import 'dart:convert';

import '../extract/html_text.dart';

/// Đọc email MIME (RFC 5322/2045-2047/2231) tối giản, Dart thuần, không phụ thuộc gói ngoài: multipart lồng nhau,
/// base64, quoted-printable, tiêu đề mã hóa `=?utf-8?B?...?=`, tên file RFC 2231, `message/rfc822` (email chuyển tiếp dạng đính kèm).
/// Không kiểm chữ ký, không tải ảnh từ xa, không chạy gì trong HTML.
class MimePart {
  MimePart._(this.headers, this.mediaType, this.params, this.children, this.body, this.message);

  /// Tên header viết thường → giá trị đã gộp dòng (chưa giải mã RFC 2047). Header lặp lại giữ cái đầu.
  final Map<String, String> headers;
  /// `text/html`, `multipart/mixed`... (viết thường).
  final String mediaType;
  final Map<String, String> params;
  final List<MimePart> children;
  /// Nội dung đã giải mã transfer-encoding (lá); rỗng với multipart.
  final List<int> body;
  /// Email lồng (`message/rfc822`).
  final MimePart? message;

  bool get isMultipart => mediaType.startsWith('multipart/');
  bool get isText => mediaType.startsWith('text/');

  String? header(String name) {
    final v = headers[name.toLowerCase()];
    return v == null ? null : decodeHeaderWords(v);
  }

  String? get disposition => _splitParams(headers['content-disposition'] ?? '').$1.toLowerCase().nullIfEmpty;

  String? get filename {
    final d = _splitParams(headers['content-disposition'] ?? '').$2;
    final n = d['filename'] ?? params['name'];
    return n == null ? null : decodeHeaderWords(n).trim().nullIfEmpty;
  }

  /// Phần đính kèm: có tên file hoặc `attachment`, hoặc không phải text.
  bool get isAttachment =>
      !isMultipart && message == null && (disposition == 'attachment' || (filename != null && disposition != 'inline') || !isText);

  /// Nội dung chữ theo `charset` (thiếu charset: thử UTF-8 rồi windows-1252).
  String get text => decodeCharset(body, params['charset']);

  /// Mọi phần lá theo thứ tự xuất hiện (không đi vào email lồng).
  Iterable<MimePart> get leaves sync* {
    if (isMultipart) {
      for (final c in children) {
        yield* c.leaves;
      }
    } else {
      yield this;
    }
  }

  static MimePart parse(List<int> bytes) => _parse(String.fromCharCodes(bytes), 0);

  static MimePart _parse(String raw, int depth) {
    final (headerText, bodyText) = _splitHead(raw);
    final headers = <String, String>{};
    String? last;
    for (final line in headerText.split(RegExp(r'\r?\n'))) {
      if (line.isEmpty) continue;
      if ((line.startsWith(' ') || line.startsWith('\t')) && last != null) {
        headers[last] = '${headers[last]} ${line.trim()}';
        continue;
      }
      final colon = line.indexOf(':');
      if (colon <= 0) continue;
      final name = line.substring(0, colon).trim().toLowerCase();
      if (headers.containsKey(name)) {
        last = null;
        continue;
      }
      headers[name] = line.substring(colon + 1).trim();
      last = name;
    }
    final (type, params) = _splitParams(headers['content-type'] ?? 'text/plain');
    final mediaType = type.toLowerCase().nullIfEmpty ?? 'text/plain';
    final cte = (headers['content-transfer-encoding'] ?? '').trim().toLowerCase();

    if (mediaType.startsWith('multipart/') && params['boundary'] != null && depth < 16) {
      final parts = <MimePart>[];
      for (final chunk in _splitMultipart(bodyText, params['boundary']!)) {
        parts.add(_parse(chunk, depth + 1));
      }
      return MimePart._(headers, mediaType, params, parts, const [], null);
    }
    final body = switch (cte) {
      'base64' => _base64(bodyText),
      'quoted-printable' => _quotedPrintable(bodyText),
      _ => bodyText.codeUnits,
    };
    final nested = mediaType == 'message/rfc822' && depth < 16 ? _parse(String.fromCharCodes(body), depth + 1) : null;
    return MimePart._(headers, mediaType, params, const [], body, nested);
  }

  static (String, String) _splitHead(String raw) {
    final m = RegExp(r'\r?\n\r?\n').firstMatch(raw);
    if (m == null) {
      // Không có dòng trống: toàn bộ là header nếu dòng đầu giống header, ngược lại là thân.
      return RegExp(r'^[!-9;-~]+:').hasMatch(raw) ? (raw, '') : ('', raw);
    }
    return (raw.substring(0, m.start), raw.substring(m.end));
  }

