FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o geoip .

RUN apk add --no-cache curl \
    && curl -fL --retry 3 -o Merged-IP.mmdb "https://github.com/NetworkCats/Merged-IP-Data/releases/latest/download/Merged-IP.mmdb"

FROM alpine:3.22

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY --from=builder /app/geoip /app/geoip
COPY --from=builder /app/Merged-IP.mmdb /app/Merged-IP.mmdb

ENV GEOIP_API_KEY=""

EXPOSE 8080

CMD ["/app/geoip"]
