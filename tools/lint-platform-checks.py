#!/usr/bin/env python3
"""Chỉ code trong packages/platform/** và apps/*/lib/platform/** được dò nền tảng (architecture/multi-platform.md §2 quy tắc 3).
Nơi khác dùng PlatformCapabilities. Package Dart thuần (core, data, parsers) không được import Flutter hay dart:io Platform.
Chạy: python3 tools/lint-platform-checks.py"""
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PLATFORM_USE = re.compile(r"\bPlatform\.(is[A-Z]\w*|operatingSystem)\b|\bdefaultTargetPlatform\b|\bTargetPlatform\.\w+")
FLUTTER_IMPORT = re.compile(r"""import\s+['"](package:flutter/|package:material_ui/|package:cupertino_ui/|dart:ui)""")
PURE = ["packages/core", "packages/data", "packages/parsers"]

def allowed(p: pathlib.Path) -> bool:
    rel = p.relative_to(ROOT).as_posix()
    return rel.startswith("packages/platform/") or re.match(r"apps/[^/]+/lib/platform/", rel) is not None

errors = []
for f in list(ROOT.glob("apps/*/lib/**/*.dart")) + list(ROOT.glob("packages/*/lib/**/*.dart")):
    if f.name.endswith(".g.dart") or f.name.startswith("app_localizations"):
        continue
    rel = f.relative_to(ROOT).as_posix()
    for n, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
        if line.lstrip().startswith("//"):
            continue
        if PLATFORM_USE.search(line) and not allowed(f):
            errors.append(f"{rel}:{n}: dò nền tảng ngoài lib/platform/ (dùng PlatformCapabilities)")
        if any(rel.startswith(p + "/") for p in PURE) and FLUTTER_IMPORT.search(line):
            errors.append(f"{rel}:{n}: package Dart thuần không được import Flutter")
for e in errors:
    print(e)
print(f"lint-platform-checks: {len(errors)} lỗi")
sys.exit(1 if errors else 0)
