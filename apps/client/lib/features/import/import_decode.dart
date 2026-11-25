import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

/// Loại tệp nhập được (on-device-extraction.md §2). `unsupported` gồm PDF/ảnh (tầng T1/E1.3 chưa có).
enum ImportFormat { ics, pkpass, email, csv, xlsx, markdown, text, unsupported }

/// Yêu cầu giải mã: dữ liệu thuần để chạy trong isolate (gói ngôn ngữ ở dạng chuỗi YAML).
class ImportRequest {
  const ImportRequest({
    required this.name,
    required this.bytes,
    required this.packSources,
    required this.now,
    this.airportsTsv,
    this.region,
    this.dateOrder,
    this.sheetIndex = 0,
    this.columns,
    this.hasHeader,
    this.savedMappings = const {},
  });

  final String name;
  final Uint8List bytes;
  /// Ngôn ngữ → YAML; gói đầu là gói chính (ngôn ngữ giao diện).
  final Map<String, String> packSources;
  /// `packages/parsers/data/airports.tsv`: mã sân bay → múi giờ cho tầng luật T2. null = T2 chạy không có từ điển.
  final String? airportsTsv;
  /// Giờ máy (local) lúc nhập: suy năm cho ngày không có năm, ngày tương đối trong câu.
  final DateTime now;
  final String? region;
  /// Người dùng chọn lại thứ tự ngày của bảng ('dmy' | 'mdy').
  final String? dateOrder;
  final int sheetIndex;
  /// Bảng: cột người dùng ghép lại ở màn Ghép cột (Figma 18); null = theo kết quả dò / cách ghép đã nhớ.
  final Map<TableField, int>? columns;
  /// Bảng: người dùng bật/tắt "Dòng 1 là tiêu đề".
  final bool? hasHeader;
  /// Cách ghép đã nhớ: chữ ký header → JSON của [TableMapping.toJson] (LocalPrefs, on-device-extraction §4.5).
  final Map<String, String> savedMappings;

  /// Đổi trang tính thì bỏ cột/tiêu đề đã chọn cho trang cũ.
  ImportRequest copyWith({String? dateOrder, int? sheetIndex, Map<TableField, int>? columns, bool? hasHeader}) {
    final sameSheet = sheetIndex == null || sheetIndex == this.sheetIndex;
    return ImportRequest(
      name: name,
      bytes: bytes,
      packSources: packSources,
      now: now,
      airportsTsv: airportsTsv,
      region: region,
      dateOrder: dateOrder ?? (sameSheet ? this.dateOrder : null),
      sheetIndex: sheetIndex ?? this.sheetIndex,
      columns: columns ?? (sameSheet ? this.columns : null),
      hasHeader: hasHeader ?? (sameSheet ? this.hasHeader : null),
      savedMappings: savedMappings,
    );
  }
}

/// Cách hiểu bảng đang dùng: nhãn cột (null = không có tiêu đề), cột → trường, chữ ký để nhớ, có áp cách ghép đã nhớ không.
class TableInfo {
  const TableInfo({
    required this.labels,
    required this.columns,
    required this.hasHeader,
    required this.dataRows,
    this.signature,
    this.remembered = false,
  });

  final List<String?> labels;
  final Map<TableField, int> columns;
  final bool hasHeader;
  /// Số dòng dữ liệu (kể cả dòng không có tên việc).
  final int dataRows;
  final String? signature;
  final bool remembered;
  /// JSON để nhớ cách ghép (chỉ khi có [signature]).
  String mappingJson(String dateOrder) => jsonEncode({
        'columns': {for (final e in columns.entries) e.key.name: e.value},
        'date_order': dateOrder,
        'has_header': hasHeader,
      });
}

