#!/usr/bin/env bash
# Rà văn phong "AI" (sycophancy, từ sáo rỗng, hedging, lạm dụng gạch ngang...) trong markdown. Giữ nguyên code, URL, heading.
# Chế độ deterministic (regex, không gọi API, không tốn token).
# MẶC ĐỊNH CHỈ HIỆN DIFF. Bộ luật của unslop viết cho tiếng Anh: với tiếng Việt nó có thể sửa sai
# (vd viết hoa "iOS" → "IOS" ở đầu câu). Xem diff rồi mới ghi bằng --write.
# Dùng:  tools/unslop-docs.sh docs/product/PRD.md            # xem diff
#        tools/unslop-docs.sh --write store/listing.en.md     # ghi đè (git là backup)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/.venv-tools/bin/unslop"
[ -x "$BIN" ] || { echo "Chưa cài. Chạy tools/ai-tools-setup.sh"; exit 1; }
MODE_ARGS=(--diff)
if [ "${1:-}" = "--write" ]; then MODE_ARGS=(--no-backup); shift; fi
[ $# -gt 0 ] || { echo "Cần ít nhất 1 file"; exit 1; }
"$BIN" --deterministic --mode "${UNSLOP_MODE:-subtle}" "${MODE_ARGS[@]}" "$@"
