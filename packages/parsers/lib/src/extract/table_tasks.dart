import 'package:remindme_core/remindme_core.dart';

import '../decoders/table.dart';
import '../nlu/engine.dart';
import '../nlu/pack.dart';
import '../nlu/result.dart';
import 'candidate.dart';

/// Trường của 1 cột (on-device-extraction.md §6). `assignee` chỉ để nhận ra cột, không nhập.
enum TableField { title, date, time, notes, priority, status, location, assignee, list }

/// Cách hiểu 1 bảng: dòng tiêu đề, cột nào là trường nào, gói ngôn ngữ khớp, thứ tự ngày.
/// Màn xem trước cho người dùng đổi [columns] rồi gọi lại [TableTaskExtractor.extract] (lưu theo hash header: §4.5).
class TableMapping {
  const TableMapping({
    required this.headerRow,
    required this.columns,
    required this.lang,
    required this.dateOrder,
    required this.dateOrderAmbiguous,
  });

  /// null = bảng không có dòng tiêu đề (cột suy theo kiểu dữ liệu).
  final int? headerRow;
  final Map<TableField, int> columns;
  /// Gói khớp nhiều tên cột nhất (null nếu không có header).
  final String? lang;
  /// 'dmy' | 'mdy' | 'ymd'.
  final String dateOrder;
  /// Mọi ngày dạng số trong bảng đều đọc được theo cả 2 thứ tự và vùng không cho biết: màn xem trước phải hỏi.
  final bool dateOrderAmbiguous;

  TableMapping copyWith({Map<TableField, int>? columns, String? dateOrder, int? Function()? headerRow}) => TableMapping(
        headerRow: headerRow == null ? this.headerRow : headerRow(),
        columns: columns ?? this.columns,
        lang: lang,
        dateOrder: dateOrder ?? this.dateOrder,
        dateOrderAmbiguous: dateOrder == null && dateOrderAmbiguous,
      );

  /// Phần người dùng chọn được (cột, thứ tự ngày, có dòng tiêu đề) để nhớ theo [TableTaskExtractor.signature] (§4.5).
  Map<String, Object?> toJson() => {
        'columns': {for (final e in columns.entries) e.key.name: e.value},
        'date_order': dateOrder,
        'has_header': headerRow != null,
      };

  /// Áp cách ghép đã nhớ lên kết quả dò; JSON hỏng hoặc trỏ ra ngoài bảng thì giữ nguyên [detected].
  static TableMapping applySaved(TableMapping detected, Map<String, Object?> json, {required int columnCount}) {
    final cols = <TableField, int>{};
    final raw = json['columns'];
    if (raw is! Map) return detected;
    for (final e in raw.entries) {
      final f = TableField.values.where((f) => f.name == e.key).firstOrNull;
      final c = e.value;
      if (f == null || c is! int || c < 0 || c >= columnCount) return detected;
      cols[f] = c;
    }
    if (!cols.containsKey(TableField.title)) return detected;
    final order = json['date_order'];
    return detected.copyWith(
      columns: cols,
      dateOrder: order is String && const {'dmy', 'mdy', 'ymd'}.contains(order) ? order : null,
      headerRow: json['has_header'] == false ? () => null : null,
    );
  }

  @override
  String toString() => 'TableMapping(header: $headerRow, $columns, lang: $lang, $dateOrder${dateOrderAmbiguous ? '?' : ''})';
}

/// Bảng → danh sách việc. Không phụ thuộc ngôn ngữ: tên cột, giá trị ưu tiên/trạng thái nằm trong gói (`table:` của `<lang>.yaml`).
class TableTaskExtractor {
  TableTaskExtractor(this.packs, {this.region, this.nlu});

  /// Mọi gói cấp A/B đang có; gói khớp nhiều tên cột nhất được chọn.
  final List<GrammarPack> packs;
  /// Vùng của người dùng (ISO 3166-1) để chọn thứ tự ngày khi bảng không tự cho biết.
  final String? region;
  /// Đọc ô ngày dạng chữ ("thứ 6 tuần sau") và tên việc có thời điểm khi bảng không có cột ngày.
  final NluEngine? nlu;

  static const _headerScan = 10;
  static const _sampleRows = 20;
  static const _universalDone = {'x', '✓', '✔', '☑', '✅', 'true', '1', '100%'};

