#!/bin/bash
# spicoclaw .deb 打包：组装 sophpicoclaw 服务 + 预编译 picoclaw 二进制。
#
# 用法: bash build/build-deb-spicoclaw.sh [VERSION] [ARCH]
#   VERSION 默认 0.3.1（picoclaw 定制版版本）
#   ARCH    默认 arm64（设备）；amd64 用于 PCIE/开发机
# 产物: release/spicoclaw_${VERSION}_${ARCH}.deb
#
# 二进制来源（按优先级）:
#   1. env PICOCLAW_BIN_DIR: 显式指定二进制目录（含 picoclaw、picoclaw-launcher）
#   2. binary/<arch>/: 仓库内置的定制版预编译二进制
#   3. 失败报错退出（不静默使用错误版本）
set -e

cd "$(dirname "$0")/.."
VERSION="${1:-0.3.1}"
# 版本号不允许进入 sed 替换分隔符；若含 / 则替换为 -（同时保持产物名一致）
VERSION="${VERSION//\//-}"
ARCH="${2:-arm64}"

case "$ARCH" in
  arm64|amd64) ;;
  *) echo "ERROR: ARCH 必须是 arm64|amd64，得到: $ARCH" >&2; exit 1 ;;
esac

# 1. 确定二进制来源
BIN_SRC="${PICOCLAW_BIN_DIR:-}"
if [ -z "$BIN_SRC" ]; then
  BIN_SRC="binary/$ARCH"
fi
for f in picoclaw picoclaw-launcher; do
  if [ ! -f "$BIN_SRC/$f" ]; then
    echo "ERROR: 缺少二进制 $BIN_SRC/$f（用 PICOCLAW_BIN_DIR 指定或放入 binary/$ARCH/）" >&2
    exit 1
  fi
done

# 2. 组装 deb 数据树（绝对路径布局，postinst 建运行目录）
DEBROOT=build/deb/spicoclaw-root
rm -rf "$DEBROOT"
mkdir -p "$DEBROOT/DEBIAN" \
         "$DEBROOT/opt/sophon/picoclaw/bin" \
         "$DEBROOT/usr/lib/systemd/system"

cp "$BIN_SRC/picoclaw" "$DEBROOT/opt/sophon/picoclaw/bin/picoclaw"
cp "$BIN_SRC/picoclaw-launcher" "$DEBROOT/opt/sophon/picoclaw/bin/picoclaw-launcher"
chmod 0755 "$DEBROOT/opt/sophon/picoclaw/bin/picoclaw" "$DEBROOT/opt/sophon/picoclaw/bin/picoclaw-launcher"
cp build/sophpicoclaw.service "$DEBROOT/usr/lib/systemd/system/sophpicoclaw.service"
cp build/sophpicoclaw-launcher.service "$DEBROOT/usr/lib/systemd/system/sophpicoclaw-launcher.service"

# 3. DEBIAN 控制文件（Version/Architecture 注入）
sed -e "s/@VERSION@/$VERSION/" -e "s/@ARCH@/$ARCH/" \
  build/deb/control > "$DEBROOT/DEBIAN/control"
cp build/deb/postinst "$DEBROOT/DEBIAN/postinst"
cp build/deb/prerm    "$DEBROOT/DEBIAN/prerm"
cp build/deb/postrm   "$DEBROOT/DEBIAN/postrm"
chmod 0755 "$DEBROOT/DEBIAN/postinst" "$DEBROOT/DEBIAN/prerm" "$DEBROOT/DEBIAN/postrm"
chmod 0644 "$DEBROOT/DEBIAN/control"

# 4. md5sums（数据文件校验和，路径不含前导 /，对齐 deb policy）
( cd "$DEBROOT" && find . -type f ! -path './DEBIAN/*' -printf '%P\0' | \
  sort -z | xargs -0 md5sum ) > "$DEBROOT/DEBIAN/md5sums"

# 5. 打包
mkdir -p release
OUT="release/spicoclaw_${VERSION}_${ARCH}.deb"
dpkg-deb --root-owner-group -b "$DEBROOT" "$OUT"
rm -rf "$DEBROOT"

echo
echo "✓ built $OUT"
dpkg-deb -f "$OUT" Package Version Architecture Maintainer
echo "--- contents ---"
dpkg-deb -c "$OUT" | grep -vE '/$'