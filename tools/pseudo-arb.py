#!/usr/bin/env python3
"""Sinh pseudo-locale en_XA từ app_en.arb (i18n-l10n.md §8 bước 4): chữ có dấu lạ, dài thêm ~40%, bọc [ ].
Hiểu cú pháp ICU: không đụng tên placeholder, từ khóa plural/select, chỉ biến đổi phần chữ.
Chạy: python3 tools/pseudo-arb.py [--check]   (--check: báo lỗi nếu file đang commit chưa cập nhật)"""
import json, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "apps/client/lib/l10n/app_en.arb"
DST = ROOT / "apps/client/lib/l10n/app_en_XA.arb"
ACCENT = dict(zip("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
                  "àƀçđéƒĝĥîĵķļɱñöþǫŕšţûṽŵẋýžÀƁÇĐÉƑĜĤÎĴĶĻṀÑÖÞǪŔŠŢÛṼŴẊÝŽ"))
PAD = "~"

def text(s: str) -> str:
    out = "".join(ACCENT.get(c, c) for c in s)
    letters = sum(c.isalpha() for c in s)
    return out + (PAD * round(letters * 0.4) if letters else "")

def icu(s: str, i: int = 0, depth: int = 0):
    """Trả (chuỗi đã biến đổi, vị trí kết thúc). depth>0: đang trong sub-message, dừng ở '}' cân bằng."""
    out, buf = [], []
    while i < len(s):
        c = s[i]
        if c == "{":
            out.append(text("".join(buf))); buf = []
            arg, i = argument(s, i)
            out.append(arg)
            continue
        if c == "}" and depth > 0:
            break
        buf.append(c); i += 1
    out.append(text("".join(buf)))
    return "".join(out), i

def argument(s: str, i: int):
    """s[i] == '{'. Placeholder đơn giản giữ nguyên; plural/select thì biến đổi từng sub-message."""
    j = i + 1
    while j < len(s) and s[j] not in ",}":
        j += 1
    if s[j] == "}":
        return s[i:j + 1], j + 1
    k = s.index(",", j + 1)
    kind = s[j + 1:k].strip()
    if kind not in ("plural", "select", "selectordinal"):
        end = s.index("}", k)
        return s[i:end + 1], end + 1
    out = [s[i:k + 1]]
    p = k + 1
    while True:
        while s[p].isspace():
            out.append(s[p]); p += 1
        if s[p] == "}":
            out.append("}"); return "".join(out), p + 1
        q = s.index("{", p)
        out.append(s[p:q + 1])
        sub, e = icu(s, q + 1, 1)
        out.append(sub + "}")
        p = e + 1

def main():
    src = json.loads(SRC.read_text(encoding="utf-8"))
    dst = {"@@locale": "en_XA"}
    for k, v in src.items():
        if k.startswith("@"):
            continue
        dst[k] = v if k == "appTitle" else "[" + icu(v)[0] + "]"
    rendered = json.dumps(dst, ensure_ascii=False, indent=2) + "\n"
    if "--check" in sys.argv:
        if not DST.exists() or DST.read_text(encoding="utf-8") != rendered:
            print("pseudo-arb: app_en_XA.arb chưa cập nhật, chạy python3 tools/pseudo-arb.py"); sys.exit(1)
        print("pseudo-arb: OK"); return
    DST.write_text(rendered, encoding="utf-8")
    print(f"pseudo-arb: {len(dst) - 1} key → {DST.relative_to(ROOT)}")

main()
