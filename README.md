# Grok2API 多平台部署指南

Grok2API 是一个 OpenAI / Anthropic 兼容的 Grok 网关，支持多账号池、Admin 后台、聊天、图像和视频接口。

本文档只保留部署和运行所需内容，默认推荐 PostgreSQL 存储。Aiven PostgreSQL、Render、Vercel、Docker Compose、Railway、Zeabur、VPS 都可以部署。

## 快速选择

| 平台 | 推荐程度 | 数据库 | 说明 |
| :-- | :-- | :-- | :-- |
| Docker Compose / VPS | 推荐 | 内置 PostgreSQL 或 Aiven | 最完整，支持长期运行 |
| Render | 推荐 | Aiven PostgreSQL | 支持 Docker Web Service，部署稳定 |
| Railway / Zeabur | 推荐 | 平台 PostgreSQL 或 Aiven | 适合容器化一键部署 |
| Vercel | 可用但不推荐重负载 | Aiven PostgreSQL | Serverless，不能跑 Docker Compose |

## 重要说明

- 默认 Docker Compose 已改为 PostgreSQL 模式。
- `docker-compose.yml` 会加入外部 Docker 网络 `smvapi`。
- Vercel 不支持 Docker Compose、内置 PostgreSQL 容器、`smvapi` 网络或可靠本地持久化。
- Aiven PostgreSQL 通常需要 TLS/CA 证书。项目已支持通过环境变量 `AIVEN_CA_CERT` 自动写入证书文件并连接。
- 首次启动后访问 `/admin/login`，默认密码是 `grok2api`。

## 环境变量

| 变量名 | 必填 | 默认值 | 说明 |
| :-- | :-- | :-- | :-- |
| `ACCOUNT_STORAGE` | 是 | `postgresql` | 存储后端，推荐 `postgresql` |
| `ACCOUNT_POSTGRESQL_URL` | PostgreSQL 模式必填 | 空 | PostgreSQL 连接串 |
| `AIVEN_CA_CERT` | Aiven 推荐 | 空 | Aiven `ca.pem` 完整内容 |
| `AIVEN_CA_CERT_PATH` | 否 | `/app/data/aiven-ca.pem` 或 `/tmp/grok2api-data/aiven-ca.pem` | CA 证书写入路径 |
| `SERVER_HOST` | 否 | `0.0.0.0` | 服务监听地址 |
| `SERVER_PORT` | 否 | `8000` | Docker/VPS 监听端口 |
| `HOST_PORT` | 否 | `8000` | Docker Compose 宿主机端口 |
| `SERVER_WORKERS` | 否 | `1` | Worker 数 |
| `LOG_LEVEL` | 否 | `INFO` | 日志级别 |
| `DATA_DIR` | 否 | `./data` | 数据目录 |
| `LOG_DIR` | 否 | `./logs` | 日志目录 |

部分平台不允许配置 `TZ`。它不是必填项；如果平台提示不能配置，直接删除即可。

## Aiven PostgreSQL

### 连接串

在 Aiven 控制台复制 PostgreSQL Service URI，例如：

```text
postgresql://avnadmin:password@host.aivencloud.com:12345/defaultdb
```

推荐加上 `sslmode=verify-full` 和 `sslrootcert`：

```text
postgresql://avnadmin:password@host.aivencloud.com:12345/defaultdb?sslmode=verify-full
```

项目启动时如果设置了 `AIVEN_CA_CERT`，会自动把证书写入 `AIVEN_CA_CERT_PATH`，并给 `ACCOUNT_POSTGRESQL_URL` 自动追加 `sslrootcert=/path/to/aiven-ca.pem`。

### AIVEN_CA_CERT

把 Aiven 下载的 `ca.pem` 完整内容填入环境变量：

```text
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
```

如果平台不方便填写多行变量，可以把换行保留为平台支持的多行 Secret。不要把真实证书和数据库密码提交到仓库。

Docker Compose 场景也可以把 Aiven `ca.pem` 放到本地 `./data/aiven-ca.pem`，然后设置：

```env
AIVEN_CA_CERT_PATH=/app/data/aiven-ca.pem
```

