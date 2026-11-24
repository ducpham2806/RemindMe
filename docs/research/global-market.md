# RemindMe: Nghiên cứu thị trường global (locale, region dữ liệu, nhóm giá), 11/2026

> TL;DR: Doanh thu app tập trung ở US (~$60B năm 2025), JP, KR, UK; tăng nhanh nhất ở DE, FR, ES, IT, BR. Lượt tải dẫn đầu là IN, US, BR, ID.
> Đợt 1 cấp B nên giữ 8 locale hiện có và **thêm `it`** (9 locale). `th`, `tr` lùi sang đợt 2, `ar` lên đợt 2, `hi` để đợt 3.
> Region Supabase chính: **`eu-central-1` (Frankfurt)**. EU, JP, KR, BR, UK chuyển dữ liệu vào EU mà không cần thêm cơ chế; độ trễ tới US ~92 ms, tới Singapore ~164 ms.
> T1/T2/T3 khớp giá TickTick ở phần lớn storefront. Cần thêm SA, AE, HK, TW vào bảng, hạ BR/TR xuống ~50% và sửa giá neo Todoist ($6,99, không phải $5).

> Persona: Product Trend Researcher (agency-agents). Dữ liệu thu thập ngày 24/11/2026. Số liệu theo category và theo quốc gia của Sensor Tower,
> AppMagic, RevenueCat phần lớn nằm sau paywall. Khi không có số liệu, tài liệu dùng proxy: tổng chi tiêu app theo quốc gia, thị phần iOS, xếp hạng top-grossing và giá local của đối thủ.
> Ký hiệu: **(ước lượng)** = suy ra/tính toán của người viết; **(chưa xác minh)** = chỉ có nguồn thứ cấp hoặc chưa kiểm tra trực tiếp.

---

## 1. Chi tiêu và lượt tải theo quốc gia

