@echo off
echo 🚀 开始构建 EPUB/PDF 词汇提取器 Docker 镜像...

:: 设置变量
set IMAGE_NAME=epub-extractor
set IMAGE_TAG=latest
set CONTAINER_NAME=epub-extractor-app

:: 检查 Docker 是否运行
echo 🔍 检查 Docker 状态...
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker 未运行或未安装！请先启动 Docker Desktop
    pause
    exit /b 1
)
echo ✅ Docker 运行正常

:: 显示当前目录和文件
echo 📁 当前目录: %cd%
echo 📋 检查 Dockerfile...
if not exist "Dockerfile" (
    echo ❌ 找不到 Dockerfile！
    pause
    exit /b 1
)
echo ✅ Dockerfile 存在

:: 清理旧的构建缓存（可选）
echo 🧹 清理 Docker 构建缓存...
docker builder prune -f

:: 构建镜像
echo 📦 构建 Docker 镜像...
echo 💡 提示: 构建过程可能需要几分钟，请耐心等待...
docker build -t %IMAGE_NAME%:%IMAGE_TAG% --progress=plain --no-cache .

if %errorlevel% neq 0 (
    echo ❌ 镜像构建失败！
    echo 🔍 请检查上方的错误信息
    pause
    exit /b 1
)

echo ✅ 镜像构建成功！

:: 检查并停止现有容器
echo 🔍 检查现有容器...
for /f %%i in ('docker ps -a -q -f name=%CONTAINER_NAME% 2^>nul') do (
    echo 🛑 停止现有容器...
    docker stop %CONTAINER_NAME%
    docker rm %CONTAINER_NAME%
)

:: 创建必要的目录
echo 📁 创建本地目录...
if not exist "temp_data" mkdir temp_data
if not exist "logs" mkdir logs

:: 运行容器
echo 🚀 启动新容器...
docker run -d ^
    --name %CONTAINER_NAME% ^
    -p 5000:5000 ^
    -v "%cd%/temp_data:/app/temp_data" ^
    -v "%cd%/logs:/app/logs" ^
    --restart unless-stopped ^
    %IMAGE_NAME%:%IMAGE_TAG%

if %errorlevel% neq 0 (
    echo ❌ 容器启动失败！
    echo 🔍 查看容器日志:
    docker logs %CONTAINER_NAME%
    pause
    exit /b 1
)

echo ✅ 容器启动成功！
echo 🌐 应用已启动，访问地址: http://localhost:5000
echo 📊 容器状态:
docker ps -f name=%CONTAINER_NAME%
echo 📋 查看日志: docker logs %CONTAINER_NAME%
echo 🔧 停止容器: docker stop %CONTAINER_NAME%

pause
