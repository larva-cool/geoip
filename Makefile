.DEFAULT_GOAL := help

APP_NAME := geoip
GO ?= go
BIN_DIR := bin
BINARY := $(BIN_DIR)/$(APP_NAME)
DIST_DIR := dist
PORT ?= 8080
DB_URL ?= 1
LDFLAGS ?= -s -w
DOCKER_IMAGE ?= geoip:latest

.PHONY: help build run start test vet fmt tidy check release clean download-db docker-build docker-run

help: ## 显示可用命令
	@printf "GeoIP 项目常用命令：\n\n"
	@printf "  make build                  编译当前平台二进制到 %s\n" "$(BINARY)"
	@printf "  make run [PORT=8080]        使用 go run 启动服务\n"
	@printf "  make start [PORT=8080]      运行已编译的二进制\n"
	@printf "  make test                   运行全部测试\n"
	@printf "  make vet                    执行 go vet 静态检查\n"
	@printf "  make fmt                    格式化 Go 代码\n"
	@printf "  make tidy                   整理 Go 模块依赖\n"
	@printf "  make check                  依次执行格式化、静态检查和测试\n"
	@printf "  make release                构建全部发布平台二进制到 %s/\n" "$(DIST_DIR)"
	@printf "  make download-db            下载默认 IP 数据库\n"
	@printf "  make download-db DB_URL=url 从指定地址下载 IP 数据库\n"
	@printf "  make docker-build           构建 Docker 镜像\n"
	@printf "  make docker-run [PORT=8080] 运行 Docker 容器\n"
	@printf "  make clean                  清理编译产物\n"

build: ## 编译当前平台二进制
	@mkdir -p $(BIN_DIR)
	CGO_ENABLED=0 $(GO) build -trimpath -ldflags="$(LDFLAGS)" -o $(BINARY) .

run: ## 使用 go run 启动服务
	$(GO) run . -p $(PORT)

start: build ## 编译并启动服务
	./$(BINARY) -p $(PORT)

test: ## 运行全部测试
	$(GO) test ./...

vet: ## 执行静态检查
	$(GO) vet ./...

fmt: ## 格式化 Go 代码
	$(GO) fmt ./...

tidy: ## 整理模块依赖
	$(GO) mod tidy

check: fmt vet test ## 执行完整本地检查

release: ## 构建全部发布平台二进制
	./build.sh

download-db: ## 下载 IP 数据库，DB_URL=1 表示默认地址
	$(GO) run . -d "$(DB_URL)"

docker-build: ## 构建 Docker 镜像
	docker build -t $(DOCKER_IMAGE) .

docker-run: ## 运行 Docker 容器
	docker run --rm --name $(APP_NAME) -p $(PORT):8080 \
		-e GEOIP_API_KEY="$(GEOIP_API_KEY)" $(DOCKER_IMAGE)

clean: ## 清理编译产物，不删除 IP 数据库
	rm -rf $(BIN_DIR) $(DIST_DIR)