| Chỉ số | Số liệu | Nguồn |
|---|---|---|
| IAP toàn cầu 2025 (iOS + Google Play) | $167B (+10,6%); lượt tải ~150B (+0,8%) | [Sensor Tower SoM 2026](https://sensortower.com/blog/state-of-mobile-2026) |
| Chi tiêu toàn cầu 2025 theo Appfigures | $155,8B (+21,6%); US $55,5B (+18,1%) | [TechCrunch/Appfigures](https://techcrunch.com/2026/01/14/app-downloads-declined-again-in-2025-but-consumer-spending-soared-to-nearly-156b) |
| US 2025 | gần $60B, thị trường lớn nhất | [Sensor Tower SoM 2026](https://sensortower.com/blog/state-of-mobile-2026) |
| Top 5 IAP Q3/2025 | US (>$15B, +11%) > CN (chỉ iOS) > JP (-1%) > KR (+7%) > UK (+19%) | [ST Q3/2025 DMI, tr.12](https://investgame.net/wp-content/uploads/2025/11/sensor_tower__q3_2025_digital_market_index.pdf) |
| Thị trường tăng mạnh Q3/2025 | DE +21% (+$0,29B), UK +19%, FR +29%, BR +29% (nhanh nhất trong top 20) | [ST Q3/2025 DMI, tr.13](https://investgame.net/wp-content/uploads/2025/11/sensor_tower__q3_2025_digital_market_index.pdf) |
| JP | $16,5B năm 2024, hạng 3; game chiếm phần lớn; non-game Q3/2025 +13% | [Adjust/Sensor Tower](https://www.adjust.com/blog/japan-app-trends-2025/) (chưa xác minh), [ST Q3/2025](https://investgame.net/wp-content/uploads/2025/11/sensor_tower__q3_2025_digital_market_index.pdf) |
| Doanh thu 2025 theo AppMagic | Tăng nhiều nhất: ES, AE, BR, FR, IT. Giảm: KR (-6,5%), IN, HK, TW (-3,5%) | [AppMagic Landscape 2026](https://gamedevreports.substack.com/p/appmagic-mobile-market-landscape) |
| Lượt tải 2025 (AppMagic) | IN, US, BR, ID (ID +10%); VN +12% | [AppMagic Landscape 2026](https://gamedevreports.substack.com/p/appmagic-mobile-market-landscape) |
| Q2/2026 | US $14,8B (-3%); lượt tải IN 6,67B, US 3,08B, BR 2,43B | [9to5Mac/Sensor Tower](https://9to5mac.com/2026/08/11/report-non-gaming-apps-drove-mobile-spending-growth-in-q2-as-games-fell-4-5/) |
| Category Productivity 2025 (toàn cầu) | $9,1B doanh thu (6,0%, +79,3%); 6,0B lượt tải (+19,2%) | [AppTweak](https://www.apptweak.com/en/reports/app-market-size-by-app-category) |

- Mức +79% của Productivity chủ yếu đến từ chatbot AI. ChatGPT, Claude, Grok, Gemini nằm trong category Productivity trên iOS: chúng chiếm hạng 1-6 top grossing Productivity US
  ([Apple RSS US](https://itunes.apple.com/us/rss/topgrossingapplications/limit=100/genre=6007/json), 24/11/2026). Vì vậy app todo chỉ đứng hạng 50-100 ở hầu hết storefront, kể cả khi doanh thu tuyệt đối lớn.
- Chưa có số liệu công khai về doanh thu của riêng app todo/lịch theo quốc gia. Thay vào đó, mục 2 dùng xếp hạng top-grossing trong từng storefront.
  Hạng là số tương đối trong một storefront, nên không so được giữa các nước.

## 2. Hồ sơ từng thị trường

iOS % = thị phần lượt xem web trên mobile, tháng 10/2026 ([StatCounter](https://gs.statcounter.com/os-market-share/mobile/)). Số này không phải installed base. App: G = hạng top-grossing, F = hạng top-free,
category Productivity, iPhone, top 100, ngày 24/11/2026 ([Apple RSS](https://itunes.apple.com/us/rss/topgrossingapplications/limit=100/genre=6007/json), đổi mã nước). Tài liệu du lịch: xem mục 3.

| TT | iOS % | Tín hiệu chi tiêu | App todo/lịch mạnh (Productivity) | Tài liệu du lịch có cấu trúc | Nhóm giá |
|---|---|---|---|---|---|
| US | 52 | #1, ~$60B/2025 | Todoist G93; Google Calendar F19, Google Tasks F89; TripIt G18, Tripsy G20 (Travel) | BCBP, Gmail JSON-LD, pkpass; Amtrak có extractor | T1 |
| UK | 50 | top 5, +19% | Todoist G80; MS To Do F90, TickTick F97 | BCBP; National Rail, Trainline có extractor | T1 |
| CA | 65 | (chưa có số riêng) | Todoist G69, TickTick G87; MS To Do F95 | BCBP; VIA Rail, Air Canada | T1 |
| AU | 62 | (chưa có số riêng) | Todoist G84; TripIt G4 (Travel) | BCBP | T1 |
| DE | 28 | +21% | Todoist G55, TimeTree G58, Structured G76, TickTick G91; MS To Do F74 | UIC 918.3/918.9, VDV (DB) | T1 |
| FR | 36 | +29% | Notion G48, Todoist G67, TickTick G100 | Barcode riêng của SNCF + UIC | T1 |
| ES | 27 | tăng mạnh nhất (AppMagic) | TickTick G83, Todoist G91 | Renfe, Iberia, Vueling có extractor | T1 (EU) |
| IT | 38 | top 5 tăng trưởng (AppMagic) | Notion G50, Calendars G65, Todoist G94 | Barcode riêng của Trenitalia; Italo | T1 (EU) |
| MX | 26 | (chưa có số riêng) | Tiimo G94; không có Todoist/TickTick trong top 100 | Gần như không có extractor LATAM | T2 |
| BR | 26 | +29%, lượt tải #3 | App đặt lịch chuyên nghiệp G14/G32/G70; TickTick G65, Todoist G88 | Không có extractor LATAM (định dạng Gol/Azul/LATAM: chưa xác minh) | T2 |
| JP | 54 | #3; non-game +13% | **TimeTree G25**, **Lifebear G32**, TickTick G63, Jorte G92; LINE Calendar F10 | eki-net (JR East), Kintetsu, ANA, Peach, Skymark | T1 |
| KR | 39 | #4 nhưng -6,5% (2025) | **App nội địa**: TimeBlocks G17, AnySchedule G21, 플래닛 G43, 할일차곡 G46; TickTick G44 | Korail | T1 |
| TW | 52 | -3,5% (2025) | TimeTree G29, TickTick G66, Todoist G73, Jorte G88 | THSR | chưa xếp |
| HK | 46 | giảm (2025) | TimeTree G45, Todoist G92 | BCBP | chưa xếp |
| ID | 21 | lượt tải #4 (+10%) | Todoist G86, Superlist G94 | AirAsia, Agoda, 12go; KAI (chưa xác minh) | T3 |
| TH | 24 | (chưa có số riêng) | **AMA lịch cát tường G29**, TickTick G98 | Thailand Railway | T2 |
| VN | 38 | lượt tải +12% | Notion G36, CalendarDC G82; Âm Lịch Việt F83 | Vietjet; xem `competitor-analysis.md` | T3 |
| IN | 5 | lượt tải #1; doanh thu giảm 2025 | TickTick G48, Todoist G57 | IRCTC, IndiGo, Vistara | T3 |
| PH | 14 | (chưa có số riêng) | TickTick G66, Structured G95 | BCBP; Cebu Pacific (chưa xác minh) | T3 |
| MY | 37 | (chưa có số riêng) | Todoist G73, TickTick G95 | KTMB, AirAsia | T2 |
| TR | 23 | (chưa có số riêng) | TickTick G68 | TCDD | T2 |
| SA | 42 | tăng nhanh (AppMagic) | **Hilal Calendar (Hijri) G28**, TickTick G98 | BCBP; định dạng nội địa (chưa xác minh) | chưa xếp |
| AE | 19 (nghi ngờ) | tăng nhanh (AppMagic) | Notion G45; không có app todo | BCBP | chưa xếp |

Nhận xét:
- **Microsoft To Do vẫn nằm trong top-free ở GB, CA, AU, DE** (F74-F95), dù app sẽ ngừng ngày 30/06/2027 (`competitor-analysis.md` §1). Vì vậy kênh "chuyển nhà" từ MS To Do nên nhắm `en` và `de` trước.
- **JP, KR, TW có app lịch/planner nội địa đứng trên Todoist/TickTick.** TimeTree có 70 triệu người dùng đăng ký (11/2025) ([Barchart](https://www.barchart.com/story/news/163999/timetree-launches-new-home-calendar-focused-on-my-time-amid-major-uiux-overhaul)).
  Ở KR, 4/5 app todo có doanh thu cao nhất là app nội địa. Vào các thị trường này cần lợi thế khác biệt (đọc vé, âm lịch); dịch UI thôi thì không đủ.
- **Nhu cầu nhắc theo hệ lịch phi Gregorian có trả tiền**: Hilal Calendar (Hijri) G28 ở SA, AMA (lịch cát tường) G29 ở TH, nhiều app âm lịch ở VN/TW. Tính năng recurrence âm lịch/Hijri của RemindMe khớp với các thị trường này.
- **Android chiếm ≥ 72% ở DE, ES, MX, BR, ID, TH, TR, IN, PH** ([StatCounter](https://gs.statcounter.com/os-market-share/mobile/)). Import ảnh/PDF của đối thủ du lịch hầu như chỉ có trên iOS (`competitor-analysis.md` §1), nên khoảng trống Android rộng nhất ở các thị trường này.
- RevenueCat ghi nhận tỉ lệ chuyển đổi trial cao nhất ở Bắc Mỹ và APAC; LATAM và MEA biến động hơn ([RevenueCat SOSA](https://www.revenuecat.com/state-of-subscription-apps-2025)) (chưa xác minh, chỉ có bản preview).

## 3. Dữ liệu có cấu trúc trong tài liệu du lịch

| Định dạng | Phạm vi | Thị trường | Ý nghĩa cho RemindMe |
|---|---|---|---|
| IATA BCBP (Res. 792) trên thẻ lên máy bay | 100% hãng IATA từ 2010 ([IATA](https://www.iata.org/en/pressroom/pressroom-archive/2010-press-releases/2010-12-15-01/)) | Toàn cầu | Đọc barcode cho ra PNR, chặng, ngày, ghế trên mọi thị trường. Nên là luồng P0 cho máy bay |
| Gmail markup `FlightReservation` (JSON-LD/Microdata) | Schema của Google, nhà cung cấp tự thêm vào email ([Google](https://developers.google.com/workspace/gmail/markup/reference/flight-reservation)) | Hãng/OTA lớn (tỉ lệ có markup theo nước: chưa xác minh) | Email forward có JSON-LD thì parse trực tiếp, không cần mẫu |
| Apple Wallet `.pkpass` / Google Wallet | Phổ biến ở hãng bay và đường sắt lớn (KItinerary có extractor pkpass cho Lufthansa, Eurowings, SAS) | US/EU/JP (chưa xác minh tỉ lệ) | Bên trong là JSON, đọc được trên máy |
| UIC 918.3 / IRS 90918-9 (FCB, Aztec), TAP TSI B.12 | Tiêu chuẩn vé tàu EU ([ERA TD B.12](https://www.era.europa.eu/system/files/2023-10/ERA-OPI-2023-4%20-%20ERA_Technical_Document_TAP_B_12.pdf)) | DE, AT, CH, EU liên quốc gia | Dùng một decoder cho nhiều hãng; DB đang chuyển sang 918.9 |
| VDV-KA; barcode riêng SNCF, SBB, Trenitalia | Không theo chuẩn chung ([KDE](https://community.kde.org/KDE_PIM/KItinerary/Barcode_Formats)) | DE (vé địa phương), FR, CH, IT | Mỗi hãng cần một mẫu riêng |
| Email/PDF nội địa châu Á | KItinerary có 253 extractor, phần lớn cho châu Âu. Châu Á có eki-net, kintetsu, korail, taiwan-high-speed-rail, thailand-railway, ktmb, irctc, vietjetair, airasia, agoda ([KItinerary](https://invent.kde.org/pim/kitinerary/-/tree/master/src/lib/scripts)) | JP, KR, TW, TH, MY, IN, VN | Có tham chiếu mã mở (LGPL) để học định dạng; cần mẫu riêng cho từng nước |
| LATAM (Gol, Azul, LATAM, Aeroméxico, ADO, bus BR) | Không có extractor mở nào trong KItinerary | BR, MX | Với BR/MX, chỉ BCBP dùng được ngay. Mẫu email cần tự thu mẫu (V4 trong `STATE.md`) |

## 4. Đề xuất locale (cấp B đợt 1 và thứ tự các đợt sau)

| Locale | Quyết định | Lý do (dữ liệu) |
|---|---|---|
| `es` | Giữ đợt 1 | ES tăng doanh thu mạnh nhất 2025 (AppMagic); MX/LATAM Android ~74%; TickTick G83, Todoist G91 ở ES |
| `pt-BR` | Giữ; ưu tiên số 1 khi nâng lên cấp A | BR +29%, lượt tải #3, Android 74%; TickTick/Todoist có trong top-grossing; không có extractor mở, nên tự làm mẫu sẽ tạo lợi thế |
| `ja` | Giữ | JP là thị trường #3; iOS 54%; TickTick G63. TimeTree/Lifebear mạnh, nên cần mẫu eki-net/JR sớm |
| `ko` | Giữ, hạ kỳ vọng doanh thu | KR #4 nhưng -6,5% năm 2025; app planner nội địa thống lĩnh |
| `de` | Giữ | DE +21%; Todoist G55; MS To Do F74; tiêu chuẩn UIC/VDV giúp đọc vé tàu dễ |
| `fr` | Giữ | FR +29%; Notion G48, Todoist G67 |
| `zh-Hant` | **Giữ** (không bỏ) | TW/HK có iOS 46-52%; TimeTree, TickTick, Todoist đều trong top-grossing; nhắc âm lịch (農曆) là lợi thế khác biệt; giá đối thủ ở HK ≈ US |
| `id` | Giữ; KPI chính là lượt tải, không phải doanh thu | Lượt tải #4 (+10%), Android 79%, có nhu cầu Hijri; chỉ Todoist G86 trong top-grossing, ARPU thấp (ước lượng) |
| `it` | **Thêm vào đợt 1** | IT nằm trong top 5 tăng doanh thu (AppMagic); giá T1/EU; chữ Latin nên NLU rẻ; Trenitalia/Italo có extractor tham chiếu |
| `tr` | Đợt 2 | TickTick G68 cho thấy có người trả tiền, nhưng lira biến động nên giá phải chỉnh liên tục; TickTick TR chỉ ~51% giá US |
| `th` | Đợt 2 | Nhu cầu lịch cát tường (AMA G29). ML Kit v2 không đọc được chữ Thái ([ML Kit](https://developers.google.com/ml-kit/vision/text-recognition/v2/languages)), nên OCR trên Android chưa có |
| `hi` | Đợt 3 (hoặc cấp C) | iOS 5%, doanh thu IN giảm 2025; người dùng IN trả tiền phần lớn dùng `en` (đã ở cấp A). Devanagari có trong ML Kit nên thêm sau không tốn nhiều |

**Cấp B đợt 1 (9 locale):** `es`, `pt-BR`, `ja`, `ko`, `de`, `fr`, `zh-Hant`, `id`, `it`.
**Cấp B đợt 2 (+3 tháng), theo thứ tự:** `tr`, `th`, `zh-Hans` (SG/MY), `ar` (SA/AE; RTL, lên từ đợt 3 nếu QA giao diện gương đạt), `nl`, `pl`, `ms`. `fil` chuyển sang C vì PH dùng `en`.
**Cấp B đợt 3:** `he`, `hi`, `ru`, `uk`.
**Cấp A:** đợt 2 giữ `pt-BR` trước `es`. Đợt 3 theo doanh thu: `ja`, `de`, `fr`, `ko`, `it`. `id` chỉ nâng khi doanh thu ID đạt ngưỡng (ước lượng, chủ dự án đặt ngưỡng).

## 5. Region Supabase chính

Region hiện có ([Supabase docs](https://supabase.com/docs/guides/platform/regions)): `us-west-1`, `us-west-2`, `us-east-1`, `us-east-2`, `ca-central-1`, `eu-west-1`, `eu-west-2`, `eu-west-3`, `eu-central-1`,
`eu-central-2`, `eu-north-1`, `ap-south-1`, `ap-southeast-1`, `ap-northeast-1`, `ap-northeast-2`, `ap-southeast-2`, `sa-east-1` (17 region). **Không đổi được region sau khi tạo project.**

| Phương án | RTT tới us-east-1 / eu-central-1 / ap-southeast-1 / ap-northeast-1 ([CloudPing](https://www.cloudping.co/)) | Chuyển dữ liệu vào region |
|---|---|---|
| `us-east-1` (Virginia) | 0 / 92 / 223 / 149 ms | EU, UK, BR: cần SCC. JP: cần đồng ý hoặc biện pháp tương đương. KR: phải công bố/xin đồng ý. Supabase dùng SCC, không thấy trong DPF (chưa xác minh) |
| **`eu-central-1` (Frankfurt)** | 92 / 0 / 164 / 228 ms; tới `sa-east-1` 203 ms | EU: trong khối. JP: PPC công nhận EEA tương đương từ 2019 ([Orrick](https://www.orrick.com/en/Insights/2019/03/Worlds-Largest-Area-of-Safe-Data-Flow-Created-by-Japan-and-the-European-Union)). KR: PIPC công nhận EU tương đương 16/09/2025 ([DPA](https://digitalpolicyalert.org/event/24576-announced-equivalence-recognition-for-personal-data-transfers-between-south-korea-and-the-eu)). BR: EU-Brazil adequacy hai chiều 26-27/01/2026 ([White & Case](https://www.whitecase.com/insight-alert/mutual-adequacy-between-eu-and-brazil-new-era-transatlantic-data-transfers)). UK: UK coi EEA là adequate (chưa xác minh trong phiên). US: luật liên bang không hạn chế chuyển ra nước ngoài |
| `eu-west-1` (Ireland) | 68 / (chưa đo) / 172 / 203 ms | Giống Frankfurt. Google Cloud không có region ở Ireland, nên worker Cloud Run phải đặt ở London/Belgium (ước lượng thêm 10-20 ms) |
| `ap-southeast-1` (Singapore) | 223 / 164 / 0 / 70 ms; tới Mumbai 64 ms | Gần VN/ID/TH/PH/MY, nhóm nhiều lượt tải nhưng ARPU thấp. EU/UK/JP/KR/BR sang SG đều cần SCC hoặc đồng ý |

**Đề xuất: `eu-central-1` (Frankfurt)**, worker Cloud Run đặt ở `europe-west3` (cùng Frankfurt).
- App offline-first nên RTT 92-228 ms chỉ ảnh hưởng tốc độ sync nền, không ảnh hưởng UX (ADR-003). Tiêu chí ADR-011 hiện tại là "nơi có nhiều người dùng trả phí nhất" (sẽ là US). Tiêu chí này nên đổi thành "region giảm nhiều nhất thủ tục chuyển dữ liệu".
  Frankfurt bao được EU + UK + JP + KR + BR, tức phần lớn doanh thu ngoài US, và với US cũng không phát sinh nghĩa vụ chuyển dữ liệu.
- DPF giữa EU và US vẫn còn hiệu lực sau phán quyết Latombe (03/09/2025), nhưng có thể bị kháng cáo ([IAPP](https://iapp.org/news/a/european-general-court-dismisses-latombe-challenge-upholds-eu-us-data-privacy-framework)). Đặt region tại EU giúp RemindMe không phụ thuộc vào DPF.
- Region nào cũng còn một số luồng chuyển dữ liệu: bên xử lý chính của Supabase là Supabase Pte. Ltd. (Singapore), và hỗ trợ/vận hành chạy qua Singapore và US theo SCC trong DPA ([Supabase FAQ](https://supabase.com/legal/privacy-resources/data-residency-and-transfers-faq)).
  Vì vậy ADR-011 vẫn phải nêu SCC/DPA.
- VN: Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 có hiệu lực từ 01/01/2026. Chuyển dữ liệu ra bất kỳ nước nào đều phải lập hồ sơ đánh giá tác động chuyển dữ liệu ra nước ngoài và nộp cho Bộ Công an trong 60 ngày
  ([FPF](https://fpf.org/wp-content/uploads/2026/01/January-2026-FPF-Issue-Brief-Making-Sense-of-Vietnams-Latest-Data-Protection-and-Governance-Regime-1.pdf), [EY, NĐ 356/2025](https://www.ey.com/en_vn/technical/tax/tax-and-law-updates/legal-alert-march-2026-decree-no-356-2025-nd-cp-providing-detailed-guidance-for-implementation-of-personal-data-protection-law)) (chưa xác minh trên văn bản gốc).
  Nghĩa vụ này không phụ thuộc region đã chọn. ID và IN cũng cần đánh giá riêng (ngoài phạm vi tài liệu này).

## 6. Kiểm tra nhóm giá T1/T2/T3

Giá in-app trên App Store từng storefront, ngày 24/11/2026 ([Todoist](https://apps.apple.com/us/app/id572688855), [TickTick](https://apps.apple.com/us/app/id626144601); đổi mã nước trong URL).
Quy đổi theo tỷ giá ngày 24/11/2026 ([open.er-api](https://open.er-api.com/v6/latest/USD)) (ước lượng). % = so với giá US. Giá ở EU/UK/JP/KR/AU đã gồm VAT/GST; giá US chưa gồm thuế.

| Storefront | Todoist tháng / năm | ≈ USD (% US) | TickTick tháng / năm | ≈ USD (% US) | RemindMe |
|---|---|---|---|---|---|
| US | $6,99 / $59,99 | 100% | $4,99 / $49,99 | 100% | T1 |
| GB | £6,99 / £59,99 | $9,12 / $78,25 (130%) | £4,99 / £49,99 | $6,51 / $65,20 (130%) | T1 |
| DE, FR, ES | €6,99 / €59,99 | $7,63 / $65,52 (109%) | €4,99 (có cả €5,99) / €49,99 | $5,45 / $54,60 (109%) | T1 |
| JP | ¥890 / ¥8.080 | $5,60 / $50,80 (80-85%) | ¥800 / ¥8.000 | $5,03 / $50,29 (101%) | T1 |
| KR | ₩9.900 / ₩88.000 | $7,37 / $65,50 (105-109%) | ₩7.700 / ₩77.000 | $5,73 / $57,31 (115%) | T1 |
| AU | A$11,99 / A$107,99 | $7,95 / $71,57 (114-119%) | A$7,99 / A$79,99 | $5,30 / $53,01 (106%) | T1 |
| CA | C$9,99 / C$84 | $6,96 / $58,50 (~100%) | C$6,99 / C$69,99 | $4,87 / $48,74 (~98%) | T1 |
| SA | SAR 29,99 / 249,99 | $8,00 / $66,66 (111-114%) | SAR 19,99 / 199,99 | $5,33 / $53,33 (107%) | chưa xếp |
| HK | HK$58 / HK$488 | $7,40 / $62,23 (104-106%) | HK$38 / HK$388 | $4,85 / $49,48 (97-99%) | chưa xếp |
| TW | NT$220 / NT$1.990 | $6,70 / $60,59 (96-101%) | NT$90 / NT$870 | $2,74 / $26,49 (53-55%) | chưa xếp |
| MX | MX$79 / MX$799 | $4,12 / $41,65 (59-69%) | MX$69 / MX$659 | $3,60 / $34,35 (69-72%) | T2 |
| TH | ฿249 / ฿1.990 | $7,32 / $58,53 (98-105%) | ฿109 / ฿1.000 | $3,21 / $29,41 (59-64%) | T2 |
| TR | ₺249,99 / ₺1.999 | $4,94 / $39,49 (66-71%) | ₺129,99 / ₺1.199,99 | $2,57 / $23,71 (47-51%) | T2 |
| BR | R$24,90 / R$199,90 | $4,18 / $33,55 (56-60%) | R$14,90 / R$137,90 | $2,50 / $23,14 (46-50%) | T2 |
| ID | Rp119k / Rp999k | $6,54 / $54,90 (92-94%) | Rp49k / Rp439k | $2,69 / $24,13 (48-54%) | T3 |
| IN | ₹330 / ₹3.149 | $3,55 / $33,86 (51-56%) | ₹269 / ₹2.599 | $2,89 / $27,95 (56-58%) | T3 |
| VN | 199.000đ / 1.999.000đ | $7,71 / $77,48 (110-129%) | 69.000đ / 639.000đ | $2,67 / $24,77 (50-54%) | T3 |

Kết luận:
- **T1 ($4,99 / $39,99) hợp lý:** gói tháng bằng TickTick, gói năm rẻ hơn TickTick 20% và Todoist 33%. Ở EU/UK, giá tự quy đổi của Apple cho $4,99 có thể là €5,99 (TickTick có cả hai mức)
  (chưa xác minh). Nên ghi đè thành €4,99 / £4,99 để ngang đối thủ.
- **T2 (~60%)**: khớp MX (TickTick 69-72%) và TH (59-64%). BR và TR thấp hơn (TickTick 46-51%), nên đặt ~50%. TR cần xem lại giá mỗi quý: Apple không tự cập nhật giá auto-renewable subscription theo tỷ giá
  ([Apple](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions)).
- **T3 (35-45%)**: TickTick ở IN/ID/VN ở mức 48-58%, nên RemindMe ở mức 45% vẫn rẻ hơn đối thủ. Giá VN đã chốt (59.000đ ≈ 46%, 449.000đ ≈ 44%; ước lượng) nằm trong khoảng này.
  Todoist gần như không giảm giá ở SEA (ID 92-94%, VN 110-129%). Đây là một điểm RemindMe có thể cạnh tranh về giá.
- **Bổ sung storefront chưa xếp nhóm:** SA, AE, HK → T1 (đối thủ bán ≈ 100% giá US). TW → T1, chạy thử T2 (TickTick TW 53-55%). IT, ES ghi rõ thuộc nhóm EU/T1.
- Thu nhập: VN và PH được World Bank nâng lên nhóm trung bình cao (7/2026) ([UDLAP](https://observatorioglobal.udlap.mx/who-moves-up-and-why-a-closer-look-at-the-2026-2027-release-of-the-world-bank-group-country-income-classifications/)) (chưa xác minh trên danh sách WB).
  Nhãn "T3 sức mua thấp" nên đổi thành "T3 giá thấp" và giữ nguyên giá đã chốt.

## 7. Rủi ro và việc cần xác minh

| Việc | Cách xác minh | Ảnh hưởng |
|---|---|---|
| Doanh thu Productivity/todo theo nước | Mua 1 tháng Sensor Tower/AppMagic hoặc dùng bản dùng thử Appfigures | Xếp lại thứ tự `ko`/`zh-Hant`/`id` |
| Xếp hạng ở mục 2 chỉ là ảnh chụp 1 ngày, chỉ iPhone | Lặp lại script RSS mỗi tuần trong 4 tuần; thêm Google Play (không có RSS chính thức) | Độ tin cậy của mục 2 |
| Chữ Thái/Ả Rập trên Apple Vision | Gọi `supportedRecognitionLanguages` trên iOS 18+ (đã có trong STATE) | Thời điểm thêm `th`, `ar` |
| Tỉ lệ email có JSON-LD theo nước | Đếm trong bộ ≥ 300 mẫu tài liệu (STATE, mục 4) | Ưu tiên mẫu nhà cung cấp |
| UK→EEA, Supabase trong DPF, NĐ 356/2025 | Luật sư hoặc DPO đọc văn bản gốc | Nội dung ADR-011 |

## 8. Nguồn (truy cập 24/11/2026)

- Sensor Tower, State of Mobile 2026: https://sensortower.com/blog/state-of-mobile-2026
- Sensor Tower, Q3 2025 Digital Market Index (PDF, tr.12-15): https://investgame.net/wp-content/uploads/2025/11/sensor_tower__q3_2025_digital_market_index.pdf
- 9to5Mac (Sensor Tower Q2/2026): https://9to5mac.com/2026/08/11/report-non-gaming-apps-drove-mobile-spending-growth-in-q2-as-games-fell-4-5/
- AppMagic Mobile Market Landscape 2026 (tóm tắt): https://gamedevreports.substack.com/p/appmagic-mobile-market-landscape
- Appfigures qua TechCrunch: https://techcrunch.com/2026/01/14/app-downloads-declined-again-in-2025-but-consumer-spending-soared-to-nearly-156b
- AppTweak, app market size by category 2025: https://www.apptweak.com/en/reports/app-market-size-by-app-category
- Adjust, Japan app trends 2025: https://www.adjust.com/blog/japan-app-trends-2025/
- StatCounter, mobile OS theo quốc gia (CSV, 10/2026): https://gs.statcounter.com/os-market-share/mobile/
- Apple iTunes RSS top-grossing/top-free, genre 6007 (Productivity) và 6003 (Travel): https://itunes.apple.com/us/rss/topgrossingapplications/limit=100/genre=6007/json
- App Store: Todoist https://apps.apple.com/us/app/id572688855, TickTick https://apps.apple.com/us/app/id626144601
- Todoist, giá Pro từ 10/12/2025: https://www.todoist.com/help/articles/todoist-pro-pricing-update-in-2025-bxBvHZuJZ
- Tỷ giá: https://open.er-api.com/v6/latest/USD
- RevenueCat, State of Subscription Apps 2025: https://www.revenuecat.com/state-of-subscription-apps-2025
- TimeTree 70 triệu người dùng: https://www.barchart.com/story/news/163999/timetree-launches-new-home-calendar-focused-on-my-time-amid-major-uiux-overhaul
- IATA, BCBP 100% (2010): https://www.iata.org/en/pressroom/pressroom-archive/2010-press-releases/2010-12-15-01/
- Google, Gmail markup FlightReservation: https://developers.google.com/workspace/gmail/markup/reference/flight-reservation
- ERA, TAP TSI TD B.12: https://www.era.europa.eu/system/files/2023-10/ERA-OPI-2023-4%20-%20ERA_Technical_Document_TAP_B_12.pdf
- KDE KItinerary: https://community.kde.org/KDE_PIM/KItinerary/Barcode_Formats ; https://invent.kde.org/pim/kitinerary/-/tree/master/src/lib/scripts
- ML Kit Text Recognition v2, ngôn ngữ: https://developers.google.com/ml-kit/vision/text-recognition/v2/languages
- Supabase regions: https://supabase.com/docs/guides/platform/regions ; Data residency FAQ: https://supabase.com/legal/privacy-resources/data-residency-and-transfers-faq
- CloudPing (độ trễ giữa các region AWS): https://www.cloudping.co/
- IAPP, Latombe v Commission: https://iapp.org/news/a/european-general-court-dismisses-latombe-challenge-upholds-eu-us-data-privacy-framework
- Orrick, Japan-EU mutual adequacy: https://www.orrick.com/en/Insights/2019/03/Worlds-Largest-Area-of-Safe-Data-Flow-Created-by-Japan-and-the-European-Union
- Digital Policy Alert, KR-EU equivalence: https://digitalpolicyalert.org/event/24576-announced-equivalence-recognition-for-personal-data-transfers-between-south-korea-and-the-eu
- White & Case, EU-Brazil adequacy: https://www.whitecase.com/insight-alert/mutual-adequacy-between-eu-and-brazil-new-era-transatlantic-data-transfers
- FPF và EY, PDPL Việt Nam: https://fpf.org/wp-content/uploads/2026/01/January-2026-FPF-Issue-Brief-Making-Sense-of-Vietnams-Latest-Data-Protection-and-Governance-Regime-1.pdf ;
  https://www.ey.com/en_vn/technical/tax/tax-and-law-updates/legal-alert-march-2026-decree-no-356-2025-nd-cp-providing-detailed-guidance-for-implementation-of-personal-data-protection-law
- Apple, giá auto-renewable subscription: https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions
- World Bank reclassification 7/2026 (thứ cấp): https://observatorioglobal.udlap.mx/who-moves-up-and-why-a-closer-look-at-the-2026-2027-release-of-the-world-bank-group-country-income-classifications/

## 9. Đề xuất cập nhật docs (chưa sửa; chủ dự án duyệt)

1. `docs/architecture/i18n-l10n.md` dòng 18 (hàng A): đợt 3 đổi thành `ja`, `de`, `fr`, `ko`, `it`; `id` chỉ nâng khi đạt ngưỡng doanh thu.
2. `i18n-l10n.md` dòng 19 (hàng B): đợt 1 thêm `it`. Đợt 2 đổi thành `tr`, `th`, `zh-Hans`, `ar` (RTL, có điều kiện QA), `nl`, `pl`, `ms`. Đợt 3 đổi thành `he`, `hi`, `ru`, `uk`. Bỏ `fil` (chuyển sang C).
3. `i18n-l10n.md` dòng 21-22: thay câu "Cần xác minh bằng dữ liệu doanh thu theo quốc gia" bằng link tới `research/global-market.md` §4. Thêm ý: `th` chờ OCR chữ Thái (ML Kit v2 không hỗ trợ).
4. `i18n-l10n.md` dòng 23: "RTL (`ar`, `he`) để đợt 3" đổi thành "`ar` đợt 2 nếu qua QA giao diện gương, `he` đợt 3".
5. `docs/architecture/decisions.md` dòng 134 (ADR-011): thay "chọn theo nơi có nhiều người dùng trả phí dự kiến nhất (chốt sau...)" bằng "**`eu-central-1` (Frankfurt)**, worker Cloud Run
   `europe-west3`; lý do: EU/UK/JP/KR/BR chuyển vào EU không cần cơ chế thêm, không phụ thuộc DPF".
6. `decisions.md` dòng 135-136: giữ SCC/DPA (Supabase Pte. Ltd. Singapore vẫn xử lý hỗ trợ). Thêm "VN/ID/IN: hồ sơ chuyển dữ liệu ra nước ngoài theo luật nước sở tại, độc lập với region".
   Đổi "tách project EU" thành "tách project theo yêu cầu data residency (VD: US doanh nghiệp, VN)".
7. `docs/product/pricing-entitlements.md` dòng 11 (T1): thêm SA, AE, HK, TW (TW chạy thử T2) và ghi rõ IT, ES. Thêm ghi chú: EU/UK ghi đè €4,99 / £4,99.
8. `pricing-entitlements.md` dòng 12 (T2): ghi BR, TR ~50% T1, các nước còn lại ~60%. Dòng 13: đổi nhãn thành "T3 giá thấp", khoảng 40-45%.
9. `pricing-entitlements.md` dòng 15: thêm "Apple không tự cập nhật giá auto-renewable theo tỷ giá; rà lại TR, AR, BR mỗi quý".
   Dòng 17: "Todoist $5/tháng" sửa thành "Todoist $6,99/$59,99, TickTick $4,99/$49,99 (App Store US, 24/11/2026)".
10. Ngoài phạm vi được giao: `research/competitor-analysis.md` dòng 30 ghi TickTick US "chỉ có gói năm". App Store US hiện liệt kê thêm gói Monthly $4,99.