class ImportPreview {
  const ImportPreview({
    required this.format,
    required this.candidates,
    this.sheetNames = const [],
    this.sheetIndex = 0,
    this.dateOrder,
    this.dateOrderAmbiguous = false,
    this.docLanguage,
    this.subject,
    this.pendingAttachments = const [],
    this.docType,
    this.templateId,
    this.reminderDefaults = const [],
    this.trips = const [],
    this.table,
  });

  final ImportFormat format;
  final List<Candidate> candidates;
  final List<String> sheetNames;
  final int sheetIndex;
  final String? dateOrder;
  final bool dateOrderAmbiguous;
  final String? docLanguage;
  /// Tiêu đề email.
  final String? subject;
  /// Tên tệp đính kèm chưa đọc được (PDF, ảnh...).
  final List<String> pendingAttachments;
  /// Loại tài liệu khi đã qua tầng luật T2 (email/text không có dữ liệu có cấu trúc).
  final DocType? docType;
  /// Mẫu nhà cung cấp đã khớp (`id@version`).
  final String? templateId;
  /// Nhắc mặc định theo loại cho từng đề xuất (cùng thứ tự `candidates`; null = như Quick Add).
  final List<DefaultReminders?> reminderDefaults;
  /// Gợi ý gom đặt chỗ đi lại thành chuyến đi (US-21).
  final List<TripSuggestion> trips;
  /// Bảng tính: cách ghép cột đang dùng (màn Ghép cột, Figma 18).
  final TableInfo? table;

  /// Múi giờ sân bay cho vé chỉ có offset, nhắc mặc định, gợi ý chuyến đi: cần từ điển sân bay nên làm trong isolate.
  ImportPreview _withTravel(AirportIndex? airports) {
    final cs = airports == null ? candidates : [for (final c in candidates) withAirportTimeZones(c, airports)];
    return ImportPreview(
      format: format,
      candidates: cs,
      sheetNames: sheetNames,
      sheetIndex: sheetIndex,
      dateOrder: dateOrder,
      dateOrderAmbiguous: dateOrderAmbiguous,
      docLanguage: docLanguage,
      subject: subject,
      pendingAttachments: pendingAttachments,
      docType: docType,
      templateId: templateId,
      reminderDefaults: [for (final c in cs) defaultReminders(c, airports: airports)],
      trips: suggestTrips(cs, airports: airports),
      table: table,
    );
  }

  /// `imports.tier_used`: qua tầng luật thì `t1t2` (CHECK của server), decoder định dạng thì `t0`.
  String get tierUsed => docType != null ? 't1t2' : 't0';

  /// Giá trị `imports.kind`.
  String get recordKind => switch (format) {
        ImportFormat.ics => 'ics',
        ImportFormat.pkpass => 'pkpass',
        ImportFormat.email => 'email',
        ImportFormat.csv || ImportFormat.xlsx => 'xlsx',
        ImportFormat.markdown => 'md',
        ImportFormat.text || ImportFormat.unsupported => 'text',
      };
}

/// Theo đuôi tệp, rồi theo nội dung khi đuôi lạ (tệp chia sẻ từ app khác hay mất đuôi).
ImportFormat detectFormat(String name, List<int> bytes) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  switch (ext) {
    case 'ics' || 'ical' || 'ifb' || 'vcs':
      return ImportFormat.ics;
    case 'pkpass':
      return ImportFormat.pkpass;
    case 'eml':
      return ImportFormat.email;
    case 'csv' || 'tsv':
      return ImportFormat.csv;
    case 'xlsx' || 'xlsm':
      return ImportFormat.xlsx;
    case 'md' || 'markdown':
      return ImportFormat.markdown;
    case 'txt':
      return ImportFormat.text;
    case 'pdf' || 'jpg' || 'jpeg' || 'png' || 'heic' || 'webp' || 'xls' || 'msg' || 'docx':
      return ImportFormat.unsupported;
  }
  if (bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
    try {
      final names = ZipDecoder().decodeBytes(bytes).files.map((f) => f.name).toSet();
      if (names.contains('pass.json')) return ImportFormat.pkpass;
      if (names.contains('xl/workbook.xml')) return ImportFormat.xlsx;
    } on Object {
      return ImportFormat.unsupported;
    }
    return ImportFormat.unsupported;
  }
  final head = latin1.decode(bytes.take(2048).toList(), allowInvalid: true);
  if (head.trimLeft().toUpperCase().startsWith('BEGIN:VCALENDAR')) return ImportFormat.ics;
  if (RegExp(r'^(?:Received|From|MIME-Version|Return-Path|Delivered-To|Subject):', multiLine: true, caseSensitive: false).hasMatch(head) &&
      RegExp(r'^\r?$', multiLine: true).hasMatch(head)) {
    return ImportFormat.email;
  }
  return ImportFormat.unsupported;
}

