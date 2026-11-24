#!/usr/bin/env python3
"""Kiểm ARB (i18n-l10n.md §8 bước 6): key trong template có @description; mọi locale có đủ key (cấp A + pseudo bắt buộc,
locale khác cảnh báo); placeholder khớp template; ngoặc ICU cân bằng. Chạy: python3 tools/check-arb.py"""
import json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIR = ROOT / "apps/client/lib/l10n"
TEMPLATE = DIR / "app_en.arb"
REQUIRED_FULL = {"en", "vi", "en_XA"}   # cấp A + pseudo; locale cấp B được phép thiếu tạm (fallback en)
ARG = re.compile(r"\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*[,}]")

def placeholders(msg: str) -> set:
    return set(ARG.findall(msg))

def balanced(msg: str) -> bool:
    d = 0
    for c in msg:
        d += c == "{"; d -= c == "}"
        if d < 0: return False
    return d == 0

errors, warnings = [], []
tpl = json.loads(TEMPLATE.read_text(encoding="utf-8"))
keys = [k for k in tpl if not k.startswith("@")]
for k in keys:
    meta = tpl.get(f"@{k}")
    if not meta or not meta.get("description"):
        errors.append(f"app_en.arb: '{k}' thiếu @{k}.description")
for f in sorted(DIR.glob("app_*.arb")):
    data = json.loads(f.read_text(encoding="utf-8"))
    loc = data.get("@@locale", f.stem[4:])
    for k in keys:
        if k not in data:
            (errors if loc in REQUIRED_FULL else warnings).append(f"{f.name}: thiếu '{k}'")
            continue
        if not balanced(data[k]):
            errors.append(f"{f.name}: '{k}' ngoặc ICU không cân bằng")
        if placeholders(data[k]) != placeholders(tpl[k]):
            errors.append(f"{f.name}: '{k}' placeholder {sorted(placeholders(data[k]))} ≠ template {sorted(placeholders(tpl[k]))}")
    for k in data:
        if not k.startswith("@") and k not in tpl:
            errors.append(f"{f.name}: key thừa '{k}' (không có trong template)")
for w in warnings: print("warn:", w)
for e in errors: print(e)
print(f"check-arb: {len(keys)} key, {len(list(DIR.glob('app_*.arb')))} locale, {len(errors)} lỗi, {len(warnings)} cảnh báo")
sys.exit(1 if errors else 0)
