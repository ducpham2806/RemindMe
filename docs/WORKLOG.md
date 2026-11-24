# WORKLOG

> Nhật ký công việc. **Entry mới thêm ở ĐẦU** (ngay dưới khối mẫu). Đọc nhanh: `head -60 docs/WORKLOG.md`.
> Khi file > 400 dòng: chuyển các entry cũ sang `docs/worklog/archive/YYYY-MM.md`.

<!-- MẪU (copy, không sửa khối này)
## YYYY-MM-DD · <tiêu đề ngắn> · <người/agent>
- **Làm:** ...
- **Quyết định:** ... (ADR-xxx nếu có)
- **File:** ...
- **Kiểm chứng:** lệnh/test đã chạy + kết quả
- **Dở dang / tiếp theo:** ...
-->

## 2026-11-24 · Khởi tạo bộ tài liệu Phase 0 · Claude Code
- **Làm:**
  - Viết bộ tài liệu hệ thống, UI/UX, sản phẩm, tích hợp, kế hoạch (17 file trong `docs/`).
  - Nghiên cứu đối thủ bằng 1 subagent (persona Trend Researcher): `docs/research/competitor-analysis.md`.
  - Dựng context phân tầng cho AI: `AGENTS.md` (Codex) + `CLAUDE.md` (import AGENTS + STATE).
  - Cài và thử graphify 0.9.118 + unslop 0.7.0; viết script wrapper trong `tools/`.
- **Quyết định:**
  - Stack: Flutter + watch native, Supabase + worker TS, offline-first, Claude API phía server, RevenueCat (ADR-001..009).
  - Giá đề xuất 59.000đ/tháng, 149.000đ/quý, 449.000đ/năm.
  - Free: 10 nhắc/ngày, 5 chuỗi lặp, 10 lịch hẹn đang hoạt động (gồm booking), 1 chuyến đi, 10 import AI/tháng.
  - Email forward trước, Gmail API sau (tránh CASA sớm). Import Microsoft To Do vào MVP, vì app To Do ngừng 30/06/2027 (đã kiểm chứng qua nhiều nguồn tin 11/2026).
- **Kiểm chứng:**
  - `graphify update .`: 193 node, 174 cạnh, 20 cộng đồng. `graphify benchmark`: ~877 token/query so với ~12,9k token đọc thô (giảm 14,7 lần).
  - `query` và `section` chạy được sau khi thêm `anyio` vào requirements.
  - unslop `--diff` trên toàn bộ docs: 0 AI-ism. Hai sửa đổi nó đề xuất là sai ("iOS" thành "IOS", "watchOS" thành "WatchOS"), nên script để mặc định chỉ hiện diff.
- **Dở dang / tiếp theo:** xem `docs/STATE.md`. Các con số giá/giới hạn và thời gian chờ duyệt store/OAuth là ước lượng, cần xác minh.
