#!/usr/bin/env python3
"""Kiểm tra bộ mẫu tài liệu (E0.4): cấu trúc thư mục, meta.json/expected.json đúng schema, dấu hiệu chưa ẩn danh.
Cần: pip install jsonschema. Chạy: python3 tools/validate-fixtures.py"""
import json, pathlib, re, sys
from jsonschema import Draft202012Validator

ROOT = pathlib.Path(__file__).resolve().parent.parent / "packages/parsers/fixtures"
SCHEMA = {n: Draft202012Validator(json.loads((ROOT / f"schema/{n}.schema.json").read_text()))
          for n in ("meta", "expected")}
ALLOWED = {"meta.json", "expected.json", "ocr.android.json", "ocr.ios.json", "README.md"}
# Dấu hiệu dữ liệu thật còn sót (chỉ quét file văn bản). Mẫu đã che dùng X/9 theo README.
PII = [("email", re.compile(r"[\w.+-]+@(?!example\.(?:com|org|net)\b)[\w-]+\.[\w.]+")),
       ("chuỗi số dài (SĐT/CCCD/số vé)", re.compile(r"(?<!\d)(?!9+\b)\d[\d .-]{9,}\d(?!\d)"))]

errors, count = [], 0
for d in sorted(p for p in (ROOT / "docs").iterdir() if p.is_dir()):
    count += 1
    names = {f.name for f in d.iterdir()}
    inputs = [n for n in names if n.startswith("input.")]
    if len(inputs) != 1:
        errors.append(f"{d.name}: cần đúng 1 file input.<ext>, có {inputs}")
    for extra in names - ALLOWED - set(inputs):
        errors.append(f"{d.name}: file lạ '{extra}'")
    for kind in ("meta", "expected"):
        f = d / f"{kind}.json"
        if not f.exists():
            errors.append(f"{d.name}: thiếu {f.name}")
            continue
        data = json.loads(f.read_text(encoding="utf-8"))
        for e in SCHEMA[kind].iter_errors(data):
            errors.append(f"{d.name}/{f.name}: {'/'.join(map(str, e.path))}: {e.message}")
        if kind == "meta" and data.get("id") != d.name:
            errors.append(f"{d.name}/meta.json: id phải trùng tên thư mục")
    for n in inputs:
        f = d / n
        if f.suffix in (".txt", ".md", ".eml", ".csv", ".ics", ".html"):
            text = f.read_text(encoding="utf-8", errors="replace")
            for label, rx in PII:
                for m in rx.finditer(text):
                    errors.append(f"{d.name}/{n}: nghi chưa ẩn danh ({label}): '{m.group(0)[:24]}'")
for e in errors:
    print(e)
print(f"validate-fixtures: {count} mẫu, {len(errors)} lỗi")
sys.exit(1 if errors else 0)
