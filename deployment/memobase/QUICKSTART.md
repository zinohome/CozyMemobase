# Memobase 1Panel 快速启动指南

## 前置要求

- 已安装 Docker 和 Docker Compose
- 1Panel 面板已安装并运行
- 已准备好 OpenAI API Key 或其他兼容的 LLM API

## 快速部署步骤

### 步骤 1: 准备文件

在 `deployment/memobase/` 目录下，运行构建脚本自动复制文件：

```bash
cd deployment/memobase
./build.sh
```

或者手动复制文件：

```bash
cd deployment/memobase
cp ../../projecs/memobase/src/server/api/pyproject.toml .
cp ../../projecs/memobase/src/server/api/uv.lock .
cp -r ../../projecs/memobase/src/server/api/memobase_server .
cp ../../projecs/memobase/src/server/api/api.py .
cp ../../projecs/memobase/src/server/api/config.yaml.example ./config.yaml
```

### 步骤 2: 构建 Docker 镜像

```bash
docker build -t memobase-server:latest .
```

### 步骤 3: 配置环境

1. 复制环境变量示例文件：
```bash
cp env.example .env
```

2. 编辑 `.env` 文件，修改以下关键配置：
   - `DATABASE_PASSWORD`: 数据库密码（建议使用强密码）
   - `REDIS_PASSWORD`: Redis 密码（建议使用强密码）
   - `ACCESS_TOKEN`: API 访问令牌（建议使用强密码）
   - `API_EXPORT_PORT`: API 服务端口（默认 8019）

3. 编辑 `config.yaml` 文件，配置 LLM API：
```yaml
llm_api_key: YOUR-OPENAI-KEY
# 其他配置根据需要修改
```

### 步骤 4: 在 1Panel 中部署

#### 方法 1: 通过 1Panel 界面

1. 登录 1Panel
2. 进入 **应用** → **Docker Compose**
3. 点击 **创建** 或 **导入**
4. 选择 **从文件导入** 或直接粘贴 `docker-compose.yml` 内容
5. 配置环境变量（可以导入 `.env` 文件）
6. 点击 **启动**

#### 方法 2: 通过命令行

```bash
# 加载环境变量
export $(cat .env | xargs)

# 启动服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 步骤 5: 验证安装

1. 检查服务状态：
```bash
docker-compose ps
```

所有服务应该显示为 `Up` 状态。

2. 检查 API 健康状态：
```bash
curl http://localhost:8019/healthcheck
```

应该返回健康状态信息。

3. 查看 API 文档：
访问 `http://your-server-ip:8019/docs` 查看 Swagger API 文档。

## 配置说明

### 端口映射

- **8019**: Memobase API 服务（可在 `.env` 中修改 `API_EXPORT_PORT`）
- **5432**: PostgreSQL 数据库（可在 `.env` 中修改 `DATABASE_EXPORT_PORT`）
- **6379**: Redis 服务（可在 `.env` 中修改 `REDIS_EXPORT_PORT`）

### 数据存储

所有数据存储在 `./data/` 目录下：
- `./data/db`: PostgreSQL 数据
- `./data/redis`: Redis 数据

### 配置文件

- `config.yaml`: Memobase 主配置文件，包含 LLM、Embedding 等配置
- `.env`: 环境变量配置文件

## 常见问题

### 1. 服务启动失败

**问题**: 容器无法启动

**解决方案**:
- 检查端口是否被占用：`netstat -tulpn | grep -E '8019|5432|6379'`
- 检查日志：`docker-compose logs [service-name]`
- 检查环境变量配置是否正确

### 2. 数据库连接失败

**问题**: API 服务无法连接数据库

**解决方案**:
- 确认数据库服务已启动：`docker-compose ps memobase-server-db`
- 检查 `DATABASE_URL` 环境变量是否正确
- 查看数据库日志：`docker-compose logs memobase-server-db`

### 3. API 返回错误

**问题**: API 调用返回 500 错误

**解决方案**:
- 检查 `config.yaml` 中的 LLM API Key 是否正确
- 查看 API 服务日志：`docker-compose logs memobase-server-api`
- 确认所有依赖服务（数据库、Redis）正常运行

### 4. 内存不足

**问题**: 容器因内存不足被杀死

**解决方案**:
- 增加服务器内存
- 调整 Docker 内存限制
- 优化 `config.yaml` 中的配置参数

## 更新服务

```bash
# 停止服务
docker-compose down

# 重新构建镜像（如果有代码更新）
./build.sh
docker build -t memobase-server:latest .

# 启动服务
docker-compose up -d
```

## 备份和恢复

### 备份

```bash
# 备份数据库
docker exec memobase-server-db pg_dump -U memobase memobase > backup.sql

# 备份 Redis
docker exec memobase-server-redis redis-cli --no-auth-warning -a redis123 SAVE
cp -r ./data/redis ./backup/redis-$(date +%Y%m%d)
```

### 恢复

```bash
# 恢复数据库
docker exec -i memobase-server-db psql -U memobase memobase < backup.sql
```

## 安全建议

1. **修改默认密码**: 生产环境务必修改所有默认密码
2. **使用 HTTPS**: 通过反向代理（如 Nginx）配置 HTTPS
3. **限制访问**: 使用防火墙限制数据库和 Redis 的访问
4. **定期备份**: 设置定期备份数据库和 Redis 数据
5. **监控日志**: 定期检查服务日志，及时发现异常

## 获取帮助

- 官方文档: https://docs.memobase.io/
- GitHub: https://github.com/memodb-io/memobase
- Discord: https://discord.gg/YdgwU4d9NB