  static List<String> _splitMultipart(String body, String boundary) {
    final re = RegExp('(?:^|\\r?\\n)--${RegExp.escape(boundary)}(--)?[ \\t]*(?:\\r?\\n|\$)');
    final out = <String>[];
    int? start;
    for (final m in re.allMatches(body)) {
      if (start != null) out.add(body.substring(start, m.start));
      if (m[1] != null) return out;
      start = m.end;
    }
    if (start != null && start < body.length) out.add(body.substring(start));
    return out;
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

/// `text/html; charset="utf-8"; name*=UTF-8''%E1%BB%87.ics` → ('text/html', {charset: utf-8, name: ...}).
(String, Map<String, String>) _splitParams(String value) {
  final pieces = <String>[];
  final b = StringBuffer();
  var quoted = false;
  for (var i = 0; i < value.length; i++) {
    final c = value[i];
    if (c == '"') quoted = !quoted;
    if (c == ';' && !quoted) {
      pieces.add(b.toString());
      b.clear();
    } else {
      b.write(c);
    }
  }
  pieces.add(b.toString());
  final params = <String, String>{};
  final continued = <String, Map<int, (String, bool)>>{};
  for (final p in pieces.skip(1)) {
    final eq = p.indexOf('=');
    if (eq <= 0) continue;
    var name = p.substring(0, eq).trim().toLowerCase();
    var v = p.substring(eq + 1).trim();
    if (v.length >= 2 && v.startsWith('"') && v.endsWith('"')) v = v.substring(1, v.length - 1).replaceAll(r'\"', '"');
    final m = RegExp(r'^(.+?)(?:\*(\d+))?(\*)?$').firstMatch(name)!;
    if (m[2] == null && m[3] == null) {
      params[name] = v;
      continue;
    }
    name = m[1]!;
    (continued[name] ??= {})[int.tryParse(m[2] ?? '0') ?? 0] = (v, m[3] != null);
  }
  for (final e in continued.entries) {
    final keys = e.value.keys.toList()..sort();
    String? charset;
    final bytes = <int>[];
    for (final k in keys) {
      var (v, encoded) = e.value[k]!;
      if (encoded) {
        if (k == keys.first) {
          final q = RegExp(r"^([^']*)'[^']*'(.*)$").firstMatch(v);
          if (q != null) {
            charset = q[1];
            v = q[2]!;
          }
        }
        bytes.addAll(_percentDecode(v));
      } else {
        bytes.addAll(utf8.encode(v));
      }
    }
    params[e.key] = decodeCharset(bytes, charset);
  }
  return (pieces.first.trim(), params);
}

List<int> _percentDecode(String s) {
  final out = <int>[];
  for (var i = 0; i < s.length; i++) {
    if (s[i] == '%' && i + 2 < s.length) {
      final b = int.tryParse(s.substring(i + 1, i + 3), radix: 16);
      if (b != null) {
        out.add(b);
        i += 2;
        continue;
      }
    }
    out.add(s.codeUnitAt(i) & 0xFF);
  }
  return out;
}

List<int> _base64(String s) {
  var clean = s.replaceAll(RegExp(r'[^A-Za-z0-9+/]'), '');
  clean = clean.padRight((clean.length + 3) ~/ 4 * 4, '=');
  try {
    return base64.decode(clean);
  } on FormatException {
    return const [];
  }
}

List<int> _quotedPrintable(String s) {
  final out = <int>[];
  final src = s.replaceAll(RegExp(r'[ \t]+(?=\r?\n)'), '');
  for (var i = 0; i < src.length; i++) {
    final c = src.codeUnitAt(i);
    if (c == 0x3D /* = */) {
      if (i + 1 < src.length && src[i + 1] == '\n') {
        i += 1;
        continue;
      }
      if (i + 2 < src.length && src[i + 1] == '\r' && src[i + 2] == '\n') {
        i += 2;
        continue;
      }
      if (i + 2 < src.length) {
        final b = int.tryParse(src.substring(i + 1, i + 3), radix: 16);
        if (b != null) {
          out.add(b);
          i += 2;
          continue;
        }
      }
    }
    out.add(c & 0xFF);
  }
  return out;
}

/// Giải mã theo charset khai báo. Hỗ trợ UTF-8, US-ASCII, ISO-8859-1, windows-1252 (charset khác: UTF-8 rồi windows-1252).
String decodeCharset(List<int> bytes, String? charset) {
  final cs = (charset ?? '').trim().toLowerCase().replaceAll('_', '-');
  switch (cs) {
    case 'utf-8' || 'utf8':
      return utf8.decode(bytes, allowMalformed: true);
    case 'iso-8859-1' || 'latin1' || 'latin-1' || 'us-ascii' || 'ascii':
      return latin1.decode(bytes, allowInvalid: true);
    case 'windows-1252' || 'cp1252':
      return _cp1252(bytes);
    default:
      try {
        return utf8.decode(bytes);
      } on FormatException {
        return _cp1252(bytes);
      }
  }
}

const _cp1252High = [
  0x20AC, 0x81, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, 0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x8D, 0x017D, 0x8F, //
  0x90, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, 0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x9D, 0x017E, 0x0178,
];

String _cp1252(List<int> bytes) =>
    String.fromCharCodes([for (final b in bytes) b >= 0x80 && b < 0xA0 ? _cp1252High[b - 0x80] : b]);

/// Tiêu đề RFC 2047 (`=?UTF-8?B?...?=`, `=?iso-8859-1?Q?...?=`); phần không mã hóa mà là UTF-8 thô (RFC 6532) cũng giải đúng.
String decodeHeaderWords(String value) {
  var v = value;
  if (v.codeUnits.any((c) => c > 0x7F && c <= 0xFF)) {
    try {
      v = utf8.decode(v.codeUnits);
    } on FormatException {
      // giữ nguyên (latin1)
    }
  }
  final word = RegExp(r'=\?([^?]+)\?([bBqQ])\?([^?]*)\?=');
  // Khoảng trắng giữa 2 từ mã hóa liền nhau bị bỏ.
  v = v.replaceAllMapped(RegExp(r'(\?=)\s+(?==\?)'), (m) => m[1]!);
  return v.replaceAllMapped(word, (m) {
    final charset = m[1]!.split('*').first;
    final bytes = m[2]!.toLowerCase() == 'b'
        ? _base64(m[3]!)
        : _quotedPrintable(m[3]!.replaceAll('_', ' '));
    return decodeCharset(bytes, charset);
  });
}

/// Email đã đọc: tiêu đề, người gửi, thời điểm gửi, thân chữ (để T2 chạy sau) và cây phần.
class MimeMessage {
  MimeMessage._(this.root);
  factory MimeMessage.parse(List<int> bytes) => MimeMessage._(MimePart.parse(bytes));
  factory MimeMessage.fromPart(MimePart part) => MimeMessage._(part);

  final MimePart root;

  String? get subject => root.header('subject');
  String? get from => root.header('from');
  DateTime? get sentAt => parseRfc5322Date(root.headers['date']);

  /// Phần HTML (không phải đính kèm), theo thứ tự.
  List<String> get htmlBodies => [for (final p in root.leaves) if (p.mediaType == 'text/html' && !_attached(p)) p.text];
  String? get plainBody => [for (final p in root.leaves) if (p.mediaType == 'text/plain' && !_attached(p)) p.text].firstOrNull;

  /// Thân dạng chữ: `text/plain` nếu có, không thì HTML bỏ thẻ.
  String get text => plainBody ?? htmlBodies.map(htmlToText).join('\n\n');

  List<MimePart> get attachments => [
        for (final p in root.leaves)
          if (p.message != null || _attached(p)) p,
      ];

  static bool _attached(MimePart p) => p.message != null || p.isAttachment;
}

const _months = {'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12};

/// `Tue, 24 Nov 2026 10:05:00 +0700` → DateTime UTC. Múi giờ chữ cũ (GMT, UT, EST...) chỉ nhận GMT/UT/Z.
DateTime? parseRfc5322Date(String? s) {
  if (s == null) return null;
  final m = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})[a-z]*\s+(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|GMT|UT|UTC|Z)?')
      .firstMatch(s);
  if (m == null) return null;
  final month = _months[m[2]!.toLowerCase()];
  if (month == null) return null;
  var year = int.parse(m[3]!);
  if (year < 100) year += year < 50 ? 2000 : 1900;
  final local = DateTime.utc(year, month, int.parse(m[1]!), int.parse(m[4]!), int.parse(m[5]!), int.tryParse(m[6] ?? '') ?? 0);
  final z = m[7];
  if (z == null || !z.startsWith(RegExp('[+-]'))) return local;
  final sign = z.startsWith('-') ? -1 : 1;
  final offset = Duration(hours: int.parse(z.substring(1, 3)), minutes: int.parse(z.substring(3, 5))) * sign;
  return local.subtract(offset);
}
