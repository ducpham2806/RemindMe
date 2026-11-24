#!/usr/bin/env bash
# Dựng knowledge graph cho repo (docs + code) để AI truy vấn thay vì đọc nguyên file.
# Không cần API key: dùng extractor cục bộ (AST cho code, cấu trúc heading cho markdown).
# Kết quả: graphify-out/GRAPH_REPORT.md (commit), graph.json (commit, dùng cho query/section).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/.venv-tools/bin/graphify"
[ -x "$BIN" ] || { echo "Chưa cài. Chạy tools/ai-tools-setup.sh"; exit 1; }
cd "$ROOT"
"$BIN" update . "$@"
echo "Xong. Đọc: graphify-out/GRAPH_REPORT.md | Truy vấn: $BIN query \"...\" --budget 1500"