  TableMapping detect(TableSheet sheet) {
    ({int row, Map<TableField, int> cols, GrammarPack pack, int score})? best;
    for (final pack in packs) {
      if (pack.tableColumns.isEmpty) continue;
      for (var r = 0; r < sheet.rows.length && r < _headerScan; r++) {
        final (cols, score) = _matchHeader(sheet.rows[r], pack);
        if (best == null || score > best.score) best = (row: r, cols: cols, pack: pack, score: score);
      }
    }
    final width = sheet.columnCount;
    final hasHeader = best != null && best.cols.containsKey(TableField.title) && (best.cols.length >= 2 || width == 1);
    final columns = hasHeader ? best.cols : _inferColumns(sheet);
    final firstData = hasHeader ? best.row + 1 : 0;
    final (order, ambiguous) = _dateOrder(sheet, columns, firstData, hasHeader ? best.pack : packs.first);
    return TableMapping(
      headerRow: hasHeader ? best.row : null,
      columns: columns,
      lang: hasHeader ? best.pack.lang : null,
      dateOrder: order,
      dateOrderAmbiguous: ambiguous,
    );
  }

  /// Chữ ký của bảng để nhớ cách ghép (§4.5): băm FNV-1a 64 bit các tên cột đã bỏ dấu/hoa thường. Không có dòng tiêu đề thì null
  /// (cột suy theo kiểu dữ liệu, không đủ ổn định để nhớ). Không chứa nội dung ô dữ liệu.
  static String? signature(TableSheet sheet, int? headerRow) {
    if (headerRow == null || headerRow >= sheet.rows.length) return null;
    final names = [for (final c in sheet.rows[headerRow]) _foldHeader(c.text)];
    while (names.isNotEmpty && names.last.isEmpty) {
      names.removeLast();
    }
    if (names.every((n) => n.isEmpty)) return null;
    var h = 0xcbf29ce484222325;
    for (final b in names.join('\u001f').codeUnits) {
      h ^= b;
      h *= 0x100000001b3; // tràn 64 bit là đúng thuật toán (int của Dart VM quấn vòng)
    }
    return 't1-${h.toUnsigned(64).toRadixString(16)}';
  }

  /// Tên từng cột ở dòng tiêu đề (null: không có tiêu đề hoặc ô trống; màn ghép cột hiện "Cột A").
  static List<String?> headerLabels(TableSheet sheet, int? headerRow) => [
        for (var c = 0; c < sheet.columnCount; c++)
          if (headerRow == null || sheet.cell(headerRow, c).text.trim().isEmpty) null else sheet.cell(headerRow, c).text.trim(),
      ];

  /// Người dùng bật/tắt "Dòng 1 là tiêu đề": bật khi chưa có thì lấy dòng đầu; tắt thì mọi dòng là dữ liệu. Giữ cột đang ghép.
  static TableMapping withHeader(TableMapping m, bool hasHeader) =>
      hasHeader == (m.headerRow != null) ? m : m.copyWith(headerRow: () => hasHeader ? 0 : null);

  /// Mỗi dòng có tên việc thành 1 candidate. [source]: `xlsx` | `csv`.
  List<Candidate> extract(TableSheet sheet, TableMapping mapping, {required String source, required DateTime now}) {
    final pack = packs.where((p) => p.lang == mapping.lang).firstOrNull ?? packs.first;
    final out = <Candidate>[];
    final start = mapping.headerRow == null ? 0 : mapping.headerRow! + 1;
    TableCell at(int r, TableField f) => mapping.columns[f] == null ? TableCell.empty : sheet.cell(r, mapping.columns[f]!);
    for (var r = start; r < sheet.rows.length; r++) {
      var title = at(r, TableField.title).text.trim();
      if (title.isEmpty) continue;
      var when = _when(at(r, TableField.date), at(r, TableField.time), mapping.dateOrder, now);
      final dateCell = at(r, TableField.date);
      if (when == null && !dateCell.isBlank && nlu != null) when = _nluWhen(dateCell.text, now);
      String? rrule;
      int? priority = _priority(at(r, TableField.priority), pack);
      if (when == null && nlu != null) {
        final res = nlu!.parse(title, NluContext(now: now, region: region));
        if ((res.when != null || res.recurrence != null) && res.title.isNotEmpty) {
          title = res.title;
          when = res.when;
          rrule = res.recurrence?.rrule;
          priority ??= res.priority;
        }
      }
      final notes = at(r, TableField.notes).text.trim();
      final location = at(r, TableField.location).text.trim();
      final list = at(r, TableField.list).text.trim();
      out.add(Candidate(
        kind: CandidateKind.task,
        source: source,
        confidence: mapping.headerRow == null ? 0.7 : 0.9,
        rrule: rrule,
        notes: notes.isEmpty ? null : notes,
        priority: priority,
        done: _done(at(r, TableField.status), pack),
        listName: list.isEmpty ? null : list,
        fields: CandidateFields(
          title: title,
          due: when == null ? null : LocalTime(when.time == null ? '${when.date}' : '${when.date}T${when.time}'),
          locationText: location.isEmpty ? null : location,
        ),
      ));
    }
    return out;
  }

