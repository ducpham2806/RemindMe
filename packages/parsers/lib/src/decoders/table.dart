import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:xml/xml.dart';

import 'mime.dart' show decodeCharset;

/// Một ô bảng. xlsx giữ kiểu gốc (số, ngày theo định dạng ô, đúng/sai); csv chỉ có chữ.
class TableCell {
  const TableCell(this.text, {this.number, this.isDate = false, this.boolean});
  static const empty = TableCell('');

  /// Chữ như người dùng thấy (ô ngày của xlsx: ISO `YYYY-MM-DD` hoặc `YYYY-MM-DDTHH:MM`).
  final String text;
  final num? number;
  /// Ô số có định dạng ngày/giờ (xlsx): [number] là serial Excel.
  final bool isDate;
  final bool? boolean;

  bool get isBlank => text.trim().isEmpty && number == null && boolean == null;

  @override
  String toString() => text;
}

class TableSheet {
  const TableSheet(this.name, this.rows);
  final String? name;
  final List<List<TableCell>> rows;

  int get columnCount => rows.fold(0, (m, r) => r.length > m ? r.length : m);
  TableCell cell(int row, int col) => row < rows.length && col < rows[row].length ? rows[row][col] : TableCell.empty;
}

/// Serial Excel → ngày giờ dân sự. Hệ 1900 lấy gốc 1899-12-30 (đã tính lỗi năm nhuận 1900 của Lotus); hệ 1904 gốc 1904-01-01.
CivilDateTime excelSerialToCivil(num serial, {bool date1904 = false}) {
  final base = date1904 ? DateTime.utc(1904) : DateTime.utc(1899, 12, 30);
  final days = serial.floor();
  final minutes = ((serial - days) * 1440).round();
  final d = base.add(Duration(days: days, minutes: minutes));
  final hasTime = serial != days;
  return CivilDateTime(CivilDate.of(d), hasTime ? CivilTime(d.hour, d.minute) : null);
}

/// CSV/TSV (RFC 4180: ngoặc kép, xuống dòng trong ô). Tự đoán dấu phân cách (`,` `;` tab `|`: Excel ở VN/châu Âu xuất `;`)
/// và mã hóa (BOM UTF-8/UTF-16, không có thì UTF-8 rồi windows-1252).
class CsvReader {
  const CsvReader();

  TableSheet readBytes(List<int> bytes, {String? name}) => read(decodeText(bytes), name: name);

  static String decodeText(List<int> b) {
    if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) return utf8.decode(b.sublist(3), allowMalformed: true);
    if (b.length >= 2 && ((b[0] == 0xFF && b[1] == 0xFE) || (b[0] == 0xFE && b[1] == 0xFF))) {
      final le = b[0] == 0xFF;
      final units = [for (var i = 2; i + 1 < b.length; i += 2) le ? b[i] | (b[i + 1] << 8) : (b[i] << 8) | b[i + 1]];
      return String.fromCharCodes(units);
    }
    return decodeCharset(b, null);
  }

  TableSheet read(String text, {String? name, String? delimiter}) {
    final d = delimiter ?? sniffDelimiter(text);
    final rows = <List<TableCell>>[];
    var row = <TableCell>[];
    final cell = StringBuffer();
    var quoted = false;
    var i = 0;
    void endCell() {
      row.add(TableCell(cell.toString()));
      cell.clear();
    }

    void endRow() {
      endCell();
      if (!(row.length == 1 && row.first.text.isEmpty)) rows.add(row);
      row = <TableCell>[];
    }

    while (i < text.length) {
      final c = text[i];
      if (quoted) {
        if (c == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i += 2;
            continue;
          }
          quoted = false;
        } else {
          cell.write(c);
        }
      } else if (c == '"' && cell.isEmpty) {
        quoted = true;
      } else if (c == d) {
        endCell();
      } else if (c == '\r' || c == '\n') {
        endRow();
        if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      } else {
        cell.write(c);
      }
      i++;
    }
    if (cell.isNotEmpty || row.isNotEmpty) endRow();
    return TableSheet(name, rows);
  }

  /// Dấu xuất hiện đều nhất (cùng số lần, khác 0) trên 10 dòng đầu, ngoài ngoặc kép.
  static String sniffDelimiter(String text) {
    const candidates = [',', ';', '\t', '|'];
    final lines = <String>[];
    final b = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length && lines.length < 10; i++) {
      final c = text[i];
      if (c == '"') quoted = !quoted;
      if ((c == '\n') && !quoted) {
        lines.add(b.toString());
        b.clear();
      } else if (!quoted) {
        b.write(c);
      }
    }
    if (b.isNotEmpty && lines.length < 10) lines.add(b.toString());
    final body = lines.where((l) => l.trim().isNotEmpty).toList();
    var best = ',';
    var bestScore = -1.0;
    for (final d in candidates) {
      final counts = [for (final l in body) d.allMatches(l).length];
      if (counts.isEmpty || counts.first == 0) continue;
      final consistent = counts.where((n) => n == counts.first).length / counts.length;
      final score = consistent * 100 + counts.first;
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    return best;
  }
}

/// `.xlsx` (Office Open XML) bằng `archive` + `xml`: chuỗi dùng chung, chuỗi inline, số, đúng/sai, ô ngày theo định dạng số
/// (mã có sẵn 14-22, 27-36, 45-47, 50-58, 71-81 và mã tự định nghĩa có d/m/y/h/s), hệ ngày 1904. Không chạy công thức: lấy giá trị đã lưu.
class XlsxReader {
  const XlsxReader();

  static const _builtinDateFormats = {14, 15, 16, 17, 18, 19, 20, 21, 22, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 45, 46, 47, //
    50, 51, 52, 53, 54, 55, 56, 57, 58, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81};

