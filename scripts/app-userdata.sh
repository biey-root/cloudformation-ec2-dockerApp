#!/bin/bash
# UserData script for App EC2 (Amazon Linux 2)
set -eux

# Install Docker
yum update -y
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker

# Pull and run nginxdemos/hello container
docker pull nginxdemos/hello:latest

# Run container with restart policy
docker run -d --name hello-app --restart unless-stopped -p 80:80 nginxdemos/hello:latest