#!/bin/bash

# Memobase Docker 镜像构建脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_DIR="${SCRIPT_DIR}/../../projects/memobase/src/server/api"

echo "准备构建 Memobase Docker 镜像..."

# 检查源文件是否存在
if [ ! -d "$API_DIR" ]; then
    echo "错误: 找不到 API 源目录: $API_DIR"
    exit 1
fi

# 复制必要的文件
echo "复制构建文件..."
cp "$API_DIR/pyproject.toml" "$SCRIPT_DIR/"
cp "$API_DIR/uv.lock" "$SCRIPT_DIR/"
cp -r "$API_DIR/memobase_server" "$SCRIPT_DIR/"
cp "$API_DIR/api.py" "$SCRIPT_DIR/"

# 构建 Docker 镜像
echo "构建 Docker 镜像..."
cd "$SCRIPT_DIR"
docker build -t memobase-server:latest .

echo "构建完成！"
echo "镜像名称: memobase-server:latest"
echo ""
echo "下一步："
echo "1. 复制 config.yaml.example 为 config.yaml 并配置"
echo "2. 配置 .env 文件"
echo "3. 运行 docker-compose up -d 启动服务"

