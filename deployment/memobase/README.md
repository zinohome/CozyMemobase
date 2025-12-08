# Memobase 1Panel 安装部署

本目录包含用于 1Panel 部署的 Memobase 配置文件。

## 文件说明

- `Dockerfile`: Memobase API 服务的 Docker 镜像构建文件
- `docker-compose.yml`: Docker Compose 配置文件，包含数据库、Redis 和 API 服务
- `env.example`: 环境变量配置示例文件
- `build.sh`: 自动构建脚本，用于复制源文件并构建镜像
- `README.md`: 详细部署说明文档
- `QUICKSTART.md`: 快速启动指南

## 部署步骤

### 1. 准备文件

将以下文件从 `projecs/memobase/src/server/api/` 复制到当前目录：

```bash
# 复制必要的文件到 deployment/memobase/
cp -r projecs/memobase/src/server/api/pyproject.toml .
cp -r projecs/memobase/src/server/api/uv.lock .
cp -r projecs/memobase/src/server/api/memobase_server .
cp -r projecs/memobase/src/server/api/api.py .
cp projecs/memobase/src/server/api/config.yaml.example ./config.yaml
```

### 2. 构建 Docker 镜像

在 `deployment/memobase/` 目录下执行：

```bash
docker build -t memobase-server:latest .
```

### 3. 配置环境变量

复制 `env.example` 为 `.env` 并修改配置：

```bash
cp env.example .env
# 编辑 .env 文件，修改数据库密码、Redis 密码、访问令牌等
```

### 4. 配置 config.yaml

编辑 `config.yaml` 文件，配置 LLM API 密钥等信息：

```yaml
llm_api_key: YOUR-OPENAI-KEY
# 其他配置...
```

### 5. 启动服务

在 1Panel 中：

1. 进入应用管理
2. 选择 Docker Compose
3. 创建新应用
4. 将 `docker-compose.yml` 内容粘贴进去
5. 配置环境变量（或使用 `.env` 文件）
6. 启动应用

或者使用命令行：

```bash
docker-compose up -d
```

## 环境变量说明

### 数据库配置
- `DATABASE_USER`: PostgreSQL 用户名（默认: memobase）
- `DATABASE_PASSWORD`: PostgreSQL 密码（默认: memobase123）
- `DATABASE_NAME`: 数据库名称（默认: memobase）
- `DATABASE_EXPORT_PORT`: 数据库对外端口（默认: 5432）
- `DATABASE_LOCATION`: 数据库数据存储路径（默认: ./data/db）

### Redis 配置
- `REDIS_EXPORT_PORT`: Redis 对外端口（默认: 6379）
- `REDIS_LOCATION`: Redis 数据存储路径（默认: ./data/redis）
- `REDIS_PASSWORD`: Redis 密码（默认: redis123）

### Memobase API 配置
- `ACCESS_TOKEN`: API 访问令牌（默认: secret）
- `PROJECT_ID`: 项目 ID（默认: default）
- `API_HOSTS`: 允许的主机（默认: *）
- `USE_CORS`: 是否启用 CORS（默认: true）
- `API_EXPORT_PORT`: API 服务对外端口（默认: 8019）
- `CONFIG_FILE`: 配置文件路径（默认: ./config.yaml）

## 验证安装

服务启动后，可以通过以下方式验证：

```bash
# 检查服务状态
docker-compose ps

# 检查 API 健康状态
curl http://localhost:8019/healthcheck

# 查看日志
docker-compose logs -f memobase-server-api
```

## 注意事项

1. **安全性**: 生产环境请务必修改默认密码和访问令牌
2. **数据持久化**: 数据库和 Redis 数据存储在 `./data/` 目录下，请确保该目录有适当的备份
3. **配置文件**: `config.yaml` 需要配置有效的 LLM API 密钥才能正常工作
4. **网络**: 所有服务都在 `memobase-network` 网络中，可以通过服务名互相访问

## 故障排查

### 服务无法启动
- 检查端口是否被占用
- 检查环境变量配置是否正确
- 查看容器日志：`docker-compose logs [service-name]`

### 数据库连接失败
- 检查数据库服务是否正常启动
- 验证 `DATABASE_URL` 环境变量是否正确
- 检查网络连接

### API 服务异常
- 检查 `config.yaml` 配置是否正确
- 验证 LLM API 密钥是否有效
- 查看 API 服务日志

## 更新服务

```bash
# 停止服务
docker-compose down

# 重新构建镜像（如果有代码更新）
docker build -t memobase-server:latest .

# 启动服务
docker-compose up -d
```

