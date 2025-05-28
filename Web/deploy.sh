#!/bin/bash

# 远程服务器信息
REMOTE_USER="k611"
REMOTE_HOST="172.16.2.131"
REMOTE_DIR="/home/k611/data3/lys/product/frontend-1"

# 构建应用
echo "正在构建应用..."
npm run build

# 确保远程目录存在
echo "确保远程目录存在..."
ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p $REMOTE_DIR"

# 上传文件到远程服务器
echo "上传静态文件到远程服务器 $REMOTE_HOST..."
scp -r dist/* $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/dist/

echo "上传Nginx配置文件..."
scp nginx.conf $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/

echo "上传docker-compose配置文件..."
scp docker-compose.yml $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/

# 在远程服务器上启动容器
echo "在远程服务器上启动容器..."
ssh $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_DIR && docker-compose down && docker-compose up -d"

echo "部署完成！应用可以通过 http://$REMOTE_HOST:8321 访问" 