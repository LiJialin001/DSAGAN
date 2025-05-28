#!/bin/bash

# 远程服务器信息
REMOTE_USER="k611"
REMOTE_HOST="172.16.2.131"
REMOTE_DIR="/home/k611/data3/lys/product/frontend-1"
PASSWORD="666666"

# 检查sshpass是否安装
if ! command -v sshpass &> /dev/null; then
    echo "sshpass未安装，正在尝试安装..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install hudochenkov/sshpass/sshpass
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y sshpass
    else
        echo "无法自动安装sshpass，请手动安装后重试"
        exit 1
    fi
fi

# 构建应用
echo "正在构建应用..."
npm run build

# 确保远程目录存在
echo "确保远程目录存在..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "mkdir -p $REMOTE_DIR/dist"

# 上传文件到远程服务器
echo "上传静态文件到远程服务器 $REMOTE_HOST..."
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no -r dist/* $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/dist/

echo "上传Nginx配置文件..."
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no nginx.conf $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/

echo "上传docker-compose配置文件..."
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no docker-compose.yml $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/

# 上传配置Docker镜像加速器脚本
echo "上传Docker镜像加速器配置脚本..."
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no configure-docker-mirror.sh $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "chmod +x $REMOTE_DIR/configure-docker-mirror.sh && $REMOTE_DIR/configure-docker-mirror.sh"

# 在远程服务器上检查Docker和Docker Compose
echo "检查远程服务器上的Docker和Docker Compose环境..."
DOCKER_INSTALLED=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "command -v docker > /dev/null && echo yes || echo no")
DOCKER_COMPOSE_INSTALLED=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "command -v docker-compose > /dev/null && echo yes || docker compose version > /dev/null 2>&1 && echo yes || echo no")

if [ "$DOCKER_INSTALLED" == "no" ]; then
    echo "错误：远程服务器上未安装Docker。请先安装Docker后再尝试部署。"
    exit 1
fi

# 如果docker-compose命令不可用，尝试使用docker compose插件形式
if [ "$DOCKER_COMPOSE_INSTALLED" == "no" ]; then
    echo "警告：未找到docker-compose命令，尝试使用Docker Compose插件..."
    # 检查是否可以使用docker compose插件形式的命令
    PLUGIN_AVAILABLE=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "docker compose version > /dev/null 2>&1 && echo yes || echo no")
    
    if [ "$PLUGIN_AVAILABLE" == "yes" ]; then
        echo "使用Docker Compose插件形式启动容器..."
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && docker compose down && docker compose up -d"
    else
        echo "尝试安装Docker Compose..."
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "sudo curl -L \"https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
        
        # 再次检查安装是否成功
        COMPOSE_INSTALLED=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "command -v docker-compose > /dev/null && echo yes || echo no")
        if [ "$COMPOSE_INSTALLED" == "yes" ]; then
            echo "Docker Compose安装成功，启动容器..."
            sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && docker-compose down && docker-compose up -d"
        else
            echo "Docker Compose安装失败，尝试使用纯Docker命令..."
            # 使用纯Docker命令启动容器
            sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && \
            docker network create graduation-network 2>/dev/null || true && \
            docker stop graduation-frontend 2>/dev/null || true && \
            docker rm graduation-frontend 2>/dev/null || true && \
            docker pull nginx:alpine && \
            docker run -d --name graduation-frontend \
              --network graduation-network \
              -p 8321:80 \
              -v $REMOTE_DIR/dist:/usr/share/nginx/html \
              -v $REMOTE_DIR/nginx.conf:/etc/nginx/conf.d/default.conf \
              nginx:alpine"
        fi
    fi
else
    # 使用标准docker-compose命令
    echo "使用Docker Compose启动容器..."
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && docker-compose down && docker-compose up -d"
fi

echo "部署完成！应用可以通过 http://$REMOTE_HOST:8321 访问" 