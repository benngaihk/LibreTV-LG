#!/usr/bin/env bash
# 打包 LibreTV webOS 应用 → webos/out/org.libretv.webos_<版本>_all.ipk
#
# 用法：
#   ./build.sh                              # 打包（首次启动时在电视上输入服务器地址）
#   ./build.sh --url http://192.168.1.10:8080   # 把默认服务器地址写进安装包
#
# 依赖：Node.js（自动通过 npx 使用 @webos-tools/cli，已全局安装 ares-package 则直接使用）
set -euo pipefail

cd "$(dirname "$0")"

URL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) URL="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

cp appinfo.json index.html config.js icon.png largeIcon.png splash.png "$STAGE/"

if [[ -n "$URL" ]]; then
  # 仅允许 http(s) 地址，且转义单引号/反斜杠，避免写坏 config.js
  [[ "$URL" =~ ^https?:// ]] || { echo "--url 必须以 http:// 或 https:// 开头" >&2; exit 1; }
  ESCAPED="${URL//\\/\\\\}"; ESCAPED="${ESCAPED//\'/\\\'}"
  printf "window.LIBRETV_DEFAULT_URL = '%s';\n" "$ESCAPED" > "$STAGE/config.js"
fi

mkdir -p out
if command -v ares-package >/dev/null 2>&1; then
  ares-package "$STAGE" -o out
else
  npx -y -p @webos-tools/cli ares-package "$STAGE" -o out
fi

echo
ls -1 out/*.ipk
