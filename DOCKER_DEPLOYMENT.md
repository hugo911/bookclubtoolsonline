# Docker 部署指南

## 📦 Docker 容器化部署

本项目支持 Docker 容器化部署，提供了完整的生产环境配置。

### 🚀 快速开始

#### 方法一：使用构建脚本（推荐）

**Windows 用户:**
```bash
# 运行构建脚本
docker-build.bat
```

**Linux/Mac 用户:**
```bash
# 添加执行权限
chmod +x docker-build.sh
# 运行构建脚本
./docker-build.sh
```

#### 方法二：手动构建

1. **构建镜像**
```bash
docker build -t epub-extractor:latest .
```

2. **运行容器**
```bash
docker run -d \
  --name epub-extractor-app \
  -p 5000:5000 \
  -v $(pwd)/temp_data:/app/temp_data \
  -v $(pwd)/logs:/app/logs \
  --restart unless-stopped \
  epub-extractor:latest
```

### 🐳 Docker Compose 部署

使用 Docker Compose 可以更方便地管理多容器应用：

```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 📋 配置说明

#### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `FLASK_ENV` | `production` | Flask 环境 |
| `PYTHONUNBUFFERED` | `1` | Python 输出缓冲 |

#### 卷映射

| 主机路径 | 容器路径 | 说明 |
|----------|----------|------|
| `./temp_data` | `/app/temp_data` | 临时文件存储 |
| `./logs` | `/app/logs` | 应用日志 |

#### 端口映射

| 主机端口 | 容器端口 | 说明 |
|----------|----------|------|
| `5000` | `5000` | 应用主端口 |
| `80` | `80` | Nginx 代理端口（可选） |

### 🔧 生产环境配置

#### 1. 使用 Nginx 反向代理

项目包含了 Nginx 配置文件，可以通过 Docker Compose 启动：

```yaml
# docker-compose.yml 中的 nginx 服务
nginx:
  image: nginx:alpine
  ports:
    - "80:80"
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf:ro
  depends_on:
    - epub-extractor
```

#### 2. 健康检查

Docker 镜像内置了健康检查：

```bash
# 检查容器健康状态
docker ps

# 查看健康检查详情
docker inspect epub-extractor-app | grep -A 10 Health
```

#### 3. 日志管理

```bash
# 查看应用日志
docker logs epub-extractor-app

# 实时查看日志
docker logs -f epub-extractor-app

# 查看系统日志
docker-compose logs -f
```

### 🛠 维护操作

#### 更新应用

```bash
# 重新构建镜像
docker build -t epub-extractor:latest .

# 停止并删除旧容器
docker stop epub-extractor-app
docker rm epub-extractor-app

# 启动新容器
docker run -d \
  --name epub-extractor-app \
  -p 5000:5000 \
  -v $(pwd)/temp_data:/app/temp_data \
  -v $(pwd)/logs:/app/logs \
  --restart unless-stopped \
  epub-extractor:latest
```

#### 备份数据

```bash
# 备份临时数据
docker run --rm -v $(pwd)/temp_data:/backup -v $(pwd):/host alpine tar czf /host/backup_temp_data.tar.gz /backup

# 备份日志
docker run --rm -v $(pwd)/logs:/backup -v $(pwd):/host alpine tar czf /host/backup_logs.tar.gz /backup
```

#### 清理资源

```bash
# 停止并删除所有相关容器
docker-compose down -v

# 删除未使用的镜像
docker image prune -f

# 删除未使用的卷
docker volume prune -f
```

### 🔍 故障排除

#### 常见问题

1. **容器无法启动**
   ```bash
   # 检查日志
   docker logs epub-extractor-app
   
   # 检查端口是否被占用
   netstat -an | grep 5000
   ```

2. **文件上传失败**
   ```bash
   # 检查磁盘空间
   df -h
   
   # 检查目录权限
   ls -la temp_data/
   ```

3. **内存不足**
   ```bash
   # 增加容器内存限制
   docker run -d --memory="2g" ...
   
   # 或者在 docker-compose.yml 中设置
   mem_limit: 2g
   ```

#### 调试模式

```bash
# 以调试模式运行容器
docker run -it --rm \
  -p 5000:5000 \
  -v $(pwd)/temp_data:/app/temp_data \
  -e FLASK_ENV=development \
  epub-extractor:latest
```

### 📊 监控和性能

#### 资源使用情况

```bash
# 查看容器资源使用
docker stats epub-extractor-app

# 查看详细信息
docker inspect epub-extractor-app
```

#### 性能调优

1. **调整内存限制**
   ```yaml
   # docker-compose.yml
   services:
     epub-extractor:
       mem_limit: 2g
       mem_reservation: 1g
   ```

2. **调整 CPU 限制**
   ```yaml
   # docker-compose.yml
   services:
     epub-extractor:
       cpus: '1.0'
   ```

### 🌐 网络配置

#### 自定义网络

```yaml
# docker-compose.yml
networks:
  epub-net:
    driver: bridge

services:
  epub-extractor:
    networks:
      - epub-net
```

#### SSL/TLS 配置

如需 HTTPS 支持，可以配置 Let's Encrypt：

```yaml
# docker-compose.yml
services:
  certbot:
    image: certbot/certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
```

### 🔒 安全建议

1. **使用非特权用户运行容器**（已在 Dockerfile 中配置）
2. **定期更新基础镜像**
3. **限制容器权限**
4. **使用 secrets 管理敏感信息**
5. **定期备份数据**

### 📞 技术支持

如果遇到问题，请：
1. 查看应用日志：`docker logs epub-extractor-app`
2. 检查容器状态：`docker ps -a`
3. 验证网络连接：`curl http://localhost:5000/api/status`
