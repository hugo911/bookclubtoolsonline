#!/bin/bash

# 容器启动脚本

echo "🚀 启动 EPUB/PDF 词汇提取器..."

# 创建必要的目录
mkdir -p temp_data logs

# 生成密钥文件（如果不存在）
if [ ! -f "secret_key.txt" ]; then
    echo "🔑 生成应用密钥..."
    python -c "import os; print(os.urandom(24).hex())" > secret_key.txt
    echo "✅ 密钥已生成"
fi

# 检查必要文件
echo "🔍 检查必要文件..."
if [ ! -f "wfdata.xlsx" ]; then
    echo "❌ 缺少词汇频率数据文件: wfdata.xlsx"
    exit 1
fi

if [ ! -f "dict.csv" ]; then
    echo "❌ 缺少翻译词典文件: dict.csv"
    exit 1
fi

echo "✅ 所有文件检查通过"

# 启动应用
echo "🌐 启动应用..."
exec python app.py
