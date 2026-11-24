import 'dart:convert';
import 'dart:io';

import 'package:remindme_parsers/remindme_parsers.dart';
import 'package:test/test.dart';

final packs = [for (final l in ['vi', 'en']) GrammarPack.fromYaml(File('nlu/packs/$l.yaml').readAsStringSync())];
final airports = AirportIndex.parse(File('data/airports.tsv').readAsStringSync());

/// Tầng luật T2 trên text (email không có dữ liệu có cấu trúc, text tự do; ảnh chờ OCR thật ở spike E0).
List<Candidate>? rules(String text, Map<String, Object?> meta, DateTime reference, {String? senderDomain}) {
  final lang = meta['doc_language'] as String?;
  final engine = RuleEngine(packs: [...packs.where((p) => p.lang == lang), ...packs.where((p) => p.lang != lang)], airports: airports, region: meta['market'] as String?);
  final c = engine.extract(TextDocument.fromText(text, senderDomain: senderDomain, language: lang), reference: reference).candidates;
  return c.isEmpty ? null : c;
}

List<Candidate> tableTasks(TableSheet sheet, String source, DateTime reference, String market) {
  final x = TableTaskExtractor(packs, region: market);
  return x.extract(sheet, x.detect(sheet), source: source, now: reference);
}

/// Chạy tầng có sẵn trên từng mẫu trong fixtures/docs (E3.5): T0 trước, không ra gì thì T2. Loại input chưa có tầng xử lý (ảnh, PDF) thì bỏ qua.
List<Candidate>? run(File input, Map<String, Object?> meta) {
  final reference = DateTime.parse(meta['collected_at']! as String);
  final ext = input.path.split('.').last.toLowerCase();
  switch (ext) {
    case 'ics':
      return const IcsDecoder().decode(input.readAsStringSync());
    case 'eml':
      final email = const EmailDecoder().decode(input.readAsBytesSync(), reference: reference);
      if (email.candidates.isNotEmpty) return email.candidates;
      return rules(email.text, meta, email.sentAt ?? reference, senderDomain: email.from?.split('@').last.replaceAll('>', ''));
    case 'html':
      final c = const JsonLdDecoder().decodeHtml(input.readAsStringSync());
      return c.isEmpty ? null : c;
    case 'pkpass':
      return const PkpassDecoder().decodeZip(input.readAsBytesSync(), reference: reference);
    case 'csv':
      return tableTasks(const CsvReader().readBytes(input.readAsBytesSync()), 'csv', reference, meta['market']! as String);
    case 'xlsx':
      return tableTasks(const XlsxReader().read(input.readAsBytesSync()).first, 'xlsx', reference, meta['market']! as String);
    case 'md':
      final lang = meta['doc_language']! as String;
      final nlu = NluEngine([...packs.where((p) => p.lang == lang), ...packs.where((p) => p.lang != lang)]);
      return MarkdownDecoder(nlu: nlu, region: meta['market'] as String?).decode(input.readAsStringSync(), now: reference);
    case 'txt' when meta['source_kind'] == 'boarding_pass_barcode':
      return const BcbpDecoder().decode(input.readAsLinesSync().first.trimRight(), reference: reference);
    case 'txt':
      return rules(input.readAsStringSync(), meta, reference);
    default:
      return null;
  }
}

void main() {
  test('eval trích xuất trên fixtures/docs: decoder T0 ≥ 95% trường bắt buộc, không điền sai', () {
    final report = ExtractEvalReport();
    for (final dir in Directory('fixtures/docs').listSync().whereType<Directory>().toList()..sort((a, b) => a.path.compareTo(b.path))) {
      final input = dir.listSync().whereType<File>().firstWhere((f) => f.uri.pathSegments.last.startsWith('input.'));
      final meta = (jsonDecode(File('${dir.path}/meta.json').readAsStringSync()) as Map).cast<String, Object?>();
      final expected = (jsonDecode(File('${dir.path}/expected.json').readAsStringSync()) as Map).cast<String, Object?>();
      scoreDocument(report, dir.uri.pathSegments.where((s) => s.isNotEmpty).last, expected, run(input, meta));
    }
    // Báo cáo in ra cả khi pass để theo dõi trên CI (E3.5).
    print('$report'); // ignore: avoid_print
    expect(report.docs, greaterThanOrEqualTo(3));
    expect(report.requiredAccuracy, greaterThanOrEqualTo(0.95), reason: '$report');
    expect(report.wrongFills, 0, reason: '$report');
  });
}
