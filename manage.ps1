# PowerShell Docker 管理脚本

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("build", "run", "stop", "restart", "clean", "test", "logs", "shell", "compose", "status", "help")]
    [string]$Command
)

$ImageName = "epub-extractor"
$ImageTag = "latest"
$ContainerName = "epub-extractor-app"

function Show-Help {
    Write-Host "EPUB/PDF 词汇提取器 - Docker 管理脚本" -ForegroundColor Green
    Write-Host ""
    Write-Host "使用方法: .\manage.ps1 <command>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "可用命令:" -ForegroundColor Cyan
    Write-Host "  build     - 构建 Docker 镜像"
    Write-Host "  run       - 运行容器"
    Write-Host "  stop      - 停止容器"
    Write-Host "  restart   - 重启容器"
    Write-Host "  clean     - 清理容器和镜像"
    Write-Host "  test      - 测试 Docker 构建"
    Write-Host "  logs      - 查看容器日志"
    Write-Host "  shell     - 进入容器 shell"
    Write-Host "  compose   - 使用 Docker Compose 启动"
    Write-Host "  status    - 查看容器状态"
    Write-Host "  help      - 显示帮助信息"
}

function Build-Image {
    Write-Host "📦 构建 Docker 镜像..." -ForegroundColor Green
    docker build -t "${ImageName}:${ImageTag}" .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 镜像构建成功！" -ForegroundColor Green
    } else {
        Write-Host "❌ 镜像构建失败！" -ForegroundColor Red
        exit 1
    }
}

function Run-Container {
    Write-Host "🚀 启动容器..." -ForegroundColor Green
    
    # 停止现有容器
    Stop-Container
    
    docker run -d `
        --name $ContainerName `
        -p 5000:5000 `
        -v "${PWD}/temp_data:/app/temp_data" `
        -v "${PWD}/logs:/app/logs" `
        --restart unless-stopped `
        "${ImageName}:${ImageTag}"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 容器启动成功！" -ForegroundColor Green
        Write-Host "🌐 访问地址: http://localhost:5000" -ForegroundColor Cyan
    } else {
        Write-Host "❌ 容器启动失败！" -ForegroundColor Red
        exit 1
    }
}

function Stop-Container {
    Write-Host "🛑 停止容器..." -ForegroundColor Yellow
    docker stop $ContainerName 2>$null
    docker rm $ContainerName 2>$null
}

function Restart-Container {
    Write-Host "🔄 重启容器..." -ForegroundColor Yellow
    Stop-Container
    Run-Container
}

function Clean-Resources {
    Write-Host "🧹 清理 Docker 资源..." -ForegroundColor Yellow
    docker stop $ContainerName 2>$null
    docker rm $ContainerName 2>$null
    docker rmi "${ImageName}:${ImageTag}" 2>$null
    docker system prune -f
}

function Test-Build {
    Write-Host "🧪 测试 Docker 构建..." -ForegroundColor Green
    # 简化版测试
    Build-Image
    
    # 运行临时测试容器
    docker run -d --name "${ContainerName}-test" -p 5001:5000 "${ImageName}:${ImageTag}"
    
    Start-Sleep -Seconds 10
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5001/api/status" -Method Get -TimeoutSec 30
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ 健康检查通过！" -ForegroundColor Green
        } else {
            Write-Host "❌ 健康检查失败！" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ 无法连接到测试服务！" -ForegroundColor Red
    }
    
    # 清理测试容器
    docker stop "${ContainerName}-test"
    docker rm "${ContainerName}-test"
}

function Show-Logs {
    Write-Host "📋 查看容器日志..." -ForegroundColor Green
    docker logs -f $ContainerName
}

function Enter-Shell {
    Write-Host "🐚 进入容器 shell..." -ForegroundColor Green
    docker exec -it $ContainerName /bin/bash
}

function Start-Compose {
    Write-Host "🐳 使用 Docker Compose 启动..." -ForegroundColor Green
    docker-compose up -d
}

function Show-Status {
    Write-Host "📊 容器状态:" -ForegroundColor Green
    docker ps -f name=$ContainerName
    
    Write-Host "`n🔍 健康检查:" -ForegroundColor Green
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/api/status" -Method Get -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ 服务正常运行" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ 服务不可用" -ForegroundColor Red
    }
}

# 主逻辑
switch ($Command) {
    "build" { Build-Image }
    "run" { Run-Container }
    "stop" { Stop-Container }
    "restart" { Restart-Container }
    "clean" { Clean-Resources }
    "test" { Test-Build }
    "logs" { Show-Logs }
    "shell" { Enter-Shell }
    "compose" { Start-Compose }
    "status" { Show-Status }
    "help" { Show-Help }
    default { Show-Help }
}
