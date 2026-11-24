# Bản địa hóa (L0): glossary, style guide, TMS

> TL;DR: Thư mục này là nguồn chuẩn cho thuật ngữ (`glossary.csv`) và văn phong (`style-guide-*.md`) của mọi locale.
> Đề xuất TMS: **Crowdin** (gói Pro), dự phòng **Weblate** hosted; chốt sau 14 ngày dùng thử với ARB thật.
> Dịch giả bản ngữ cấp B nhận glossary + style guide tiếng Anh + ảnh chụp màn hình, tự viết `style-guide-<locale>.md` theo mẫu cuối file.
> Quy trình tổng (key, pseudo-locale, CI, cổng chất lượng) vẫn ở `architecture/i18n-l10n.md` §8-9; file này không chép lại.

## 1. Thư mục có gì
| File | Nội dung | Ai sửa |
|---|---|---|
| `glossary.csv` | 258 thuật ngữ, cột `en`, `vi` đủ; cột cấp B chỉ điền thuật ngữ nền tảng đã chắc chắn | L10n lead qua PR; dịch giả đề xuất trong TMS |
| `style-guide-en.md` | Tiếng Anh nguồn: giọng, ICU, giới hạn độ dài, lỗi, paywall, accessibility | Đội sản phẩm |
| `style-guide-vi.md` | Tiếng Việt: xưng hô, từ địa phương, chính tả, định dạng | Đội sản phẩm |
| `style-guide-<locale>.md` | Một file cho mỗi locale cấp B (mẫu ở §6) | Dịch giả chính + người duyệt |

`glossary.csv`: UTF-8, phân cách dấu phẩy, cột `term_id,en,vi,part_of_speech,definition_en,notes,do_not_translate,es,pt-BR,ja,ko,zh-Hant,id,de,fr`.
Ô trống ở cột cấp B nghĩa là chưa dịch, không phải "giữ nguyên tiếng Anh". Giữ nguyên chỉ khi `do_not_translate = yes`.

## 2. So sánh TMS (giá tra ngày 2026-11-24)
Ước tính khối lượng (đề xuất, chưa đo): ~1.500 key, ~8.000 từ nguồn ở launch; 9 ngôn ngữ đích (vi + 8 cấp B), đội 2-5 người.
"Hosted words" của Crowdin = từ nguồn × số ngôn ngữ đích, tức ~72.000. "Hosted strings" của Weblate = chuỗi nguồn × (ngôn ngữ + 1), tức ~15.000.

| TMS | ARB / ICU | Flutter | Ảnh ngữ cảnh | Giá cho quy mô này | Nhận xét |
|---|---|---|---|---|---|
| Crowdin | ARB native, có plural; QA check ICU | SDK Flutter chính thức (OTA, cần Flutter ≥ 3.22); GitHub sync tạo PR | Có, gắn chuỗi vào ảnh | Pro $75/tháng (năm) hoặc $89/tháng; Team $450/tháng. Hạn mức hosted words của Pro **chưa xác minh**; Free còn 40K (theo tracker) | Tăng giá 16/11/2026. Mời dịch giả không giới hạn. Có chợ dịch giả/agency |
| Lokalise | ARB có tài liệu riêng | Có SDK Flutter (**chưa xác minh** phiên bản) | Có | Explorer $149, Growth $379, Advanced $1.049/tháng; không còn gói Free, trial 14 ngày | Tính theo processed words; mạnh nhưng đắt so với đội nhỏ |
| Phrase (Strings) | ARB có tài liệu riêng | Có SDK OTA (**chưa xác minh**) | Có | Software UI/UX $525/tháng (năm), 15 seat; không có gói Free | Hướng doanh nghiệp, quá cỡ cho Phase 1 |
| Tolgee | Import/export ARB; kiểu placeholder lưu ở metadata, `#` trong plural không được thay | Tích hợp Flutter đang **Alpha** | Có (upload ảnh) | Free: 30.000 hosted words, 3 seat; Translate €58, Optimise €133, Manage €373/tháng (năm). Tự host được | Mã nguồn mở, rẻ; Free không đủ cho ~72.000 từ |
| Weblate | ARB từ 4.1, check ICU; ARB không hỗ trợ trường context/flags, không tự xóa chuỗi cũ | Không có SDK, làm việc qua git | Có | Hosted 40k strings €70/tháng, 160k €114/tháng; tự host miễn phí (GPL) | Git-native, rẻ nhất; giao diện kém quen với dịch giả tự do |

