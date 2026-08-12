#!/bin/bash
# spicoclaw 统一构建接口 (M1 规范 v0.1)
# 用法: bash release.sh [ARCH] [VERSION]
#   ARCH:    arm64 | amd64 | all（默认 arm64）
#   VERSION: 显式版本号（默认 0.3.1）
#   env OUTPUT_DIR: 产物目录（默认 <repo>/output/spicoclaw/）
#   env PICOCLAW_BIN_DIR: 覆盖二进制来源目录（默认 binary/<arch>/）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
cd "$SCRIPT_DIR"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ARCH="${1:-arm64}"
VERSION="${2:-0.3.1}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/output/spicoclaw}"

case "$ARCH" in
  arm64|amd64) ;;
  all) ARCH_LIST="arm64 amd64" ;;
  *) echo "ERROR: ARCH 必须是 arm64|amd64|all，得到: $ARCH" >&2; exit 1 ;;
esac

mkdir -p "$OUTPUT_DIR"

build_one() {
  local arch="$1"
  echo "==> spicoclaw build arch=$arch version=$VERSION"
  bash build/build-deb-spicoclaw.sh "$VERSION" "$arch"
  local deb="release/spicoclaw_${VERSION}_${arch}.deb"
  if [ ! -f "$deb" ]; then
    echo "ERROR: 未找到产物 $deb" >&2
    exit 1
  fi
  cp "$deb" "$OUTPUT_DIR/"
  file "$deb" | head -1
}

if [ -n "${ARCH_LIST:-}" ]; then
  for a in $ARCH_LIST; do build_one "$a"; done
else
  build_one "$ARCH"
fi

echo "==> spicoclaw 完成, 产物: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"