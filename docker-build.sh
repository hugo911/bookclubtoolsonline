#!/bin/bash

# Docker 构建和部署脚本

echo "🚀 开始构建 EPUB/PDF 词汇提取器 Docker 镜像..."

# 设置变量
IMAGE_NAME="epub-extractor"
IMAGE_TAG="latest"
CONTAINER_NAME="epub-extractor-app"

# 构建镜像
echo "📦 构建 Docker 镜像..."
docker build -t $IMAGE_NAME:$IMAGE_TAG .

if [ $? -eq 0 ]; then
    echo "✅ 镜像构建成功！"
else
    echo "❌ 镜像构建失败！"
    exit 1
fi

# 检查并停止现有容器
if [ $(docker ps -a -q -f name=$CONTAINER_NAME) ]; then
    echo "🛑 停止现有容器..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# 运行容器
echo "🚀 启动新容器..."
docker run -d \
    --name $CONTAINER_NAME \
    -p 5000:5000 \
    -v $(pwd)/temp_data:/app/temp_data \
    -v $(pwd)/logs:/app/logs \
    --restart unless-stopped \
    $IMAGE_NAME:$IMAGE_TAG

if [ $? -eq 0 ]; then
    echo "✅ 容器启动成功！"
    echo "🌐 应用已启动，访问地址: http://localhost:5000"
    echo "📊 容器状态:"
    docker ps -f name=$CONTAINER_NAME
    echo "📋 查看日志: docker logs $CONTAINER_NAME"
else
    echo "❌ 容器启动失败！"
    exit 1
fi
