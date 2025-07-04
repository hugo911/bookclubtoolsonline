@echo off
echo 🚀 开始构建 EPUB/PDF 词汇提取器 Docker 镜像...

:: 设置变量
set IMAGE_NAME=epub-extractor
set IMAGE_TAG=latest
set CONTAINER_NAME=epub-extractor-app

:: 构建镜像
echo 📦 构建 Docker 镜像...
docker build -t %IMAGE_NAME%:%IMAGE_TAG% --progress=plain --no-cache .

if %errorlevel% neq 0 (
    echo ❌ 镜像构建失败！
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

:: 运行容器
echo 🚀 启动新容器...
docker run -d ^
    --name %CONTAINER_NAME% ^
    -p 5000:5000 ^
    -v %cd%/temp_data:/app/temp_data ^
    -v %cd%/logs:/app/logs ^
    --restart unless-stopped ^
    %IMAGE_NAME%:%IMAGE_TAG%

if %errorlevel% neq 0 (
    echo ❌ 容器启动失败！
    pause
    exit /b 1
)

echo ✅ 容器启动成功！
echo 🌐 应用已启动，访问地址: http://localhost:5000
echo 📊 容器状态:
docker ps -f name=%CONTAINER_NAME%
echo 📋 查看日志: docker logs %CONTAINER_NAME%

pause
