# 手动构建 Docker 镜像指南

## 第一步：启动 Docker Desktop
1. 右键点击 "开始菜单" -> 选择 "Windows PowerShell (管理员)"
2. 或者直接右键点击 Docker Desktop 图标 -> "以管理员身份运行"
3. 等待 Docker Desktop 完全启动（系统托盘图标变为绿色）

## 第二步：验证 Docker 状态
在 PowerShell 中运行：
```powershell
docker version
```
如果看到客户端和服务器版本信息，说明 Docker 正常运行。

## 第三步：手动构建命令
```powershell
# 进入项目目录
cd d:\gongzuo\bookclubtoolsonline

# 构建镜像（显示详细输出）
docker build -t epub-extractor:latest --progress=plain .

# 如果上面的命令卡住，可以尝试不使用缓存
docker build -t epub-extractor:latest --progress=plain --no-cache .
```

## 第四步：运行容器
```powershell
# 创建必要的目录
mkdir temp_data -Force
mkdir logs -Force

# 停止现有容器（如果存在）
docker stop epub-extractor-app
docker rm epub-extractor-app

# 运行新容器
docker run -d --name epub-extractor-app -p 5000:5000 -v "${PWD}/temp_data:/app/temp_data" -v "${PWD}/logs:/app/logs" --restart unless-stopped epub-extractor:latest
```

## 第五步：验证运行
```powershell
# 查看容器状态
docker ps -f name=epub-extractor-app

# 查看容器日志
docker logs epub-extractor-app

# 访问应用
# 在浏览器中打开: http://localhost:5000
```

## 常见问题解决

### 如果构建过程卡住：
1. 按 `Ctrl+C` 停止当前构建
2. 清理构建缓存：`docker builder prune -f`
3. 重新构建：`docker build -t epub-extractor:latest --no-cache .`

### 如果网络问题：
1. 检查网络连接
2. 尝试使用国内镜像：
```powershell
docker build -t epub-extractor:latest --build-arg PIP_INDEX_URL=https://pypi.douban.com/simple/ .
```

### 如果容器启动失败：
1. 查看详细日志：`docker logs epub-extractor-app`
2. 检查端口是否被占用：`netstat -ano | findstr :5000`
3. 重新运行容器命令
