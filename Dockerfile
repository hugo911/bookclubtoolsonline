# 使用官方 Python 镜像
FROM python:3.9-slim

# 设置环境变量
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=production

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制 requirements.txt 并安装 Python 依赖
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# 下载 spaCy 模型
RUN python -m spacy download en_core_web_sm

# 复制项目文件到容器
COPY . .

# 创建必要的目录
RUN mkdir -p temp_data logs

# 设置文件权限
RUN chmod +x deploy.sh start.sh

# 暴露端口
EXPOSE 5000

# 创建非特权用户
RUN adduser --disabled-password --gecos '' appuser
RUN chown -R appuser:appuser /app
USER appuser

# 健康检查
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/api/status || exit 1

# 运行应用
CMD ["./start.sh"]