  // --- header ---

  static String _foldHeader(String s) =>
      foldForSearch(s).replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ').trim();

  /// Mỗi ô: khớp nguyên tên cột (2 điểm) hoặc chứa tên cột như 1 cụm từ (1 điểm, tên dài nhất thắng).
  /// Mỗi trường nhận 1 cột: điểm cao hơn, rồi cột trái hơn.
  static (Map<TableField, int>, int) _matchHeader(List<TableCell> row, GrammarPack pack) {
    final claims = <TableField, (int col, int score, int len)>{};
    for (var c = 0; c < row.length; c++) {
      final h = _foldHeader(row[c].text);
      if (h.isEmpty || row[c].number != null) continue;
      (TableField, int, int)? bestForCell;
      for (final f in TableField.values) {
        for (final syn in pack.tableColumns[f.name] ?? const <String>[]) {
          final s = _foldHeader(syn);
          if (s.isEmpty) continue;
          final score = h == s ? 2 : (' $h '.contains(' $s ') ? 1 : 0);
          if (score == 0) continue;
          if (bestForCell == null || score > bestForCell.$2 || (score == bestForCell.$2 && s.length > bestForCell.$3)) {
            bestForCell = (f, score, s.length);
          }
        }
      }
      if (bestForCell == null) continue;
      final (f, score, len) = bestForCell;
      final prev = claims[f];
      if (prev == null || score > prev.$2 || (score == prev.$2 && len > prev.$3)) claims[f] = (c, score, len);
    }
    return ({for (final e in claims.entries) e.key: e.value.$1}, claims.values.fold(0, (s, v) => s + v.$2));
  }

  /// Không có header: cột phần lớn là ngày → date; phần lớn là giờ → time; cột chữ dài nhất → title.
  static Map<TableField, int> _inferColumns(TableSheet sheet) {
    final rows = sheet.rows.where((r) => r.any((c) => !c.isBlank)).take(_sampleRows).toList();
    final width = sheet.columnCount;
    final out = <TableField, int>{};
    var bestLen = -1.0;
    for (var c = 0; c < width; c++) {
      final cells = [for (final r in rows) if (c < r.length && !r[c].isBlank) r[c]];
      if (cells.isEmpty) continue;
      final dates = cells.where((x) => _looksLikeDate(x)).length;
      final times = cells.where((x) => _parseTime(x) != null && !_looksLikeDate(x)).length;
      if (dates / cells.length >= 0.6 && !out.containsKey(TableField.date)) {
        out[TableField.date] = c;
        continue;
      }
      if (times / cells.length >= 0.6 && !out.containsKey(TableField.time)) {
        out[TableField.time] = c;
        continue;
      }
      final textual = cells.where((x) => x.number == null && x.boolean == null).toList();
      if (textual.length / cells.length < 0.6) continue;
      final avg = textual.fold(0, (s, x) => s + x.text.trim().length) / textual.length;
      if (avg > bestLen) {
        bestLen = avg;
        out[TableField.title] = c;
      }
    }
    return out;
  }

  // --- ngày giờ ---

  static final _isoDate = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(?:[ T](.*))?$');
  static final _numDate = RegExp(r'^(\d{1,2})[-/.](\d{1,2})(?:[-/.](\d{4}|\d{2}))?(?:[ T,]+(.*))?$');
  /// 14:30 · 9.15 · 9h · 8h30 · 7:05 pm · 7pm · 07:00:00.
  static final _time = RegExp(r'^(\d{1,2})(?:[:.](\d{2})|\s*([hH])(?:\s*(\d{2}))?)?(?::\d{2})?\s*(?:([aApP])\.?\s*[mM]\.?)?$');

  static bool _looksLikeDate(TableCell c) =>
      (c.isDate && (c.number ?? 0) >= 1) || _isoDate.hasMatch(c.text.trim()) || _numDate.hasMatch(c.text.trim());

