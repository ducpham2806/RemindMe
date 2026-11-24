#!/usr/bin/env bash
# Cài graphify + unslop vào .venv-tools (không đụng Python hệ thống). Chạy 1 lần mỗi máy / mỗi phiên cloud mới.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENV="$ROOT/.venv-tools"
[ -x "$VENV/bin/python" ] || python3 -m venv "$VENV"
"$VENV/bin/pip" install -q --upgrade pip
"$VENV/bin/pip" install -q -r "$ROOT/tools/requirements-tools.txt"
echo "OK: $("$VENV/bin/graphify" --version 2>/dev/null || echo graphify) | $("$VENV/bin/unslop" --version)"
