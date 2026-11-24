# Gói ngữ pháp NLU (`<lang>.yaml`)

Thiết kế và ngưỡng phát hành: `docs/architecture/voice-and-text-input.md` §5, §7. Engine (`lib/src/nlu/engine.dart`) không chứa từ của ngôn ngữ nào;
thêm ngôn ngữ = thêm 1 file gói + bộ câu `fixtures/nlu/<lang>.json`, không sửa code. Chấm: `dart run tool/nlu_eval.dart <lang>`.

## Từ vựng
| Khóa | Kiểu | Ý nghĩa |
|---|---|---|
| `lang` | chuỗi | Mã BCP 47 |
| `lunar_system` | `lunar_vi` \| `lunar_zh` \| `lunar_ko` | Bật mẫu âm lịch (`lunarMonthly`, `lunarYearly`) |
| `date_order` | `{default, regions}` | `dmy` \| `mdy` \| `ymd`; `default: null` = không biết vùng thì hỏi khi `03/04` mơ hồ |
| `fillers` | danh sách | Từ đệm bỏ ở đầu câu ("nhắc tôi", "remind me to") |
| `filler_tails` | danh sách | Từ nối còn lại sau khi bỏ giờ ("remind me at 6 **to** leave") |
| `prepositions` | danh sách | Giới từ đứng ngay trước ngày/giờ, bỏ cùng ngày/giờ ("lúc", "at") |
| `conjunctions` | danh sách | Tách nhiều việc, chỉ khi mỗi phần có thời điểm riêng |
| `list_separators` | danh sách | Dấu nối trong danh sách thứ ("2, 4 và 6") |
| `this_words` | danh sách | "này/nay/ni", "this" |
| `proper_noun_guard` | danh sách | Từ trùng tên riêng: viết hoa giữa câu thì bỏ qua ("Gọi cho **Mai**") |
| `numbers` | từ → số | Số bằng chữ (STT có thể trả "ba giờ chiều") |
| `relative_days` | từ → số ngày | 0 = hôm nay |
| `weekdays` | từ → 1..7 | ISO: 1 = thứ Hai |
| `weekday_list_tokens` | từ → 1..7 | Số trong "thứ 2,4,6" |
| `months` | từ → 1..12 | |
| `next_modifiers` | từ → `next_week` \| `next_ambiguous` | "tuần sau" chắc chắn; en "next Friday" có thể là thứ 6 tới (hỏi) |
| `day_parts` | từ → `{range: [từ, đến], default: 'HH:MM', rel?}` | Khung giờ gồm 2 đầu, `from > to` = qua nửa đêm; `rel: 0` cho từ như "tonight" |
| `meridiem` | từ → `am` \| `pm` | |
| `units` | từ → `minute` \| `hour` \| `day` \| `week` \| `fortnight` \| `month` \| `year` | |
| `table.columns` | trường → danh sách tên cột | Nhập xlsx/csv: `title`, `date`, `time`, `notes`, `priority`, `status`, `location`, `assignee`, `list` (so không dấu) |
| `table.priority` | từ → 1..3 | Giá trị cột Ưu tiên ("cao" = 3) |
| `table.done` | danh sách | Giá trị cột Trạng thái nghĩa là đã xong (`x`, `✓`, `TRUE` có sẵn trong code) |
| `document.classify` | loại → (từ → 1..3) | Phân loại tài liệu (T2): `flight`, `train`, `bus`, `hotel`, `medical`, `event`, `todo_list`; mỗi từ tính tối đa 2 lần |
| `document.anchors` | trường → danh sách nhãn | Nhãn in trên tài liệu: `confirmation_code`, `passengers`, `terminal`, `gate`, `seat`, `class`, `total`, `check_in`, `check_out`, `property`, `address` |
| `document.segments` | danh sách | Nhãn mở đầu 1 chặng ("Chuyến về", "Return") |
| `document.travel_classes` | từ → `economy` \| `premium` \| `business` \| `first` | Hạng ghế in trên vé |
| `document.passenger_units` | danh sách | Đơn vị đứng sau số khách ("2 người lớn", "2 adults") |
| `document.code_stopwords` | danh sách | Từ in hoa dễ nhầm là mã đặt chỗ ("NUMBER", "TICKET") |

## Mẫu
4 phần, chạy theo thứ tự `recurrence` → `times` → `dates` → `parts`; trong mỗi phần, mẫu đầu tiên khớp được giữ (đặt mẫu dài trước).
Mỗi mẫu: `{type, re, value?}`. `re` là regex (cú pháp Dart/JS, không phân biệt hoa thường), có chỗ giữ `{lớp}` hoặc `{lớp:nhóm}`:
`num`, `year`, `weekday`, `month`, `mon` (tên tháng hoặc số), `relday`, `daypart`, `this`, `ap`, `unit`, `next`, `ord`, `wdlist`.
Engine tự thêm ranh giới từ Unicode quanh mẫu. Dùng nháy đơn YAML để không phải escape `\`.

| `type` | Nhóm đọc | Kết quả |
|---|---|---|
| `hm` | `h`, `m?`, `ap?`, `part?`, `rel?`/`this?` | Giờ:phút |
| `half` | như `hm` | h:30 |
| `minus` | `h`, `m` | h giờ kém m ("3 giờ kém 15" = 2:45, "quarter to 4") |
| `past` | `h`, `m` | h giờ m phút ("20 past 4") |
| `fixedTime` | `value: 'HH:MM'` | "noon", "midnight" |
| `inDuration` | `n`, `u` hoặc `value` (`n`, `{n, u}`) | Từ bây giờ ("2 tiếng nữa", "in 30 minutes") |
| `relday` | `rel`, `part?` | Ngày tương đối |
| `weekday` | `w`, `next?`/`this?` | Thứ |
| `nextWeek` | | +7 ngày |
| `dayMonth` | `d`, `mo`, `y?` | Ngày/tháng (năm sau nếu đã qua) |
| `numericDate` | `a`, `b`, `y?` | Ngày số, thứ tự theo `date_order` của vùng |
| `part` | `part`, `rel?`/`this?` | Buổi, giờ mặc định của buổi nếu không có giờ |
| `daily`, `dailyPart`, `weekly`, `weekdays`, `monthly`, `yearly` | `part?`, `w?` | RRULE |
| `weeklyDays` | `list` hoặc `w` | `FREQ=WEEKLY;BYDAY=…` |
| `everyN` | `n`/`value`, `u` hoặc `w` | `INTERVAL=n` |
| `monthlyDay` | `d` | `FREQ=MONTHLY;BYMONTHDAY=d` |
| `lunarMonthly`, `lunarYearly` | `d`/`value`, `mo` | `recurrences.calendar` `{system, month?, day}` |

## Mơ hồ thì hỏi
Engine trả `ambiguities` (app hiện chip có lựa chọn): `dateOrder`, `sameWeekday`, `nextWeekday`, `meridiem` (giờ 1-11 không có buổi/am-pm;
mặc định 1-6 giờ là buổi chiều). Bẫy mới của một ngôn ngữ cần một test trong `test/nlu_test.dart`.
