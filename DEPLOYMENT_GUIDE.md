# 🚀 EPUB/PDF 词汇提取器 - 完整部署指南

## 📋 项目概述

本项目是一个智能英语学习工具，支持从 EPUB 和 PDF 格式的电子书中提取低频词汇，并生成适用于 Anki/Quizlet 的词汇表。项目已完全容器化，支持多种部署方式。

## 🏗️ 项目结构

```
bookclubtoolsonline/
├── app.py                    # Flask 主应用
├── config.py                 # 开发环境配置
├── config_prod.py           # 生产环境配置
├── requirements.txt         # Python 依赖
├── dict.csv                 # 词汇翻译词典
├── wfdata.xlsx             # 词汇频率数据
├── templates/
│   └── index.html          # 前端模板
├── temp_data/              # 临时文件存储
├── logs/                   # 应用日志
│
├── Docker 相关文件
├── Dockerfile              # Docker 镜像定义
├── docker-compose.yml      # 容器编排配置
├── .dockerignore           # Docker 构建忽略文件
├── nginx.conf              # Nginx 反向代理配置
├── start.sh                # 容器启动脚本
│
├── 部署脚本
├── docker-build.sh         # Linux/Mac Docker 构建脚本
├── docker-build.bat        # Windows Docker 构建脚本
├── test-docker.sh          # Docker 构建测试脚本
├── manage.ps1              # PowerShell 管理脚本
├── Makefile                # Make 命令文件
├── deploy.sh               # Linux/Mac 部署脚本
├── deploy.bat              # Windows 部署脚本
│
└── 文档
    ├── README.md           # 项目说明
    ├── DOCKER_DEPLOYMENT.md # Docker 部署详细指南
    └── DEPLOYMENT_GUIDE.md # 本文件
```

## 🎯 支持的部署方式

### 1. 传统部署
- **开发环境**: `python app.py`
- **生产环境**: `gunicorn + nginx`

### 2. Docker 部署
- **单容器**: `docker run`
- **多容器**: `docker-compose`
- **生产级**: `docker + nginx + 监控`

### 3. 云平台部署
- **支持**: AWS, Azure, Google Cloud
- **容器服务**: ECS, AKS, GKE
- **托管服务**: App Service, Cloud Run

## 🚀 快速开始

### 方法一: Docker 一键部署（推荐）

**Windows 用户:**
```cmd
# 使用批处理脚本
docker-build.bat

# 或使用 PowerShell
.\manage.ps1 build
.\manage.ps1 run
```

**Linux/Mac 用户:**
```bash
# 使用 shell 脚本
chmod +x docker-build.sh
./docker-build.sh

# 或使用 Makefile
make build
make run
```

### 方法二: Docker Compose 部署

```bash
# 启动所有服务（包括 Nginx 反向代理）
docker-compose up -d

# 查看服务状态
docker-compose ps

# 访问应用
# http://localhost:80 (通过 Nginx)
# http://localhost:5000 (直接访问)
```

### 方法三: 传统 Python 部署

```bash
# Windows
deploy.bat

# Linux/Mac
chmod +x deploy.sh
./deploy.sh
```

## 🔧 配置选项

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `FLASK_ENV` | `production` | Flask 运行环境 |
| `DEBUG` | `False` | 调试模式 |
| `HOST` | `0.0.0.0` | 监听地址 |
| `PORT` | `5000` | 监听端口 |
| `MAX_FILE_SIZE` | `50MB` | 最大文件大小 |

### 配置文件

- `config.py`: 开发环境配置
- `config_prod.py`: 生产环境配置

### 数据文件要求

项目需要以下数据文件：
- `dict.csv`: 词汇翻译词典
- `wfdata.xlsx`: 词汇频率数据
- `en_core_web_sm/`: spaCy 英语模型

## 📊 监控和维护

### 健康检查

所有部署方式都支持健康检查：

```bash
# 检查应用状态
curl http://localhost:5000/api/status

# 预期响应
{
  "status": "ok",
  "version": "2.1",
  "features": {
    "epub_support": true,
    "pdf_support": true,
    "max_file_size": "50MB",
    "supported_formats": ["epub", "pdf"]
  }
}
```

### 日志管理

```bash
# Docker 日志
docker logs epub-extractor-app

# 应用日志文件
tail -f logs/app.log

# 系统日志
journalctl -u your-service-name
```

### 性能监控

```bash
# 容器资源使用
docker stats epub-extractor-app

# 系统资源
htop
iotop
```

## 🔒 安全配置

### 生产环境安全

1. **使用 HTTPS**
```nginx
# nginx.conf
server {
    listen 443 ssl;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
}
```

2. **防火墙配置**
```bash
# 只开放必要端口
ufw allow 80
ufw allow 443
ufw enable
```

3. **容器安全**
```dockerfile
# Dockerfile 中已配置
USER appuser  # 非特权用户
```

### 备份策略

```bash
# 数据备份
make backup

# 手动备份
tar -czf backup_$(date +%Y%m%d).tar.gz temp_data/ logs/ dict.csv wfdata.xlsx
```

## 🌐 生产环境部署

### 最小资源要求

| 组件 | CPU | 内存 | 存储 |
|------|-----|------|------|
| 应用容器 | 1 核 | 2GB | 10GB |
| Nginx | 0.5 核 | 512MB | 1GB |
| 总计 | 1.5 核 | 2.5GB | 11GB |

### 推荐配置

| 环境 | 规格 | 说明 |
|------|------|------|
| 开发 | 2核4GB | 适合开发测试 |
| 生产 | 4核8GB | 适合正式使用 |
| 高负载 | 8核16GB | 大量用户访问 |

### 扩展性

1. **水平扩展**
```yaml
# docker-compose.yml
services:
  epub-extractor:
    deploy:
      replicas: 3  # 多实例
```

2. **负载均衡**
```nginx
# nginx.conf
upstream app {
    server epub-extractor-1:5000;
    server epub-extractor-2:5000;
    server epub-extractor-3:5000;
}
```

## 🛠 故障排除

### 常见问题

1. **端口被占用**
```bash
# 查找占用进程
netstat -tulpn | grep :5000
# 终止进程
kill -9 <PID>
```

2. **内存不足**
```bash
# 增加 swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

3. **磁盘空间不足**
```bash
# 清理 Docker 资源
docker system prune -a
# 清理临时文件
rm -rf temp_data/*
```

### 调试模式

```bash
# 开发模式运行
export FLASK_ENV=development
python app.py

# Docker 调试模式
docker run -it --rm \
  -p 5000:5000 \
  -e FLASK_ENV=development \
  epub-extractor:latest
```

## 📞 技术支持

### 获取帮助

1. **查看日志**: 首先检查应用和容器日志
2. **健康检查**: 验证服务是否正常响应
3. **资源检查**: 确认 CPU、内存、磁盘空间充足
4. **网络检查**: 验证端口开放和网络连接

### 性能优化

1. **调整并发数**
```python
# 使用 gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

2. **缓存配置**
```python
# 添加 Redis 缓存
from flask_caching import Cache
cache = Cache(app, config={'CACHE_TYPE': 'redis'})
```

3. **CDN 配置**
```nginx
# 静态文件 CDN
location /static {
    proxy_pass https://cdn.example.com;
}
```

## 🎉 总结

这个项目提供了完整的容器化解决方案，支持从开发到生产的全流程部署。通过 Docker 容器化，可以确保环境一致性，简化部署流程，提高运维效率。

选择最适合您需求的部署方式，按照相应的文档进行部署即可快速搭建起 EPUB/PDF 词汇提取服务。
