#!/usr/bin/env bash
# Trỏ git hooks về tools/hooks (commit-msg). Chạy 1 lần sau khi clone.
set -euo pipefail
cd "$(dirname "$0")/.."
git config core.hooksPath tools/hooks
echo "git hooks: tools/hooks"
