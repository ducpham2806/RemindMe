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

  ImportRequest copyWith({String? dateOrder, int? sheetIndex}) => ImportRequest(
        name: name,
        bytes: bytes,
        packSources: packSources,
        now: now,
        airportsTsv: airportsTsv,
        region: region,
        dateOrder: dateOrder ?? this.dateOrder,
        sheetIndex: sheetIndex ?? this.sheetIndex,
      );
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

/// Giải mã tệp thành đề xuất. Thuần Dart, không đụng Flutter: chạy được trong `Isolate.run`.
ImportPreview decodeImport(ImportRequest r) {
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
        final t2 = _rules(packs, r, TextDocument.fromText(e.text, senderDomain: _domain(e.from)), e.sentAt ?? reference);
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
      if (r.dateOrder != null) mapping = mapping.copyWith(dateOrder: r.dateOrder);
      return ImportPreview(
        format: format,
        candidates: x.extract(sheet, mapping, source: format == ImportFormat.csv ? 'csv' : 'xlsx', now: r.now),
        sheetNames: format == ImportFormat.xlsx ? [for (final s in sheets) s.name ?? ''] : const [],
        sheetIndex: index,
        dateOrder: mapping.dateOrder,
        dateOrderAmbiguous: mapping.dateOrderAmbiguous,
        docLanguage: mapping.lang,
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
      final t2 = _rules(packs, r, TextDocument.fromText(text), reference);
      if (t2.candidates.isNotEmpty) {
        return ImportPreview(format: format, candidates: t2.candidates, docType: t2.docType, templateId: t2.templateId);
      }
      return ImportPreview(format: format, candidates: _textLines(text, nlu, r));
    case ImportFormat.unsupported:
      return const ImportPreview(format: ImportFormat.unsupported, candidates: []);
  }
}

RuleExtraction _rules(List<GrammarPack> packs, ImportRequest r, TextDocument doc, DateTime reference) => RuleEngine(
      packs: packs,
      airports: r.airportsTsv == null ? null : AirportIndex.parse(r.airportsTsv!),
      region: r.region,
    ).extract(doc, reference: reference);

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