/// Giải mã tệp thành đề xuất, kèm nhắc mặc định và gợi ý chuyến đi. Thuần Dart, không đụng Flutter: chạy được trong `Isolate.run`.
ImportPreview decodeImport(ImportRequest r) {
  final airports = r.airportsTsv == null ? null : AirportIndex.parse(r.airportsTsv!);
  return _decode(r, airports)._withTravel(airports);
}

ImportPreview _decode(ImportRequest r, AirportIndex? airports) {
  final packs = [for (final src in r.packSources.values) GrammarPack.fromYaml(src)];
  final nlu = NluEngine(packs);
  final format = detectFormat(r.name, r.bytes);
  final reference = r.now.toUtc();
  switch (format) {
    case ImportFormat.ics:
      return ImportPreview(format: format, candidates: const IcsDecoder().decode(CsvReader.decodeText(r.bytes)));
    case ImportFormat.pkpass:
      return ImportPreview(format: format, candidates: const PkpassDecoder().decodeZip(r.bytes, reference: reference));
    case ImportFormat.email:
      final e = const EmailDecoder().decode(r.bytes, reference: reference);
      final pending = [for (final p in e.pending) p.filename ?? p.mediaType];
      if (e.candidates.isEmpty && e.text.trim().isNotEmpty) {
        final t2 = _rules(packs, r, airports, TextDocument.fromText(e.text, senderDomain: _domain(e.from)), e.sentAt ?? reference);
        return ImportPreview(
          format: format,
          candidates: t2.candidates,
          subject: e.subject,
          pendingAttachments: pending,
          docType: t2.docType,
          templateId: t2.templateId,
        );
      }
      return ImportPreview(format: format, candidates: e.candidates, subject: e.subject, pendingAttachments: pending);
    case ImportFormat.csv || ImportFormat.xlsx:
      final sheets = format == ImportFormat.csv
          ? [const CsvReader().readBytes(r.bytes, name: r.name)]
          : const XlsxReader().read(r.bytes);
      if (sheets.isEmpty) return ImportPreview(format: format, candidates: const []);
      final index = r.sheetIndex.clamp(0, sheets.length - 1);
      final sheet = sheets[index];
      final x = TableTaskExtractor(packs, region: r.region, nlu: nlu);
      var mapping = x.detect(sheet);
      // Cách ghép đã nhớ cho bảng có cùng dòng tiêu đề (chỉ khi người dùng chưa chọn lại ở lần này).
      final detectedSig = TableTaskExtractor.signature(sheet, mapping.headerRow);
      var remembered = false;
      if (r.columns == null && r.hasHeader == null && detectedSig != null && r.savedMappings[detectedSig] != null) {
        try {
          final saved = TableMapping.applySaved(mapping, (jsonDecode(r.savedMappings[detectedSig]!) as Map).cast<String, Object?>(),
              columnCount: sheet.columnCount);
          remembered = !identical(saved, mapping);
          mapping = saved;
        } on FormatException {
          // Bỏ qua bản nhớ hỏng.
        }
      }
      if (r.hasHeader != null) mapping = TableTaskExtractor.withHeader(mapping, r.hasHeader!);
      if (r.columns != null) mapping = mapping.copyWith(columns: r.columns);
      if (r.dateOrder != null) mapping = mapping.copyWith(dateOrder: r.dateOrder);
      return ImportPreview(
        format: format,
        candidates: x.extract(sheet, mapping, source: format == ImportFormat.csv ? 'csv' : 'xlsx', now: r.now),
        sheetNames: format == ImportFormat.xlsx ? [for (final s in sheets) s.name ?? ''] : const [],
        sheetIndex: index,
        dateOrder: mapping.dateOrder,
        dateOrderAmbiguous: mapping.dateOrderAmbiguous,
        docLanguage: mapping.lang,
        table: TableInfo(
          labels: TableTaskExtractor.headerLabels(sheet, mapping.headerRow),
          columns: mapping.columns,
          hasHeader: mapping.headerRow != null,
          dataRows: sheet.rows.length - (mapping.headerRow == null ? 0 : mapping.headerRow! + 1),
          signature: TableTaskExtractor.signature(sheet, mapping.headerRow),
          remembered: remembered,
        ),
      );
    case ImportFormat.markdown:
      return ImportPreview(
        format: format,
        candidates: MarkdownDecoder(nlu: nlu, region: r.region).decode(CsvReader.decodeText(r.bytes), now: r.now),
      );
    case ImportFormat.text:
      final text = CsvReader.decodeText(r.bytes);
      final first = text.split('\n').first.trim();
      if (BcbpDecoder.looksLikeBcbp(first)) {
        return ImportPreview(format: format, candidates: const BcbpDecoder().decode(first, reference: reference) ?? const []);
      }
      // Văn bản của vé/phiếu (dán từ app khác, OCR) thì đọc bằng luật T2; không thì mỗi dòng 1 việc.
      final t2 = _rules(packs, r, airports, TextDocument.fromText(text), reference);
      if (t2.candidates.isNotEmpty) {
        return ImportPreview(format: format, candidates: t2.candidates, docType: t2.docType, templateId: t2.templateId);
      }
      return ImportPreview(format: format, candidates: _textLines(text, nlu, r));
    case ImportFormat.unsupported:
      return const ImportPreview(format: ImportFormat.unsupported, candidates: []);
  }
}

