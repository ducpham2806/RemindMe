#!/usr/bin/env python3
"""Chặn chuỗi hiển thị hard-code trong Flutter (AGENTS.md quy tắc 5b, i18n-l10n.md).
Bắt chuỗi literal có chữ cái nằm trong các widget/tham số hiển thị: Text('..'), labelText: '..', tooltip: '..'...
Cho phép bỏ qua 1 dòng bằng comment `// l10n-ignore` (ví dụ tên thương hiệu, mã IATA demo).
Chạy: python3 tools/lint-hardcoded-strings.py [thư mục ...]  (mặc định apps/*/lib)"""
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
targets = [pathlib.Path(a) for a in sys.argv[1:]] or [p for p in ROOT.glob("apps/*/lib") if p.is_dir()]
STR = r"""(?:'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")"""
PATTERNS = [
    re.compile(r"\b(?:Text|SelectableText|Tooltip|SnackBar|Semantics)\s*\(\s*(" + STR + ")"),
    re.compile(r"\b(?:labelText|hintText|helperText|errorText|tooltip|semanticLabel|semanticsLabel|title|message|label)\s*:\s*(?:const\s+)?(?:Text\s*\(\s*)?(" + STR + ")"),
]
LETTER = re.compile(r"[^\W\d_]", re.UNICODE)
INTERP_ONLY = re.compile(r"""^['"]\$\{?[\w.]+\}?['"]$""")

errors = []
files = [f for t in targets if t.exists() for f in t.rglob("*.dart")
         if not f.name.endswith((".g.dart", ".freezed.dart")) and "l10n" not in f.parts and "generated" not in f.parts]
for f in files:
    for n, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
        if "l10n-ignore" in line or line.lstrip().startswith("//"):
            continue
        for pat in PATTERNS:
            for m in pat.finditer(line):
                lit = m.group(1)
                body = lit[1:-1]
                if LETTER.search(re.sub(r"\$\{[^}]*\}|\$\w+", "", body)) and not INTERP_ONLY.match(lit):
                    msg = f"{f}:{n}: chuỗi hard-code {lit} (dùng AppLocalizations / ARB)"
                    if msg not in errors:
                        errors.append(msg)
for e in errors:
    print(e)
print(f"lint-hardcoded-strings: {len(files)} file dart, {len(errors)} lỗi")
sys.exit(1 if errors else 0)
