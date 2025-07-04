@echo off
echo 🚀 简化版 Docker 构建脚本

:: 设置变量
set IMAGE_NAME=epub-extractor
set IMAGE_TAG=latest
set CONTAINER_NAME=epub-extractor-app

echo 🔍 检查 Docker 状态...
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker 未运行！
    echo 💡 请以管理员身份启动 Docker Desktop，然后重新运行此脚本
    pause
    exit /b 1
)
echo ✅ Docker 运行正常

echo 📁 当前目录: %cd%
echo 📦 开始构建镜像...
echo 💡 提示: 构建过程可能需要 5-10 分钟，请耐心等待...

:: 构建镜像
docker build -t %IMAGE_NAME%:%IMAGE_TAG% --progress=plain .

if %errorlevel% neq 0 (
    echo ❌ 镜像构建失败！
    echo 🔧 尝试清理缓存重新构建...
    docker builder prune -f
    docker build -t %IMAGE_NAME%:%IMAGE_TAG% --progress=plain --no-cache .
    
    if %errorlevel% neq 0 (
        echo ❌ 构建仍然失败，请检查错误信息
        pause
        exit /b 1
    )
)

echo ✅ 镜像构建成功！

:: 创建目录
if not exist "temp_data" mkdir temp_data
if not exist "logs" mkdir logs

:: 停止现有容器
echo 🛑 停止现有容器...
docker stop %CONTAINER_NAME% 2>nul
docker rm %CONTAINER_NAME% 2>nul

:: 启动容器
echo 🚀 启动容器...
docker run -d ^
    --name %CONTAINER_NAME% ^
    -p 5000:5000 ^
    -v "%cd%/temp_data:/app/temp_data" ^
    -v "%cd%/logs:/app/logs" ^
    --restart unless-stopped ^
    %IMAGE_NAME%:%IMAGE_TAG%

if %errorlevel% neq 0 (
    echo ❌ 容器启动失败！
    echo 📋 查看错误日志:
    docker logs %CONTAINER_NAME%
    pause
    exit /b 1
)

echo ✅ 容器启动成功！
echo 🌐 应用地址: http://localhost:5000
echo 📊 容器状态:
docker ps -f name=%CONTAINER_NAME%

pause
