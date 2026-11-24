# Quy trình phát triển với AI (Claude Code, Codex) + graphify, unslop, agency agents

> TL;DR: Ngữ cảnh chia tầng để mỗi phiên đọc ít token nhất. Dùng graphify để tra thay vì đọc nguyên file,
> unslop để rà văn phong (chủ yếu nội dung tiếng Anh), agency agents làm persona chuyên môn cho từng loại việc.
> Mọi phiên kết thúc bằng cập nhật WORKLOG + STATE.

## 1. Ngân sách ngữ cảnh (token budget)
| Tầng | Nội dung | Khi nào đọc | Mục tiêu kích thước |
|---|---|---|---|
| L0 | `AGENTS.md` (+ `CLAUDE.md` import) | Tự động mỗi phiên | ≤ 1.500 token |
| L1 | `docs/STATE.md` | Tự động (Claude import) / bắt buộc đọc (Codex) | ≤ 800 token |
| L2 | `docs/INDEX.md`, `graphify-out/GRAPH_REPORT.md` | Khi cần tìm tài liệu | ≤ 1.500 token mỗi file |
| L3 | 1 section cụ thể | Khi làm task liên quan | `graphify section` ≤ 2.000 token |
| L4 | Cả file docs / code | Chỉ khi sửa chính file đó | |

Quy tắc giữ L0/L1 nhỏ:
- `STATE.md` chỉ chứa hiện trạng, không chứa lịch sử. Lịch sử nằm trong `WORKLOG.md`.
- `WORKLOG.md`: entry mới ở **đầu** file; đọc bằng `head -60`. Khi > 400 dòng, chuyển phần cũ sang `docs/worklog/archive/YYYY-MM.md`.
- Mỗi file docs mở đầu bằng khối `> TL;DR` 2-4 dòng: đọc `head -8` là đủ biết có cần đọc tiếp không.
- Không dán log dài, output lệnh dài vào docs. Link tới file/commit.
- `.claude/settings.json` chặn Read các file sinh ra lớn (`graph.json`, `graph.html`, cache).

## 2. graphify (knowledge graph của repo)
- Cài: `tools/ai-tools-setup.sh` (venv `.venv-tools`, gồm graphify + unslop + anyio).
- Dựng/cập nhật: `tools/graphify-docs.sh` (lệnh `graphify update .`, không cần API key: markdown được tách theo heading, code theo AST).
  Chạy lại sau khi thêm/sửa nhiều docs hoặc code. Commit `graphify-out/GRAPH_REPORT.md` và `graph.json`.
- Tra cứu:
  ```bash
  G=.venv-tools/bin/graphify
  $G query "import vé máy bay tạo nhắc mặc định" --budget 1500   # BFS quanh các node khớp
  $G section "5. Múi giờ và du lịch"                             # in đúng 1 section (tên heading đầy đủ, kể cả số)
  $G section "docs/architecture/data-model.md#4. Quy tắc đếm quota (thực thi trong RPC \`sync_push\` và trigger)"
  $G explain "Reminder engine: lập lịch, lặp lại, thông báo, đồng hồ"
  $G god-nodes --top 10
  ```
- Đo mức tiết kiệm: `graphify benchmark` (24/11/2026: corpus ~12,9k token, mỗi query ~877 token, giảm khoảng 14,7 lần).
- Khi đã có code nhiều: cân nhắc `graphify claude install` / `graphify codex install` (thêm hook PreToolUse gợi ý dùng graph).
  Chưa bật vì phiên cloud mới phải cài graphify trước thì hook mới chạy.
- Trích xuất ngữ nghĩa sâu (cạnh INFERRED giữa các tài liệu) cần LLM backend (`graphify extract . --backend claude`), tốn token: chỉ chạy khi cần.

