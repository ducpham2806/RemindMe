#!/usr/bin/env python3
"""Kiểm tra tham chiếu trong docs: mọi `*.md`, link markdown tương đối và đường dẫn repo (`supabase/...`, `tools/...`)
phải trỏ tới file có thật. Bỏ qua WORKLOG (lịch sử) và dòng ghi rõ file đã xóa. Chạy: python3 tools/check-docs.py"""
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
FILES = [ROOT / "AGENTS.md", ROOT / "README.md", *DOCS.rglob("*.md")]
SKIP_FILES = {DOCS / "WORKLOG.md"}
SKIP_LINE = re.compile(r"đã xóa|superseded|thay cho", re.I)
TICK = re.compile(r"`([A-Za-z0-9_./-]+\.(?:md|sql|sh|py|json|csv))`")
LINK = re.compile(r"\]\((?!https?://|mailto:|#)([^)#\s]+)")
REPO_PREFIX = ("docs/", "supabase/", "tools/", "packages/", "apps/", "services/", ".github/")
basenames = {}
for p in DOCS.rglob("*"):
    basenames.setdefault(p.name, []).append(p)

def resolves(ref: str, src: pathlib.Path) -> bool:
    if ref.startswith(("apps/", "services/")):
        return True  # thư mục dự kiến, chưa có code
    cands = [src.parent / ref, ROOT / ref, DOCS / ref]
    if any(c.exists() for c in cands):
        return True
    return "/" not in ref and ref in basenames

errors = []
for f in FILES:
    if f in SKIP_FILES:
        continue
    for n, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
        if SKIP_LINE.search(line):
            continue
        refs = TICK.findall(line) + LINK.findall(line)
        for ref in refs:
            if "<" in ref or "*" in ref or "YYYY" in ref:
                continue  # mẫu đường dẫn
            if ref.endswith(".md") or ref.startswith(REPO_PREFIX) or ref in LINK.findall(line):
                if not resolves(ref, f):
                    errors.append(f"{f.relative_to(ROOT)}:{n}: không tìm thấy '{ref}'")
for e in errors:
    print(e)
print(f"check-docs: {len(FILES)} file, {len(errors)} tham chiếu hỏng")
sys.exit(1 if errors else 0)