容器会通过挂载的 `./data:/app/data` 读取该证书。

## Docker Compose 一键部署

适合 VPS、1Panel、宝塔 Docker、CasaOS、Portainer 等能运行 Docker Compose 的环境。

### 使用内置 PostgreSQL

```bash
cp .env.example .env
docker network create smvapi
docker compose up -d
```

如果 `smvapi` 网络已经存在，可以忽略创建失败提示。

默认服务：

- `grok2api`: 主服务
- `postgres`: 内置 PostgreSQL
- `postgres_data`: PostgreSQL 持久化卷
- `smvapi`: 外部 Docker 网络

访问：

```text
http://服务器IP:8000/admin/login
```

### 使用 Aiven PostgreSQL

编辑 `.env`：

```env
ACCOUNT_STORAGE=postgresql
ACCOUNT_POSTGRESQL_URL=postgresql://avnadmin:password@host.aivencloud.com:12345/defaultdb?sslmode=verify-full
AIVEN_CA_CERT_PATH=/app/data/aiven-ca.pem
```

然后把 Aiven 下载的 `ca.pem` 保存为：

```text
./data/aiven-ca.pem
```

启动：

```bash
docker network create smvapi
docker compose up -d
```

如果使用 Aiven，可以保留内置 `postgres` 服务不使用，也可以按需从 `docker-compose.yml` 删除 `postgres` 服务和 `depends_on`。

## Render + Aiven PostgreSQL

仓库已内置 `render.yaml`，Render 会按 Docker Web Service 部署。

1. 在 Aiven 创建 PostgreSQL。
2. 下载 Aiven `ca.pem`。
3. 将仓库推送到 GitHub。
4. Render 选择 **New +** -> **Blueprint**。
5. 连接该仓库。
6. 填写环境变量：

| 变量名 | 值 |
| :-- | :-- |
| `ACCOUNT_POSTGRESQL_URL` | `postgresql://.../defaultdb?sslmode=verify-full` |
| `AIVEN_CA_CERT` | Aiven `ca.pem` 完整内容 |

`render.yaml` 已包含：

- `runtime: docker`
- `ACCOUNT_STORAGE=postgresql`
- `AIVEN_CA_CERT_PATH=/app/data/aiven-ca.pem`
- `healthCheckPath=/health`

Render 会自动使用 Dockerfile 构建镜像。Dockerfile 已兼容 Render 注入的 `PORT`。

## Vercel + Aiven PostgreSQL

仓库已内置：

- `api/index.py`
- `vercel.json`
- `.vercelignore`

Vercel 会以 Python Function 方式加载 FastAPI 应用。

### 限制

- 不支持 Docker Compose。
- 不支持内置 PostgreSQL 容器。
- 不支持 `smvapi` Docker 网络。
- `/tmp` 是临时目录，不能当持久化存储。
- 长流式请求、批量刷新和大文件缓存可能受 Serverless 限制影响。

### 部署步骤

1. 在 Aiven 创建 PostgreSQL。
2. 下载 Aiven `ca.pem`。
3. 将仓库推送到 GitHub。
4. 在 Vercel 导入该仓库。
5. 在 Vercel 项目环境变量中添加：

| 变量名 | 值 |
| :-- | :-- |
| `ACCOUNT_STORAGE` | `postgresql` |
| `ACCOUNT_POSTGRESQL_URL` | `postgresql://.../defaultdb?sslmode=verify-full` |
| `AIVEN_CA_CERT` | Aiven `ca.pem` 完整内容 |
| `DATA_DIR` | `/tmp/grok2api-data` |
| `LOG_DIR` | `/tmp/grok2api-logs` |

6. 点击 Deploy。

`api/index.py` 会在导入 FastAPI 应用前写入 Aiven CA 证书，并自动给数据库连接串追加 `sslrootcert`。

## Railway 部署

Railway 可直接使用 Dockerfile。

1. 新建 Railway Project。
2. 选择从 GitHub 仓库部署。
3. Railway 检测 Dockerfile 后自动构建。
4. 添加环境变量：

```env
ACCOUNT_STORAGE=postgresql
ACCOUNT_POSTGRESQL_URL=postgresql://...
AIVEN_CA_CERT=-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
SERVER_HOST=0.0.0.0
SERVER_WORKERS=1
```

