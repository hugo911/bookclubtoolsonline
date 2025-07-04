#!/bin/bash
# 部署脚本

echo "🚀 开始部署 EPUB 词汇提取器..."

# 检查 Python 版本
python_version=$(python --version 2>&1)
echo "Python 版本: $python_version"

# 创建虚拟环境（如果不存在）
if [ ! -d "venv" ]; then
    echo "📦 创建虚拟环境..."
    python -m venv venv
fi

# 激活虚拟环境
echo "🔄 激活虚拟环境..."
source venv/bin/activate

# 安装依赖
echo "📚 安装 Python 依赖..."
pip install -r requirements.txt

# 下载 spaCy 模型
echo "🧠 下载 spaCy 英语模型..."
python -m spacy download en_core_web_sm

# 创建必要的目录
echo "📁 创建必要的目录..."
mkdir -p temp_data
mkdir -p static
mkdir -p logs

# 检查必要文件
echo "🔍 检查必要文件..."
required_files=("dict.csv" "wfdata.xlsx")
missing_files=()

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -ne 0 ]; then
    echo "❌ 缺少必要文件："
    printf '%s\n' "${missing_files[@]}"
    echo "请确保这些文件存在于项目目录中"
    exit 1
fi

# 运行应用
echo "✅ 部署完成！"
echo "🌐 启动应用程序..."
python app.py
