@echo off
echo 🚀 EPUB/PDF 词汇提取器 - 分步构建脚本

:: 设置变量
set IMAGE_NAME=epub-extractor
set IMAGE_TAG=latest
set CONTAINER_NAME=epub-extractor-app

:MENU
echo.
echo =====================================================
echo 🔧 请选择操作:
echo 1. 检查 Docker 状态
echo 2. 构建 Docker 镜像
echo 3. 停止现有容器
echo 4. 启动新容器
echo 5. 查看容器状态
echo 6. 查看容器日志
echo 7. 完整构建流程
echo 8. 清理所有资源
echo 0. 退出
echo =====================================================
set /p choice=请输入选择 (0-8): 

if "%choice%"=="1" goto CHECK_DOCKER
if "%choice%"=="2" goto BUILD_IMAGE
if "%choice%"=="3" goto STOP_CONTAINER
if "%choice%"=="4" goto START_CONTAINER
if "%choice%"=="5" goto CHECK_STATUS
if "%choice%"=="6" goto CHECK_LOGS
if "%choice%"=="7" goto FULL_BUILD
if "%choice%"=="8" goto CLEANUP
if "%choice%"=="0" goto EXIT
echo ❌ 无效选择，请重新输入
goto MENU

:CHECK_DOCKER
echo 🔍 检查 Docker 状态...
docker version
if %errorlevel% neq 0 (
    echo ❌ Docker 未运行！请启动 Docker Desktop
) else (
    echo ✅ Docker 运行正常
)
pause
goto MENU

:BUILD_IMAGE
echo 📦 构建 Docker 镜像...
echo 💡 提示: 如果长时间无输出，请按 Ctrl+C 取消
docker build -t %IMAGE_NAME%:%IMAGE_TAG% --progress=plain .
if %errorlevel% neq 0 (
    echo ❌ 镜像构建失败！
) else (
    echo ✅ 镜像构建成功！
)
pause
goto MENU

:STOP_CONTAINER
echo 🛑 停止现有容器...
docker ps -a -q -f name=%CONTAINER_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    docker stop %CONTAINER_NAME%
    docker rm %CONTAINER_NAME%
    echo ✅ 容器已停止并删除
) else (
    echo ℹ️ 没有找到现有容器
)
pause
goto MENU

:START_CONTAINER
echo 🚀 启动新容器...
if not exist "temp_data" mkdir temp_data
if not exist "logs" mkdir logs
docker run -d ^
    --name %CONTAINER_NAME% ^
    -p 5000:5000 ^
    -v "%cd%/temp_data:/app/temp_data" ^
    -v "%cd%/logs:/app/logs" ^
    --restart unless-stopped ^
    %IMAGE_NAME%:%IMAGE_TAG%
if %errorlevel% neq 0 (
    echo ❌ 容器启动失败！
) else (
    echo ✅ 容器启动成功！
    echo 🌐 访问地址: http://localhost:5000
)
pause
goto MENU

:CHECK_STATUS
echo 📊 容器状态:
docker ps -f name=%CONTAINER_NAME%
pause
goto MENU

:CHECK_LOGS
echo 📋 容器日志:
docker logs %CONTAINER_NAME%
pause
goto MENU

:FULL_BUILD
echo 🔄 执行完整构建流程...
call :CHECK_DOCKER
call :BUILD_IMAGE
call :STOP_CONTAINER
call :START_CONTAINER
call :CHECK_STATUS
echo ✅ 完整构建流程完成！
pause
goto MENU

:CLEANUP
echo 🧹 清理所有资源...
docker stop %CONTAINER_NAME% 2>nul
docker rm %CONTAINER_NAME% 2>nul
docker rmi %IMAGE_NAME%:%IMAGE_TAG% 2>nul
docker system prune -f
echo ✅ 清理完成！
pause
goto MENU

:EXIT
echo 👋 再见！
exit /b 0