如果使用 Railway 自带 PostgreSQL，把 Railway 提供的 PostgreSQL URL 填入 `ACCOUNT_POSTGRESQL_URL`。如果使用 Aiven，按上面的 Aiven 证书方式填写。

## Zeabur 部署

Zeabur 可用 Dockerfile 或 Docker Compose。

### Dockerfile 方式

1. 新建 Zeabur Project。
2. 从 GitHub 导入仓库。
3. 选择 Dockerfile 部署。
4. 添加环境变量：

```env
ACCOUNT_STORAGE=postgresql
ACCOUNT_POSTGRESQL_URL=postgresql://...
AIVEN_CA_CERT=-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
SERVER_HOST=0.0.0.0
SERVER_WORKERS=1
```

### Compose 方式

如果使用 `docker-compose.yml`，需要先确认 Zeabur 是否支持外部网络 `smvapi`。如果不支持，请删除 Compose 文件中的：

```yaml
networks:
  smvapi:
    external: true
    name: smvapi
```

以及服务里的：

```yaml
networks:
  - smvapi
```

## VPS Docker Run

不使用 Compose 时可以直接运行容器。

```bash
docker run -d --name grok2api \
  -p 8000:8000 \
  -e ACCOUNT_STORAGE=postgresql \
  -e ACCOUNT_POSTGRESQL_URL='postgresql://avnadmin:password@host.aivencloud.com:12345/defaultdb?sslmode=verify-full' \
  -e AIVEN_CA_CERT='-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----' \
  -e SERVER_HOST=0.0.0.0 \
  -e SERVER_PORT=8000 \
  -v "$(pwd)/data:/app/data" \
  -v "$(pwd)/logs:/app/logs" \
  --restart unless-stopped \
  ghcr.io/jiujiu532/grok2api:latest
```

## 本地源码运行

前置要求：Python 3.13+、uv。

```bash
cp .env.example .env
uv sync
uv run granian --interface asgi --host 0.0.0.0 --port 8000 --workers 1 app.main:app
```

## 启动后配置

访问：

```text
http://你的域名或IP/admin/login
```

默认 Admin 密码：

```text
grok2api
```

首次进入后建议修改：

| 配置项 | 说明 |
| :-- | :-- |
| `app.app_key` | Admin 登录密码 |
| `app.api_key` | API 鉴权密钥 |
| `app.app_url` | 公网访问地址，图片/视频链接需要 |

## API 端点

| 端点 | 说明 |
| :-- | :-- |
| `GET /health` | 健康检查 |
| `GET /v1/models` | 模型列表 |
| `POST /v1/chat/completions` | OpenAI Chat Completions |
| `POST /v1/responses` | OpenAI Responses |
| `POST /v1/messages` | Anthropic Messages |
| `POST /v1/images/generations` | 图像生成 |
| `POST /v1/images/edits` | 图像编辑 |
| `POST /v1/videos` | 视频任务 |

## 常见问题

### Aiven 连接失败

优先检查：

- `ACCOUNT_POSTGRESQL_URL` 是否正确。
- URL 是否包含 `sslmode=verify-full` 或 `sslmode=require`。
- `AIVEN_CA_CERT` 是否是完整 `ca.pem` 内容。
- 数据库防火墙是否允许部署平台出口 IP。
- Aiven 用户名、密码、端口、数据库名是否正确。

### Render 部署后健康检查失败

检查 Render 日志，确认：

- Dockerfile 是否构建成功。
- 应用是否监听 Render 注入的 `PORT`。
- `ACCOUNT_POSTGRESQL_URL` 和 `AIVEN_CA_CERT` 是否已填写。

### Vercel 部署后 500

检查 Vercel Function 日志，常见原因：

- 未设置 `ACCOUNT_POSTGRESQL_URL`。
- Aiven 证书变量格式错误。
- 依赖安装失败。
- Serverless 执行时间或包体积限制。

### Docker Compose 报 `network smvapi not found`

先创建外部网络：

```bash
docker network create smvapi
```

## 许可证

MIT License