RuleExtraction _rules(List<GrammarPack> packs, ImportRequest r, AirportIndex? airports, TextDocument doc, DateTime reference) =>
    RuleEngine(packs: packs, airports: airports, region: r.region).extract(doc, reference: reference);

/// `Hãng <no-reply@mail.example.com>` → `mail.example.com`.
String? _domain(String? from) => from == null ? null : RegExp(r'@([\w.-]+)').firstMatch(from)?[1]?.toLowerCase();

/// Tệp chữ thường: mỗi dòng 1 việc, đọc ngày giờ bằng NLU như Quick Add. Có gạch đầu dòng/checkbox thì đọc như Markdown.
List<Candidate> _textLines(String text, NluEngine nlu, ImportRequest r) {
  final md = MarkdownDecoder(nlu: nlu, region: r.region).decode(text, now: r.now);
  if (md.isNotEmpty) return md;
  final ctx = NluContext(now: r.now, region: r.region);
  return [
    for (final line in text.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty))
      _fromNlu(nlu.parse(line, ctx), line),
  ];
}

Candidate _fromNlu(NluResult res, String line) {
  final w = res.when;
  return Candidate(
    kind: CandidateKind.task,
    source: 'text',
    confidence: 0.8,
    priority: res.priority,
    tags: res.tags,
    rrule: res.recurrence?.rrule,
    fields: CandidateFields(
      title: res.title.isEmpty ? line : res.title,
      due: w == null ? null : LocalTime(w.time == null ? '${w.date}' : '${w.date}T${w.time}'),
    ),
  );
}