## 3. unslop (rà văn phong AI)
- `tools/unslop-docs.sh <file>`: chế độ deterministic, **mặc định chỉ hiện diff**; `--write` để ghi.
- Bộ luật của unslop viết cho tiếng Anh. Với docs tiếng Việt nó gần như không tìm thấy gì, và có thể sửa sai tên riêng
  (đã thấy: "iOS" thành "IOS", "watchOS" thành "WatchOS"). Dùng chính cho: store listing tiếng Anh, landing page, email marketing,
  release notes, docs tiếng Anh khi ra global.
- Với tiếng Việt: tự rà theo danh sách: bỏ câu mở đầu sáo rỗng ("Trong thời đại số..."), bỏ tính từ thổi phồng
  ("vô cùng", "cực kỳ mạnh mẽ", "toàn diện"), câu chủ động, có số liệu thay vì tính từ.

## 4. Agency agents (persona chuyên môn)
Gọi qua skill `agency-agents` (repo `msitarzewski/agency-agents`). Mỗi persona có Critical Rules và mẫu deliverable riêng.
Cách dùng trong prompt: *"Dùng agency agent Backend Architect, thiết kế RPC sync_push theo docs/architecture/data-model.md mục 4"*.

| Phase / việc | Persona |
|---|---|
| Khám phá, phỏng vấn, PRD | Product Manager, UX Researcher, Trend Researcher, Feedback Synthesizer |
| Kiến trúc, ADR | Software Architect, Backend Architect, Database Optimizer |
| UI/UX | UX Architect, UI Designer, Accessibility Auditor, Persona Walkthrough Specialist, Whimsy Injector, Brand Guardian |
| Flutter, watch, widget | Mobile App Builder, Senior Developer, Frontend Developer |
| Trích xuất on-device, OCR, mẫu nhà cung cấp, eval | AI Engineer, PDF Engine Architect, Voice AI Integration Engineer, Model QA Specialist, Test Automation Engineer |
| Email inbound, Gmail | Email Intelligence Engineer |
| Thanh toán, paywall | Payments & Billing Engineer, Pricing Analyst |
| Bảo mật, pháp lý | Security Architect, Privacy Engineer, Data Privacy Officer, Legal Compliance Checker, AppSec Engineer |
| i18n/l10n, gói ngôn ngữ, văn hóa từng thị trường | Internationalization Engineer, Language Translator, Cultural Intelligence Strategist, App Store Optimizer (ASO theo nước) |
| Hạ tầng, CI/CD, release | DevOps Automator, Mobile Release Engineer, SRE |
| Kiểm thử | Test Automation Engineer, API Tester, Performance Benchmarker, Evidence Collector, Reality Checker |
| Review code | Code Reviewer, Minimal Change Engineer, AI-Generated Code Security Auditor |
| Launch & tăng trưởng | App Store Optimizer, Growth Hacker, Content Creator, Social Media Strategist, TikTok Strategist |
| Điều phối nhiều agent | Agents Orchestrator, Senior Project Manager, Sprint Prioritizer |

**NEXUS-Sprint** (playbook của Agency) áp dụng cho Phase 1: Discovery → Strategy → Foundation → Build → Hardening → Launch,
quality gate giữa các phase, vòng Dev↔QA tối đa 3 lần, *Reality Checker* mặc định kết luận "NEEDS WORK" cho tới khi có bằng chứng
(ảnh chụp, số đo, log test). Handoff giữa agent theo mẫu ở mục 5.

## 5. Mẫu handoff (dùng khi chuyển việc giữa persona, giữa phiên, hoặc giữa người)
```markdown
### Handoff: <task>
- Mục tiêu:
- Đã xong: (file:dòng, commit)
- Chưa xong / đang dở:
- Quyết định đã chốt (link ADR):
- Giả định chưa kiểm chứng:
- Bước tiếp theo (1-3 việc cụ thể):
- Lệnh để kiểm tra:
```

## 6. Checklist cuối phiên (bắt buộc)
1. Thêm entry vào đầu `docs/WORKLOG.md`.
2. Cập nhật `docs/STATE.md` (Đang làm, Tiếp theo, Blocker, Câu hỏi mở).
3. Nếu sửa nhiều docs/code: `tools/graphify-docs.sh`.
4. Commit + push nhánh làm việc.
