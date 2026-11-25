import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:remindme_parsers/remindme_parsers.dart';
import 'package:test/test.dart';

final now = DateTime(2026, 11, 24, 9);
final vi = GrammarPack.fromYaml(File('nlu/packs/vi.yaml').readAsStringSync());
final en = GrammarPack.fromYaml(File('nlu/packs/en.yaml').readAsStringSync());

List<int> xlsx(Map<String, String> files) {
  final a = Archive();
  files.forEach((name, body) => a.add(ArchiveFile.bytes(name, utf8.encode(body))));
  return ZipEncoder().encodeBytes(a);
}

const ns = 'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';

void main() {
  group('CsvReader', () {
    test('đoán dấu phân cách, ngoặc kép có dấu ; và xuống dòng, "" thoát', () {
      final t = const CsvReader().read('a;b;c\r\n"x;1";"dòng 1\ndòng 2";"nói ""chào"""\r\n\r\n4;5;6');
      expect(t.rows.map((r) => r.map((c) => c.text).toList()), [
        ['a', 'b', 'c'],
        ['x;1', 'dòng 1\ndòng 2', 'nói "chào"'],
        ['4', '5', '6'],
      ]);
      expect(CsvReader.sniffDelimiter('a,b\n1,2'), ',');
      expect(CsvReader.sniffDelimiter('task\tdue\nx\t1/2'), '\t');
    });

    test('mã hóa: UTF-16 LE có BOM (Excel "Unicode text"), windows-1252 không BOM', () {
      final utf16 = [0xFF, 0xFE, for (final u in 'Việc\tHạn\n'.codeUnits) ...[u & 0xFF, u >> 8]];
      expect(const CsvReader().readBytes(utf16).rows.first.map((c) => c.text), ['Việc', 'Hạn']);
      expect(const CsvReader().readBytes([0x43, 0x61, 0x66, 0xE9, 0x2C, 0x93, 0x78, 0x94]).rows.first.map((c) => c.text), ['Café', '“x”']);
    });
  });

  group('XlsxReader', () {
    test('chuỗi dùng chung (rich text, bỏ phiên âm), ô trống ở giữa, ngày hệ 1904, định dạng tự định nghĩa, đúng/sai, nhiều sheet', () {
      final bytes = xlsx({
        'xl/workbook.xml': '<workbook $ns><workbookPr date1904="1"/><sheets>'
            '<sheet name="Việc" sheetId="1" r:id="rId1"/><sheet name="Khác" sheetId="2" r:id="rId2"/></sheets></workbook>',
        'xl/_rels/workbook.xml.rels': '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="t" Target="worksheets/sheet1.xml"/>'
            '<Relationship Id="rId2" Type="t" Target="/xl/worksheets/sheet2.xml"/></Relationships>',
        'xl/sharedStrings.xml': '<sst $ns><si><t>Việc</t></si><si><r><t>Nộp </t></r><r><t>thuế</t></r><rPh><t>x</t></rPh></si></sst>',
        'xl/styles.xml': '<styleSheet $ns><numFmts><numFmt numFmtId="170" formatCode="[\$-42A]dd/mm/yyyy;@"/>'
            '<numFmt numFmtId="171" formatCode="&quot;Tổng&quot; 0.00"/></numFmts>'
            '<cellXfs><xf numFmtId="0"/><xf numFmtId="170"/><xf numFmtId="171"/><xf numFmtId="20"/></cellXfs></styleSheet>',
        'xl/worksheets/sheet1.xml': '<worksheet $ns><sheetData>'
            '<row r="1"><c r="A1" t="s"><v>0</v></c></row>'
            '<row r="2"><c r="A2" t="s"><v>1</v></c><c r="C2" s="1"><v>45269</v></c><c r="D2" s="2"><v>12.5</v></c>'
            '<c r="E2" t="b"><v>1</v></c><c r="F2" s="3"><v>0.375</v></c><c r="G2" t="str"><f>A1</f><v>Việc</v></c></row>'
            '</sheetData></worksheet>',
        'xl/worksheets/sheet2.xml': '<worksheet $ns><sheetData><row r="1"><c r="A1" t="inlineStr"><is><t>ok</t></is></c></row></sheetData></worksheet>',
      });
      final sheets = const XlsxReader().read(bytes);
      expect(sheets.map((s) => s.name), ['Việc', 'Khác']);
      final row = sheets.first.rows[1];
      expect(row.map((c) => c.text), ['Nộp thuế', '', '2027-12-10', '12.5', 'TRUE', '09:00', 'Việc']);
      expect((row[2].isDate, row[3].isDate, row[4].boolean), (true, false, true));
      expect(sheets[1].rows.single.single.text, 'ok');
      expect(const XlsxReader().read([1, 2, 3]), isEmpty);
    });

    test('serial Excel: hệ 1900 (sau 29/2/1900 giả) và giờ lẻ', () {
      expect('${excelSerialToCivil(46360)}', '2026-12-04');
      expect('${excelSerialToCivil(46374.32291666666)}', '2026-12-18 07:45');
      expect('${excelSerialToCivil(1)}', '1899-12-31');
    });
  });

  group('TableTaskExtractor', () {
    test('header tiếng Việt không dấu/viết hoa, cột STT bị bỏ, ưu tiên và trạng thái theo gói', () {
      final sheet = const CsvReader().read('STT,CONG VIEC,Ngày hết hạn,Muc do,Tinh trang,Người phụ trách,Nhóm\n'
          '1,Gọi thợ điện,03/12/2026,khẩn,đã xong,Hùng,Nhà\n'
          '2,Mua sơn,4/12,bình thường,,Lan,\n');
      final x = TableTaskExtractor([en, vi], region: 'VN');
      final m = x.detect(sheet);
      expect(m.headerRow, 0);
      expect(m.lang, 'vi');
      expect(m.columns, {
        TableField.title: 1,
        TableField.date: 2,
        TableField.priority: 3,
        TableField.status: 4,
        TableField.assignee: 5,
        TableField.list: 6,
      });
      final c = x.extract(sheet, m, source: 'csv', now: now);
      expect(c.map((e) => (e.fields.title, e.fields.due?.local, e.priority, e.done, e.listName)), [
        ('Gọi thợ điện', '2026-12-03', 3, true, 'Nhà'),
        ('Mua sơn', '2026-12-04', 2, false, null),
      ]);
    });

    test('thứ tự ngày: ô > 12 quyết định; không có thì theo vùng; vẫn không biết thì báo mơ hồ', () {
      CsvReader r() => const CsvReader();
      final us = r().read('Task,Due\nA,12/25/2026\nB,01/02/2027');
      expect(TableTaskExtractor([en]).detect(us).dateOrder, 'mdy');
      final plain = r().read('Task,Due\nA,01/02/2027');
      expect(TableTaskExtractor([en], region: 'US').detect(plain).dateOrder, 'mdy');
      expect(TableTaskExtractor([en], region: 'GB').detect(plain).dateOrder, 'dmy');
      final unknown = TableTaskExtractor([en]).detect(plain);
      expect((unknown.dateOrder, unknown.dateOrderAmbiguous), ('dmy', true));
      final x = TableTaskExtractor([en]);
      expect(x.extract(plain, unknown.copyWith(dateOrder: 'mdy'), source: 'csv', now: now).single.fields.due!.local, '2027-01-02');
    });

    test('không có header: suy cột theo kiểu dữ liệu', () {
      final sheet = const CsvReader().read('Đi khám răng định kỳ,2026-12-10,14:30,x\nThay dầu xe,2026-12-12,9h,\nĐóng tiền nhà tháng 12,2026-12-05,,');
      final x = TableTaskExtractor([vi]);
      final m = x.detect(sheet);
      expect(m.headerRow, isNull);
      expect(m.columns, {TableField.title: 0, TableField.date: 1, TableField.time: 2});
      final c = x.extract(sheet, m, source: 'csv', now: now);
      expect(c.map((e) => e.fields.due!.local), ['2026-12-10T14:30', '2026-12-12T09:00', '2026-12-05']);
      expect(c.first.confidence, lessThan(0.9));
    });

    test('không có cột ngày: NLU đọc tên việc; ô ngày dạng chữ cũng đọc qua NLU', () {
      final sheet = const CsvReader().read('Việc,Hạn\nHọp phụ huynh 7h tối thứ 6,\nTưới cây,thứ 2 tuần sau\nDọn kho,\n');
      final x = TableTaskExtractor([vi], nlu: NluEngine([vi]));
      final c = x.extract(sheet, x.detect(sheet), source: 'csv', now: now);
      expect(c.map((e) => (e.fields.title, e.fields.due?.local)), [
        ('Họp phụ huynh', '2026-11-27T19:00'),
        ('Tưới cây', '2026-11-30'),
        ('Dọn kho', null),
      ]);
    });

    test('ngày ISO kèm giờ trong 1 ô, giờ 12h am/pm, năm 2 chữ số; ngày sai thì bỏ trống', () {
      final sheet = const CsvReader().read('Task,Date,Time\nA,2026-12-01 18:15,\nB,5/12/26,7:05 pm\nC,31/04/2027,\n');
      final x = TableTaskExtractor([en], region: 'GB');
      expect(x.extract(sheet, x.detect(sheet), source: 'csv', now: now).map((e) => e.fields.due?.local),
          ['2026-12-01T18:15', '2026-12-05T19:05', null]);
    });

    test('ghép cột thủ công, bật/tắt dòng tiêu đề, chữ ký header (bỏ dấu/hoa thường) và áp cách ghép đã nhớ', () {
      final sheet = const CsvReader().read('Công việc,Hạn chót,Thời gian,Mô tả\nGửi báo giá,25/11/2026,08:00,Khách A\nHọp,26/11/2026,9:30,\n');
      final x = TableTaskExtractor([en, vi], region: 'VN');
      final m = x.detect(sheet);
      expect(TableTaskExtractor.headerLabels(sheet, m.headerRow), ['Công việc', 'Hạn chót', 'Thời gian', 'Mô tả']);
      final sig = TableTaskExtractor.signature(sheet, m.headerRow);
      expect(sig, startsWith('t1-'));
      expect(TableTaskExtractor.signature(const CsvReader().read('CONG VIEC,han chot,Thoi gian,Mo ta\n'), 0), sig);
      expect(TableTaskExtractor.signature(const CsvReader().read('Việc,Ngày\n'), 0), isNot(sig));
      expect(TableTaskExtractor.signature(sheet, null), isNull);

      // Ghi chú → cột tên việc, tên việc → ghi chú.
      final swapped = m.copyWith(columns: {...m.columns, TableField.title: 3, TableField.notes: 0});
      expect(x.extract(sheet, swapped, source: 'csv', now: now).map((c) => (c.fields.title, c.notes)), [('Khách A', 'Gửi báo giá')]);

      // Tắt dòng tiêu đề: dòng 1 thành dữ liệu.
      final noHeader = TableTaskExtractor.withHeader(m, false);
      expect(x.extract(sheet, noHeader, source: 'csv', now: now).first.fields.title, 'Công việc');
      expect(TableTaskExtractor.withHeader(noHeader, true).headerRow, 0);

      // Nhớ rồi áp lại; JSON hỏng hoặc cột ngoài bảng thì giữ kết quả dò.
      final saved = jsonDecode(jsonEncode(swapped.copyWith(dateOrder: 'mdy').toJson())) as Map<String, Object?>;
      final again = TableMapping.applySaved(m, saved, columnCount: sheet.columnCount);
      expect((again.columns[TableField.title], again.dateOrder, again.headerRow), (3, 'mdy', 0));
      expect(TableMapping.applySaved(m, {'columns': {'title': 9}}, columnCount: 4).columns, m.columns);
      expect(TableMapping.applySaved(m, {'columns': 'x'}, columnCount: 4).columns, m.columns);
      expect(TableMapping.applySaved(m, {'columns': {'notes': 1}}, columnCount: 4).columns, m.columns);
      expect(TableMapping.applySaved(m, {'columns': {'title': 0}, 'has_header': false}, columnCount: 4).headerRow, isNull);
    });
  });
}

