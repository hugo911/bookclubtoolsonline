@echo off
echo 🚀 开始部署 EPUB 词汇提取器...

:: 检查 Python 版本
python --version
if errorlevel 1 (
    echo ❌ 未找到 Python，请先安装 Python
    pause
    exit /b 1
)

:: 创建虚拟环境（如果不存在）
if not exist "venv" (
    echo 📦 创建虚拟环境...
    python -m venv venv
)

:: 激活虚拟环境
echo 🔄 激活虚拟环境...
call venv\Scripts\activate.bat

:: 安装依赖
echo 📚 安装 Python 依赖...
pip install -r requirements.txt

:: 下载 spaCy 模型
echo 🧠 下载 spaCy 英语模型...
python -m spacy download en_core_web_sm

:: 创建必要的目录
echo 📁 创建必要的目录...
if not exist "temp_data" mkdir temp_data
if not exist "static" mkdir static
if not exist "logs" mkdir logs

:: 检查必要文件
echo 🔍 检查必要文件...
if not exist "dict.csv" (
    echo ❌ 缺少文件: dict.csv
    echo 请确保词典文件存在于项目目录中
    pause
    exit /b 1
)

if not exist "wfdata.xlsx" (
    echo ❌ 缺少文件: wfdata.xlsx
    echo 请确保词汇频率数据文件存在于项目目录中
    pause
    exit /b 1
)

:: 运行应用
echo ✅ 部署完成！
echo 🌐 启动应用程序...
echo 请在浏览器中访问: http://localhost:5000
python app.py

pause
