#!/bin/bash

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

echo "Docker镜像加速器配置完成!" 