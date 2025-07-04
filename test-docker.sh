#!/bin/bash

# Docker 构建测试脚本

echo "🧪 开始测试 Docker 构建..."

# 构建测试镜像
echo "📦 构建测试镜像..."
docker build -t epub-extractor:test . --progress=plain

if [ $? -eq 0 ]; then
    echo "✅ 镜像构建成功！"
else
    echo "❌ 镜像构建失败！"
    exit 1
fi

# 运行测试容器
echo "🚀 启动测试容器..."
docker run -d \
    --name epub-extractor-test \
    -p 5001:5000 \
    -v $(pwd)/temp_data:/app/temp_data \
    epub-extractor:test

if [ $? -eq 0 ]; then
    echo "✅ 测试容器启动成功！"
else
    echo "❌ 测试容器启动失败！"
    exit 1
fi

# 等待容器启动
echo "⏱️ 等待容器启动..."
sleep 10

# 测试健康检查
echo "🔍 测试健康检查..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5001/api/status)

if [ "$response" = "200" ]; then
    echo "✅ 健康检查通过！"
else
    echo "❌ 健康检查失败！HTTP状态码: $response"
    docker logs epub-extractor-test
    docker stop epub-extractor-test
    docker rm epub-extractor-test
    exit 1
fi

# 显示容器信息
echo "📊 容器信息:"
docker ps -f name=epub-extractor-test

echo "📋 容器日志:"
docker logs epub-extractor-test

echo "🧪 测试完成！"
echo "🌐 测试地址: http://localhost:5001"
echo "⚠️  记得测试完成后清理容器: docker stop epub-extractor-test && docker rm epub-extractor-test"
