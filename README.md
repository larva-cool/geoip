# GeoIP

GeoIP 是一个基于 Go 的轻量级 IP 信息查询服务，使用 MaxMind MMDB 数据库文件 `Merged-IP.mmdb` 提供 IP 地理位置、ASN、ISP、代理/VPN 等信息查询能力。

项目支持可选 API Key 鉴权，可从 `.env` 文件或系统环境变量读取密钥；未配置密钥时接口会直接放行。

## 功能特性

- 支持单个 IP 查询
- 支持多个 IP 批量查询
- 支持完整 MMDB 原始结构返回
- 支持简化结构返回，适合前端或 API 直接消费
- 支持多语言地名返回
- 未传入 IP 时自动识别客户端真实 IP
- 本地缺少数据库文件时自动下载
- 支持手动下载或更新 IP 数据库
- 支持可选 API Key 鉴权
- 支持通过 `.env` 管理环境变量

## 环境要求

- Go `1.25.0` 或兼容版本
- 可访问互联网，用于首次自动下载 `Merged-IP.mmdb`

## 安装依赖

```bash
go mod tidy
```

## 快速开始

### 可选配置 API Key

如需启用接口鉴权，可在项目根目录创建 `.env` 文件：

```env
GEOIP_API_KEY=your_api_key_here
```

也可以直接使用系统环境变量：

```bash
export GEOIP_API_KEY=your_api_key_here
```

如果未配置 `GEOIP_API_KEY`，服务不会启用 API Key 鉴权，所有请求会直接放行。

### 启动服务

```bash
go run .
```

服务默认监听：

```text
http://127.0.0.1:8080
```

### 指定监听端口

```bash
go run . -p 8080
```

## 鉴权方式

只有配置了 `GEOIP_API_KEY` 时，接口才需要提供 API Key。

### 通过 Header 传入

```bash
curl -H "X-API-Key: your_api_key_here" "http://127.0.0.1:8080/s?ip=8.8.8.8"
```

### 通过 URL 参数传入

```bash
curl "http://127.0.0.1:8080/s?ip=8.8.8.8&key=your_api_key_here"
```

启用鉴权后，如果 API Key 缺失或错误，服务会返回 `401 Unauthorized`：

```json
{
  "code": 401,
  "hint": "Please provide '?key=YOUR_KEY' in URL or 'X-API-Key' in Header",
  "message": "Unauthorized: Invalid or missing API Key"
}
```

## IP 数据库

服务依赖当前目录下的 `Merged-IP.mmdb` 文件。

如果启动时文件不存在，程序会自动从默认地址下载：

```text
https://github.com/NetworkCats/Merged-IP-Data/releases/latest/download/Merged-IP.mmdb
```

### 手动下载默认数据库

```bash
go run . -d 1
```

### 从指定 URL 下载数据库

```bash
go run . -d "https://example.com/path/to/Merged-IP.mmdb"
```

下载完成后会保存为：

```text
./Merged-IP.mmdb
```

## 接口说明

所有接口均返回 JSON。

以下示例不包含 API Key；如果已配置 `GEOIP_API_KEY`，请按上方鉴权方式传入密钥。

### 完整查询

请求路径：

```text
/
```

示例：

```bash
curl "http://127.0.0.1:8080/?ip=8.8.8.8"
```

批量查询：

```bash
curl "http://127.0.0.1:8080/?ip=8.8.8.8,1.1.1.1"
```

响应示例：

```json
[
  {
    "ip": "8.8.8.8",
    "data": {
      "city": {},
      "continent": {},
      "country": {},
      "location": {},
      "asn": {},
      "proxy": {}
    }
  }
]
```

如果 IP 无效，会返回：

```json
[
  {
    "ip": "invalid-ip",
    "error": "无效的 IP 地址"
  }
]
```

### 简化查询

请求路径：

```text
/s
```

示例：

```bash
curl "http://127.0.0.1:8080/s?ip=8.8.8.8"
```

响应字段：

| 字段 | 说明 |
| --- | --- |
| `organization` | ASN 组织名称 |
| `city` | 城市名称 |
| `isp` | ISP / ASN 域名 |
| `asn_organization` | ASN 组织名称 |
| `latitude` | 纬度 |
| `asn` | ASN 编号 |
| `continent_code` | 大洲代码 |
| `country` | 国家或地区名称 |
| `timezone` | 时区 |
| `country_code` | 国家或地区代码 |
| `longitude` | 经度 |
| `region` | 省/州/区域名称 |
| `ip` | 查询的 IP |
| `region_code` | 省/州/区域代码 |

响应示例：

```json
[
  {
    "organization": "Google LLC",
    "city": "",
    "isp": "google.com",
    "asn_organization": "Google LLC",
    "latitude": 0,
    "asn": 15169,
    "continent_code": "NA",
    "country": "美国",
    "timezone": "",
    "country_code": "US",
    "longitude": 0,
    "region": "",
    "ip": "8.8.8.8",
    "region_code": ""
  }
]
```

### 指定语言

请求路径：

```text
/s/{lang}
```

示例：

```bash
curl "http://127.0.0.1:8080/s/en?ip=8.8.8.8"
```

支持语言：

- `en`
- `de`
- `es`
- `fr`
- `ja`
- `pt-BR`
- `ru`
- `zh-CN`

如果传入不支持的语言，会自动回退到 `zh-CN`。

## 自动识别客户端 IP

当请求未传入 `ip` 参数时，服务会按以下优先级识别客户端 IP：

1. `X-Forwarded-For`
2. `X-Real-IP`
3. `Forwarded`
4. `RemoteAddr`
5. `127.0.0.1`

示例：

```bash
curl "http://127.0.0.1:8080/s"
```

## 参数说明

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `-p` | `8080` | HTTP 服务监听端口 |
| `-d` | 空 | 下载数据库并退出。值为 `1` 时使用默认下载地址，其他值会作为下载 URL |

## 环境变量

| 变量名 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `GEOIP_API_KEY` | 否 | 空 | HTTP 接口鉴权密钥；未配置时不启用鉴权 |

## 开发

### 格式化代码

```bash
gofmt -w main.go
```

### 更新依赖

```bash
go mod tidy
```

### 运行测试

```bash
go test ./...
```

## 注意事项

- `Merged-IP.mmdb` 是运行时数据库文件，通常不建议提交到版本库。
- `.env` 可能包含敏感密钥，通常不建议提交到版本库。
- 如需保护接口，请配置自定义 `GEOIP_API_KEY`。
- 批量查询使用英文逗号分隔 IP。
- 查询结果取决于 `Merged-IP.mmdb` 中实际包含的数据字段。
- 简化查询中的地名语言依赖数据库内 `names` 字段是否包含对应语言。

## 开源协议

本项目基于 [MIT License](./LICENSE) 开源。

## 致谢

本项目移植自 [longlegmax/goip](https://github.com/longlegmax/goip)，感谢原项目作者的开源贡献。
