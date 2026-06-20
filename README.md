# Grok Fast API

OpenAI / Anthropic compatible Grok API gateway with Admin panel and WebUI.

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2FMaishan-Inc%2FGrok-Fast-API)

[前往 Aiven 申请 PostgreSQL 数据库](https://aiven.io/)

## Vercel 部署

1. 点击上方 **Deploy with Vercel**。
2. 前往 Aiven 创建 PostgreSQL 数据库。
3. 在 Aiven 控制台复制 PostgreSQL Service URI。
4. 下载 Aiven 的 `ca.pem` 证书。
5. 在 Vercel 项目环境变量中填写下面两个变量。
6. 部署完成后访问 `/admin/login`。

默认 Admin 密码：

```text
grok2api
```

## 环境变量

| 变量名 | 说明 |
| :-- | :-- |
| `ACCOUNT_POSTGRESQL_URL` | Aiven PostgreSQL 连接串，建议包含 `sslmode=verify-full` |
| `AIVEN_CA_CERT` | Aiven `ca.pem` 完整内容 |

示例：

```env
ACCOUNT_POSTGRESQL_URL=postgresql://avnadmin:password@host.aivencloud.com:12345/defaultdb?sslmode=verify-full
AIVEN_CA_CERT=-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
```

不要把真实数据库密码或证书提交到 Git 仓库。
