# AGENTS.MD

## 项目概述

本项目是一个 Go 编写的 GeoIP HTTP 查询服务，使用 `github.com/oschwald/maxminddb-golang` 读取本地 MaxMind MMDB 数据库文件 `Merged-IP.mmdb`，对外提供 IP 地理位置、ASN、代理/VPN 等信息查询能力。

服务启动时会检查当前目录是否存在 `Merged-IP.mmdb`：

- 如果不存在，会自动从默认地址下载数据库。
- 如果使用下载参数启动，则只下载数据库并退出。

## 技术栈

- 语言：Go
- 模块名：`geoip`
- Go 版本：`1.25.0`
- 核心依赖：`github.com/oschwald/maxminddb-golang`
- 数据库文件：`./Merged-IP.mmdb`

## 启动与运行

### 启动服务

```bash
go run .
```

默认监听端口为 `8080`。

### 指定端口

```bash
go run . -p 8080
```

### 下载默认 IP 数据库

```bash
go run . -d 1
```

默认下载地址：

```text
https://github.com/NetworkCats/Merged-IP-Data/releases/latest/download/Merged-IP.mmdb
```

### 从指定 URL 下载 IP 数据库

```bash
go run . -d "https://example.com/path/to/Merged-IP.mmdb"
```

下载完成后文件保存为当前目录下的 `Merged-IP.mmdb`。

## HTTP 接口

### 完整查询接口

路径：`/`

示例：

```bash
curl "http://127.0.0.1:8080/?ip=8.8.8.8"
```

支持批量查询，多个 IP 使用英文逗号分隔：

```bash
curl "http://127.0.0.1:8080/?ip=8.8.8.8,1.1.1.1"
```

返回结构为数组，每项包含：

- `ip`：查询的 IP
- `data`：完整 MMDB 查询结果
- `error`：无效 IP 或查询失败时返回错误信息

如果未传入 `ip` 参数，服务会根据请求头和连接信息自动识别客户端 IP。

### 简化查询接口

路径：`/s`

示例：

```bash
curl "http://127.0.0.1:8080/s?ip=8.8.8.8"
```

返回简化字段：

- `organization`
- `city`
- `isp`
- `asn_organization`
- `latitude`
- `asn`
- `continent_code`
- `country`
- `timezone`
- `country_code`
- `longitude`
- `region`
- `ip`
- `region_code`

### 指定语言的简化查询

路径：`/s/{lang}`

示例：

```bash
curl "http://127.0.0.1:8066/s/en?ip=8.8.8.8"
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

不支持的语言会回退到 `zh-CN`。

## 客户端 IP 识别规则

当请求未提供 `ip` 参数时，服务按以下优先级识别真实客户端 IP：

1. `X-Forwarded-For`
2. `X-Real-IP`
3. `Forwarded`
4. `RemoteAddr`
5. 默认值 `127.0.0.1`

## 代码结构说明

当前主要逻辑集中在 `main.go`：

- `IPRecord`：完整 MMDB 数据结构映射。
- `IPResult`：完整查询接口返回结构。
- `SimpleIPResult`：简化查询接口返回结构。
- `init`：解析启动参数、处理数据库下载、检查数据库文件。
- `main`：打开 MMDB 数据库并启动 HTTP 服务。
- `serveSimpleIP`：解析简化接口语言路径。
- `getRealIP`：从请求头和远端地址识别客户端 IP。
- `isValidLang`：校验支持的语言代码。
- `querySimpleIPWithLang`：执行简化 IP 查询。
- `queryIP`：执行完整 IP 查询。
- `writeJSON`：统一 JSON 响应输出。
- `downloadIpDb` / `downloadFile`：下载数据库文件并显示进度。
- `formatSize`：格式化下载进度中的文件大小。
- `checkIpDbIsExist`：检查数据库文件是否存在，不存在则自动下载。

## 开发注意事项

1. 保持 `Merged-IP.mmdb` 为运行时数据文件，不要把大体积数据库文件提交到版本库，除非项目明确要求。
2. 修改查询结构时，需要同时关注 `maxminddb` 标签和 `json` 标签。
3. 简化接口依赖 MMDB 中的多语言 `names` 字段，新增语言前需要确认数据库是否包含该语言。
4. 批量查询使用 goroutine 并发处理，修改结果写入逻辑时要保持索引稳定。
5. 下载数据库时，如果目标文件已存在，会先写入 `.tmp` 临时文件，下载成功后再覆盖原文件。
6. 修改 HTTP 响应时，应保持 `Content-Type: application/json`。

## 验证建议

修改代码后建议执行：

```bash
go test ./...
```

如果只是修改格式，可执行：

```bash
gofmt -w main.go
```

手动验证服务：

```bash
go run . -p 8066
curl "http://127.0.0.1:8080/?ip=8.8.8.8"
curl "http://127.0.0.1:8080/s/zh-CN?ip=8.8.8.8"
```
