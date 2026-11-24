import '../extract/candidate.dart';
import 'ics.dart';
import 'jsonld.dart';
import 'mime.dart';
import 'pkpass.dart';

/// Phần đính kèm chưa có decoder T0 (PDF, ảnh, xlsx/csv...): app chuyển cho tầng phù hợp (T1 OCR, PDF text layer, nhập bảng).
class PendingAttachment {
  const PendingAttachment(this.filename, this.mediaType, this.bytes);
  final String? filename;
  final String mediaType;
  final List<int> bytes;
}

/// Kết quả đọc 1 email (on-device-extraction.md §2, §8).
class EmailExtraction {
  const EmailExtraction({
    required this.subject,
    required this.from,
    required this.sentAt,
    required this.text,
    required this.candidates,
    required this.pending,
  });

  final String? subject;
  final String? from;
  final DateTime? sentAt;
  /// Thân chữ (email chuyển tiếp lồng nhau nối sau) cho tầng luật T2 khi T0 không ra gì.
  final String text;
  final List<Candidate> candidates;
  final List<PendingAttachment> pending;
}

/// Email `.eml` (chuyển tiếp hoặc chia sẻ vào app) → candidate từ JSON-LD trong HTML, `.ics`, `.pkpass` đính kèm,
/// email lồng `message/rfc822`. Cùng 1 đặt chỗ xuất hiện ở cả JSON-LD và `.ics` thì chỉ giữ bản đầu (JSON-LD đủ trường hơn).
class EmailDecoder {
  const EmailDecoder();

  static const _maxDepth = 4;

  EmailExtraction decode(List<int> bytes, {required DateTime reference}) =>
      _decode(MimeMessage.parse(bytes), reference: reference, depth: 0);

  EmailExtraction _decode(MimeMessage msg, {required DateTime reference, required int depth}) {
    final ref = msg.sentAt ?? reference;
    final candidates = <Candidate>[];
    final pending = <PendingAttachment>[];
    final texts = <String>[msg.text];

    for (final html in msg.htmlBodies) {
      candidates.addAll(const JsonLdDecoder().decodeHtml(html));
    }
    // Lịch mời dạng text/calendar nằm trong multipart/alternative (không phải đính kèm) cũng đọc.
    for (final p in msg.root.leaves) {
      if (p.mediaType == 'text/calendar' && !msg.attachments.contains(p)) candidates.addAll(const IcsDecoder().decode(p.text));
    }
    for (final a in msg.attachments) {
      final name = a.filename?.toLowerCase() ?? '';
      if (a.message != null) {
        if (depth >= _maxDepth) continue;
        final inner = _decode(MimeMessage.fromPart(a.message!), reference: ref, depth: depth + 1);
        candidates.addAll(inner.candidates);
        pending.addAll(inner.pending);
        texts.add(inner.text);
      } else if (a.mediaType == 'text/calendar' || a.mediaType == 'application/ics' || name.endsWith('.ics')) {
        candidates.addAll(const IcsDecoder().decode(a.text));
      } else if (a.mediaType == 'application/vnd.apple.pkpass' || name.endsWith('.pkpass')) {
        candidates.addAll(const PkpassDecoder().decodeZip(a.body, reference: ref));
      } else if (_inlineDecoration(a)) {
        continue;
      } else {
        pending.add(PendingAttachment(a.filename, a.mediaType, a.body));
      }
    }
    return EmailExtraction(
      subject: msg.subject,
      from: msg.from,
      sentAt: msg.sentAt,
      text: texts.where((t) => t.trim().isNotEmpty).join('\n\n'),
      candidates: dedupeCandidates(candidates),
      pending: pending,
    );
  }

  /// Logo, ảnh chữ ký nhúng trong HTML (`Content-ID`, `inline`): không đưa sang OCR.
  static bool _inlineDecoration(MimePart p) =>
      p.mediaType.startsWith('image/') && (p.disposition == 'inline' || p.headers.containsKey('content-id')) && p.filename == null;
}

/// Bỏ candidate trùng: cùng thời điểm bắt đầu (so theo UTC nếu cả 2 biết offset) và cùng mã đặt chỗ/số chuyến,
/// hoặc 1 bên là sự kiện lịch (.ics) trùng giờ với 1 đặt chỗ. Giữ bản xuất hiện trước.
List<Candidate> dedupeCandidates(List<Candidate> list) {
  final out = <Candidate>[];
  for (final c in list) {
    if (!out.any((k) => _same(k, c))) out.add(c);
  }
  return out;
}

bool _same(Candidate a, Candidate b) {
  final sa = a.fields.startsAt ?? a.fields.checkIn, sb = b.fields.startsAt ?? b.fields.checkIn;
  if (sa == null || sb == null || !_sameInstant(sa, sb)) return false;
  final fa = a.fields, fb = b.fields;
  if (fa.confirmationCode != null && fa.confirmationCode == fb.confirmationCode) return true;
  if (fa.number != null && fa.number == fb.number && fa.carrierCode == fb.carrierCode) return true;
  if (fa.title != null && fa.title == fb.title) return true;
  final oneIsCalendar = (a.kind == CandidateKind.event) != (b.kind == CandidateKind.event);
  return oneIsCalendar;
}

bool _sameInstant(LocalTime a, LocalTime b) {
  if (a.hasTime != b.hasTime) return false;
  final ua = _utcMinutes(a), ub = _utcMinutes(b);
  if (ua != null && ub != null) return ua == ub;
  return a.local == b.local;
}

int? _utcMinutes(LocalTime t) {
  if (!t.hasTime || t.utcOffsetMinutes == null) return null;
  return DateTime.parse('${t.local}:00Z').millisecondsSinceEpoch ~/ 60000 - t.utcOffsetMinutes!;
}
