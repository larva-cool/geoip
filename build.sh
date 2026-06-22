#!/usr/bin/env sh

set -eu

APP_NAME="geoip"
OUTPUT_DIR="dist"
LDFLAGS="-s -w"

PLATFORMS="\
linux/amd64 \
linux/arm64 \
darwin/amd64 \
darwin/arm64 \
windows/amd64 \
windows/arm64\
"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

for platform in $PLATFORMS; do
  GOOS="${platform%/*}"
  GOARCH="${platform#*/}"
  EXT=""

  if [ "$GOOS" = "windows" ]; then
    EXT=".exe"
  fi

  OUTPUT="$OUTPUT_DIR/${APP_NAME}_${GOOS}_${GOARCH}${EXT}"

  echo "Building $GOOS/$GOARCH -> $OUTPUT"
  CGO_ENABLED=0 GOOS="$GOOS" GOARCH="$GOARCH" go build -trimpath -ldflags="$LDFLAGS" -o "$OUTPUT" .
done

echo "Build completed. Output directory: $OUTPUT_DIR"