  /// Thứ tự ngày: ô nào có phần > 12 thì biết; không thì theo vùng (gói), vẫn không biết thì 'dmy' + cờ mơ hồ.
  (String, bool) _dateOrder(TableSheet sheet, Map<TableField, int> cols, int firstData, GrammarPack pack) {
    final dateCol = cols[TableField.date];
    var dmy = false, mdy = false, numeric = false;
    if (dateCol != null) {
      for (var r = firstData; r < sheet.rows.length; r++) {
        final m = _numDate.firstMatch(sheet.cell(r, dateCol).text.trim());
        if (m == null) continue;
        numeric = true;
        final a = int.parse(m[1]!), b = int.parse(m[2]!);
        if (a > 12 && b <= 12) dmy = true;
        if (b > 12 && a <= 12) mdy = true;
      }
    }
    if (dmy != mdy) return (dmy ? 'dmy' : 'mdy', false);
    final byRegion = region == null ? null : pack.dateOrderFor(region);
    final fallback = byRegion ?? pack.dateOrderDefault;
    if (fallback != null) return (fallback, false);
    return ('dmy', numeric);
  }

  static CivilDateTime? _when(TableCell date, TableCell time, String order, DateTime now) {
    final d = _parseDate(date, order, now);
    final t = _parseTime(time) ?? (d?.time);
    if (d == null) return null;
    return CivilDateTime(d.date, t);
  }

  static CivilDateTime? _parseDate(TableCell c, String order, DateTime now) {
    if (c.isBlank) return null;
    if (c.isDate && c.number != null && c.number! >= 1) return excelSerialToCivil(c.number!);
    final s = c.text.trim();
    final iso = _isoDate.firstMatch(s);
    if (iso != null) {
      final y = int.parse(iso[1]!), mo = int.parse(iso[2]!), d = int.parse(iso[3]!);
      if (!CivilDate.isValid(y, mo, d)) return null;
      return CivilDateTime(CivilDate(y, mo, d), iso[4] == null ? null : _parseTime(TableCell(iso[4]!)));
    }
    final m = _numDate.firstMatch(s);
    if (m == null) return null;
    final a = int.parse(m[1]!), b = int.parse(m[2]!);
    final (d, mo) = order == 'mdy' ? (b, a) : (a, b);
    int y;
    if (m[3] == null) {
      // Không có năm: lần gần nhất từ hôm nay trở đi (lùi tối đa 2 tháng: danh sách hay ghi việc vừa qua).
      y = now.year;
      if (CivilDate.isValid(y, mo, d) && CivilDate(y, mo, d).compareTo(CivilDate.of(now).addDays(-60)) < 0) y++;
    } else {
      y = int.parse(m[3]!);
      if (y < 100) y += 2000;
    }
    if (!CivilDate.isValid(y, mo, d)) return null;
    return CivilDateTime(CivilDate(y, mo, d), m[4] == null ? null : _parseTime(TableCell(m[4]!)));
  }

  static CivilTime? _parseTime(TableCell c) {
    if (c.isBlank) return null;
    final n = c.number;
    if (n != null && c.isDate) return excelSerialToCivil(n).time;
    if (n != null && n > 0 && n < 1) return excelSerialToCivil(n).time;
    final m = _time.firstMatch(c.text.trim());
    if (m == null) return null;
    // Số trơn "8" không phải giờ: cần phút, "h" hoặc am/pm.
    if (m[2] == null && m[3] == null && m[5] == null) return null;
    var h = int.parse(m[1]!);
    final min = int.tryParse(m[2] ?? m[4] ?? '') ?? 0;
    final ap = m[5]?.toLowerCase();
    if (ap != null) {
      if (h < 1 || h > 12) return null;
      h = h % 12 + (ap == 'p' ? 12 : 0);
    }
    if (h > 23 || min > 59) return null;
    return CivilTime(h, min);
  }

  CivilDateTime? _nluWhen(String text, DateTime now) => nlu!.parse(text, NluContext(now: now, region: region)).when;

  // --- ưu tiên, trạng thái ---

  static int? _priority(TableCell c, GrammarPack pack) {
    if (c.isBlank) return null;
    final s = foldForSearch(c.text).trim();
    if (pack.tablePriority[s] case final p?) return p;
    final bang = RegExp(r'^!{1,3}$').firstMatch(s);
    if (bang != null) return s.length;
    final p = RegExp(r'^p([123])$').firstMatch(s);
    if (p != null) return 4 - int.parse(p[1]!);
    return null;
  }

  static bool _done(TableCell c, GrammarPack pack) {
    if (c.boolean != null) return c.boolean!;
    final s = foldForSearch(c.text).trim();
    return s.isNotEmpty && (_universalDone.contains(s) || pack.tableDone.contains(s));
  }
}
