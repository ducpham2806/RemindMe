# Mẫu nhà cung cấp (T2)

Mỗi file `<id>.json` là 1 mẫu theo `template.schema.json` (giải thích: `docs/architecture/on-device-extraction.md` §4.2).
Engine: `lib/src/engine/template.dart` (`ProviderTemplate`, `TemplateReader`, `RuleEngine`).

- Chưa có mẫu thật: mỗi mẫu cần ≥ 10 tài liệu thật đã ẩn danh trong `fixtures/docs/` (E4.3) để xác nhận định dạng. Không viết mẫu theo trí nhớ.
- Mẫu ví dụ cho test nằm trong `test/engine_test.dart` (nhà cung cấp giả `ZZ AIR`).
- CI kiểm mọi file ở đây theo schema (`tools/validate-fixtures.py`). Ký Ed25519 và phát hành qua CDN: E4.4, chưa làm.
