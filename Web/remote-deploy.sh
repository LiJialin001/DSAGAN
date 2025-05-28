#!/bin/bash

# 配置路径
DEPLOY_DIR="/home/k611/data3/lys/product/frontend-1"

# 配置Docker镜像加速
echo "配置Docker镜像加速..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://registry.docker-cn.com",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
EOF

# 重启Docker服务
echo "重启Docker服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker

# 创建网络
echo "创建Docker网络..."
docker network create graduation-network 2>/dev/null || true

# 停止并删除已存在的容器
echo "清理已存在的容器..."
docker stop graduation-frontend 2>/dev/null || true
docker rm graduation-frontend 2>/dev/null || true

# 拉取镜像
echo "拉取Nginx镜像..."
docker pull nginx:alpine

# 启动前端容器
echo "启动前端容器..."
docker run -d --name graduation-frontend \
  --network graduation-network \
  -p 8321:80 \
  -v $DEPLOY_DIR/dist:/usr/share/nginx/html \
  -v $DEPLOY_DIR/nginx.conf:/etc/nginx/conf.d/default.conf \
  nginx:alpine

echo "前端容器部署完成！"
echo "检查容器状态..."
docker ps | grep graduation-frontend

echo "应用可以通过 http://172.16.2.131:8321 访问"