Nguồn (tra 2026-11-24; bảng giá trang chính thức render bằng JS nên một số số liệu lấy từ tracker, cần xem lại khi ký):
[Crowdin pricing](https://crowdin.com/pricing) ·
[PricingSaaS: Crowdin, thay đổi 16/11/2026](https://pricingsaas.com/companies/crowdin) ·
[Crowdin ARB](https://store.crowdin.com/arb) ·
[Crowdin Flutter SDK](https://github.com/crowdin/flutter-sdk) ·
[Lokalise pricing](https://lokalise.com/pricing) ·
[Lokalise ARB](https://docs.lokalise.com/en/articles/5042246-application-resource-bundle-arb) ·
[Phrase pricing](https://phrase.com/pricing/) ·
[Phrase ARB](https://support.phrase.com/hc/en-us/articles/6111361660188) ·
[Tolgee pricing](https://tolgee.io/pricing) ·
[Tolgee Flutter ARB](https://docs.tolgee.io/platform/formats/flutter_arb) ·
[Tolgee Flutter](https://tolgee.io/apps-integrations/flutter) ·
[Weblate hosting](https://weblate.org/en/hosting/) ·
[Weblate ARB](https://docs.weblate.org/en/latest/formats/arb.html)

## 3. Đề xuất
**Crowdin Pro**, vì: ARB native kèm kiểm tra ICU; GitHub sync mở PR vào repo (ARB vẫn là nguồn, `gen-l10n` vẫn chạy ở CI);
gắn ảnh chụp từ integration test vào chuỗi (i18n-l10n.md §8.5); mời dịch giả không tính seat; nhiều dịch giả tự do đã quen dùng.
Không dùng OTA SDK ở Phase 1: chuỗi phải qua CI (ICU, placeholder, độ dài) trước khi tới người dùng.
Rủi ro: giá vừa tăng và hạn mức hosted words của Pro chưa rõ. Nếu ~72.000 từ vượt hạn mức Pro thì chuyển **Weblate hosted** (40k strings, €70/tháng).
Lokalise và Phrase đắt gấp 2-7 lần cho cùng nhu cầu; Tolgee hợp nếu muốn tự host, nhưng Flutter còn Alpha.
Cách chốt (1 tuần, trong trial 14 ngày): đẩy 50 key thật (plural, select, placeholder, giới hạn độ dài) + 10 ảnh chụp lên Crowdin và Weblate, kiểm:
1. ARB đi một vòng không mất `@description`, `placeholders`, thứ tự key (diff sạch).
2. Plural sai cú pháp hoặc thiếu `other` bị chặn. Placeholder lệch bị chặn.
3. Ảnh chụp gắn được vào key. Import được `glossary.csv`.
4. PR tự động vào nhánh `l10n/*`, CI chạy được. Chi phí ước tính cho 10 locale và help center.
TMS không nhận dữ liệu người dùng: ảnh chụp chỉ dùng dữ liệu giả (seed test), nên không cần thêm vào bảng bên thứ ba ở `security-privacy.md` §3.

## 4. Thuê dịch giả bản ngữ và LQA
Thuê (mỗi locale cấp B: 1 dịch giả + 1 người duyệt, quy trình dịch, biên tập, đọc soát):
- Nguồn: chợ dịch giả của TMS, agency cho nhiều ngôn ngữ cùng lúc, ProZ. Ưu tiên người đang sống ở thị trường đó, có kinh nghiệm UI app di động.
- Bài test có trả phí ~300 từ lấy từ ARB thật: 1 thông báo, 1 paywall, 2 chuỗi plural, 1 lỗi, 1 câu xin quyền. Chấm theo tiêu chí LQA bên dưới.
- Hợp đồng: NDA, chuyển quyền tác giả bản dịch, giá theo từ cho dịch và theo giờ cho LQA (chưa có báo giá, cần hỏi 3 nơi).
Brief gửi kèm: `glossary.csv`, `style-guide-en.md`, mẫu §6, ảnh chụp mọi màn P0, bảng giới hạn độ dài, cheat sheet ICU (`style-guide-en.md` §8),
mô tả sản phẩm 1 trang, đầu mối trả lời câu hỏi (dùng tính năng hỏi đáp/comment trong TMS), lịch giao.
Nguồn thuật ngữ nền tảng cho dịch giả: Apple Localization Glossaries (Apple Developer, mục Downloads) và Microsoft Terminology; tên mục trong Settings lấy từ máy thật.
LQA (trên build và ảnh chụp, trước cổng i18n-l10n.md §9):
- Lỗi chia nhóm: sai nghĩa, sai thuật ngữ, không tự nhiên, sai văn phong, sai quy ước locale, vỡ layout/cắt chữ. Mức: nghiêm trọng, lớn, nhỏ.
- Ngưỡng đề xuất: 0 lỗi nghiêm trọng; ≤ 2 lỗi lớn mỗi 1.000 từ (cấp A và B). Kiểm cỡ chữ 200%.
- Chuỗi sức khỏe và paywall do người duyệt đọc riêng. Privacy Policy và Terms: luật sư địa phương duyệt (i18n-l10n.md §8.8).
- Tiếng Việt: đội viết, một người duyệt ở vùng miền khác với người viết (Bắc/Trung/Nam) để bắt từ địa phương.

## 5. Glossary và style guide trong quy trình
| Bước ở i18n-l10n.md §8 | Dùng thư mục này thế nào |
|---|---|
| 2. Key + `@description` | Description ghi `term_id` khi từ có thể hiểu hai nghĩa ("check-in = trip_checkin_flight") và giới hạn độ dài theo `style-guide-en.md` §7 |
| 3. TMS | Import `glossary.csv` thành glossary của project (map cột ngôn ngữ); đính style guide của locale vào hướng dẫn project |
| 4-6. Pseudo-locale, ảnh chụp, CI | Không phụ thuộc thư mục này; CI đọc giới hạn độ dài từ description |
| 7. Style guide theo locale | `style-guide-en.md`, `style-guide-vi.md`, `style-guide-<locale>.md` |
| 8. Store, push, email, help center | Dùng chung glossary và style guide; ASO là việc riêng từng nước |
- `glossary.csv` trong repo là bản gốc, glossary trong TMS là bản sao. Thêm hoặc sửa thuật ngữ: PR sửa CSV, rồi import lại.
  Dịch giả đề xuất trong TMS; L10n lead xuất về CSV qua PR khi locale qua LQA.
- Thuật ngữ đổi sau khi đã dịch: đánh dấu các chuỗi liên quan cần dịch lại trong TMS, không sửa tay file ARB đích.

## 6. Mẫu `style-guide-<locale>.md` cho dịch giả cấp B
```markdown
# RemindMe style guide: <locale>
> TL;DR: <form of address, tone, 1-2 rules that differ most from English>
## 1. Locale facts (paste real output from the app build)
Script · plural categories (CLDR) · sample date, time, number, store price · 12/24h · week start · decimal separator
## 2. Form of address
Decision (es tú/usted, pt-BR você, de du/Sie, fr tu/vous, ja です・ます, ko 해요체/합쇼체, id Anda/kamu, zh-Hant 你/您) · reason · 3 examples
## 3. Tone: what changes compared with style-guide-en.md §2
## 4. Capitalization and punctuation
## 5. Platform terminology: source used (Apple/Google), iOS vs Android differences
## 6. Glossary decisions: term_id, chosen term, rejected options, reason
## 7. Length: expansion vs English, strings that did not fit and how they were shortened
## 8. Plurals, select, grammar notes (gender, particles, counters)
## 9. Regional variants (e.g. es-ES vs es-419, zh-TW vs zh-HK): what the base file targets
## 10. Do / don't: at least 5 pairs from the P0 flows
## 11. Open questions · sign-off (translator, reviewer, date)
```

## 7. Câu hỏi mở cho chủ dự án
1. Tên gói "Free" có giữ nguyên ở mọi locale không (glossary `plan_free`, đang đề xuất giữ).
2. Tên list mặc định "Inbox"/"Hộp thư" trùng hộp thư email: đổi thành "Chưa phân loại"? (`core_inbox`)
3. `en` chỉ một bản (chính tả Mỹ) hay thêm `en_GB`; `es` một bản trung tính hay tách `es-ES` / `es-419` ngay đợt 1.
4. Ngân sách dịch giả cấp B và chọn Crowdin hay Weblate sau trial.
