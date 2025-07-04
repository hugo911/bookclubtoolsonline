# Makefile for EPUB/PDF Vocabulary Extractor

.PHONY: help build run stop clean test logs shell

# 默认目标
help:
	@echo "EPUB/PDF 词汇提取器 - Docker 命令"
	@echo ""
	@echo "可用命令:"
	@echo "  build     - 构建 Docker 镜像"
	@echo "  run       - 运行容器"
	@echo "  stop      - 停止容器"
	@echo "  restart   - 重启容器"
	@echo "  clean     - 清理容器和镜像"
	@echo "  test      - 测试 Docker 构建"
	@echo "  logs      - 查看容器日志"
	@echo "  shell     - 进入容器 shell"
	@echo "  compose   - 使用 Docker Compose 启动"
	@echo "  status    - 查看容器状态"

# 构建镜像
build:
	@echo "📦 构建 Docker 镜像..."
	docker build -t epub-extractor:latest .

# 运行容器
run:
	@echo "🚀 启动容器..."
	docker run -d \
		--name epub-extractor-app \
		-p 5000:5000 \
		-v $(PWD)/temp_data:/app/temp_data \
		-v $(PWD)/logs:/app/logs \
		--restart unless-stopped \
		epub-extractor:latest

# 停止容器
stop:
	@echo "🛑 停止容器..."
	docker stop epub-extractor-app || true
	docker rm epub-extractor-app || true

# 重启容器
restart: stop run

# 清理资源
clean:
	@echo "🧹 清理 Docker 资源..."
	docker stop epub-extractor-app || true
	docker rm epub-extractor-app || true
	docker rmi epub-extractor:latest || true
	docker system prune -f

# 测试构建
test:
	@echo "🧪 测试 Docker 构建..."
	chmod +x test-docker.sh
	./test-docker.sh

# 查看日志
logs:
	@echo "📋 查看容器日志..."
	docker logs -f epub-extractor-app

# 进入容器
shell:
	@echo "🐚 进入容器 shell..."
	docker exec -it epub-extractor-app /bin/bash

# 使用 Docker Compose
compose:
	@echo "🐳 使用 Docker Compose 启动..."
	docker-compose up -d

# 查看状态
status:
	@echo "📊 容器状态:"
	docker ps -f name=epub-extractor
	@echo ""
	@echo "🔍 健康检查:"
	curl -s http://localhost:5000/api/status || echo "服务不可用"

# 生产环境部署
deploy: build
	@echo "🚀 生产环境部署..."
	docker-compose -f docker-compose.yml up -d

# 备份数据
backup:
	@echo "💾 备份数据..."
	docker run --rm -v $(PWD)/temp_data:/backup -v $(PWD):/host alpine tar czf /host/backup_$(shell date +%Y%m%d_%H%M%S).tar.gz /backup

# 查看镜像大小
size:
	@echo "📏 镜像大小:"
	docker images epub-extractor:latest

# 安全扫描
security:
	@echo "🔒 安全扫描..."
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image epub-extractor:latest