  /// Mọi sheet theo thứ tự trong workbook; file hỏng trả rỗng.
  List<TableSheet> read(List<int> bytes) {
    try {
      return _read(ZipDecoder().decodeBytes(bytes));
    } on Object {
      return const [];
    }
  }

  List<TableSheet> _read(Archive zip) {
    XmlDocument? doc(String path) {
      final f = zip.findFile(path);
      return f == null ? null : XmlDocument.parse(utf8.decode(f.content, allowMalformed: true));
    }

    final workbook = doc('xl/workbook.xml');
    if (workbook == null) return const [];
    final date1904 = workbook.findAllElements('workbookPr').any((e) => const {'1', 'true'}.contains(e.getAttribute('date1904')));
    final rels = <String, String>{
      for (final r in doc('xl/_rels/workbook.xml.rels')?.findAllElements('Relationship') ?? const <XmlElement>[])
        r.getAttribute('Id') ?? '': r.getAttribute('Target') ?? '',
    };
    final shared = [
      for (final si in doc('xl/sharedStrings.xml')?.findAllElements('si') ?? const <XmlElement>[]) _richText(si),
    ];
    final dateStyles = _dateStyles(doc('xl/styles.xml'));

    final out = <TableSheet>[];
    for (final s in workbook.findAllElements('sheet')) {
      final rid = s.attributes.where((a) => a.name.local == 'id').firstOrNull?.value;
      var target = rels[rid] ?? '';
      if (target.isEmpty) continue;
      target = target.startsWith('/') ? target.substring(1) : 'xl/$target';
      final sheet = doc(target);
      if (sheet == null) continue;
      out.add(TableSheet(s.getAttribute('name'), _rows(sheet, shared, dateStyles, date1904)));
    }
    return out;
  }

  static String _richText(XmlElement si) => [
        for (final t in si.findAllElements('t'))
          if (t.parentElement?.name.local != 'rPh') t.innerText,
      ].join();

  /// Chỉ số style (cellXfs) có định dạng ngày/giờ.
  static Set<int> _dateStyles(XmlDocument? styles) {
    if (styles == null) return const {};
    final custom = <int, String>{
      for (final f in styles.findAllElements('numFmt')) int.tryParse(f.getAttribute('numFmtId') ?? '') ?? -1: f.getAttribute('formatCode') ?? '',
    };
    final xfs = styles.findAllElements('cellXfs').firstOrNull?.findElements('xf').toList() ?? const [];
    return {
      for (var i = 0; i < xfs.length; i++)
        if (_isDateFormat(int.tryParse(xfs[i].getAttribute('numFmtId') ?? '') ?? 0, custom)) i,
    };
  }

  static bool _isDateFormat(int id, Map<int, String> custom) {
    if (_builtinDateFormats.contains(id)) return true;
    final code = custom[id];
    if (code == null) return false;
    final stripped = code.replaceAll(RegExp(r'"[^"]*"|\\.|\[[^\]]*\]'), '').split(';').first.toLowerCase();
    return RegExp('[dmyhs]').hasMatch(stripped) && !stripped.contains('general');
  }

  static List<List<TableCell>> _rows(XmlDocument sheet, List<String> shared, Set<int> dateStyles, bool date1904) {
    final rows = <List<TableCell>>[];
    var nextRow = 0;
    for (final r in sheet.findAllElements('row')) {
      final rowIndex = (int.tryParse(r.getAttribute('r') ?? '') ?? (nextRow + 1)) - 1;
      nextRow = rowIndex + 1;
      while (rows.length < rowIndex) {
        rows.add(const []);
      }
      final cells = <TableCell>[];
      var nextCol = 0;
      for (final c in r.findElements('c')) {
        final col = _columnIndex(c.getAttribute('r')) ?? nextCol;
        nextCol = col + 1;
        while (cells.length < col) {
          cells.add(TableCell.empty);
        }
        cells.add(_cell(c, shared, dateStyles, date1904));
      }
      rows.add(cells);
    }
    return rows;
  }

  static int? _columnIndex(String? ref) {
    final m = RegExp(r'^([A-Z]+)').firstMatch(ref ?? '');
    if (m == null) return null;
    var n = 0;
    for (final ch in m[1]!.codeUnits) {
      n = n * 26 + (ch - 64);
    }
    return n - 1;
  }

  static TableCell _cell(XmlElement c, List<String> shared, Set<int> dateStyles, bool date1904) {
    final t = c.getAttribute('t') ?? 'n';
    final v = c.findElements('v').firstOrNull?.innerText;
    switch (t) {
      case 's':
        final i = int.tryParse(v ?? '');
        return i == null || i >= shared.length ? TableCell.empty : TableCell(shared[i]);
      case 'inlineStr':
        final isEl = c.findElements('is').firstOrNull;
        return isEl == null ? TableCell.empty : TableCell(_richText(isEl));
      case 'str':
        return TableCell(v ?? '');
      case 'b':
        final b = v == '1';
        return TableCell(b ? 'TRUE' : 'FALSE', boolean: b);
      case 'e':
        return TableCell.empty;
      default:
        final n = num.tryParse(v ?? '');
        if (n == null) return TableCell.empty;
        final style = int.tryParse(c.getAttribute('s') ?? '') ?? 0;
        if (dateStyles.contains(style)) {
          final dt = excelSerialToCivil(n, date1904: date1904);
          final text = n < 1 ? '${dt.time ?? CivilTime(0)}' : (dt.time == null ? '${dt.date}' : '${dt.date}T${dt.time}');
          return TableCell(text, number: n, isDate: true);
        }
        return TableCell(_numText(n), number: n);
    }
  }

  static String _numText(num n) => n == n.roundToDouble() ? n.round().toString() : n.toString();
}
