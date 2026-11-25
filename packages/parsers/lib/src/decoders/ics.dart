import '../extract/candidate.dart';

/// Decoder iCalendar (RFC 5545) tối giản cho nhập lịch (E1.1): VEVENT → sự kiện, VTODO → việc, kèm RRULE và VALARM.
/// Không phụ thuộc ngôn ngữ; không gọi mạng. VTIMEZONE bị bỏ qua: TZID thường là tên IANA (Google, Apple, Outlook mới);
/// TZID kiểu Windows ("SE Asia Standard Time") giữ nguyên để tầng sau ánh xạ.
class IcsDecoder {
  const IcsDecoder();

  List<Candidate> decode(String source) {
    final lines = _unfold(source);
    final out = <Candidate>[];
    final stack = <String>[];
    var props = <_Prop>[];
    var alarms = <int>[];
    var alarmProps = <_Prop>[];
    for (final raw in lines) {
      final p = _Prop.parse(raw);
      if (p == null) continue;
      if (p.name == 'BEGIN') {
        stack.add(p.value.toUpperCase());
        if (p.value.toUpperCase() == 'VEVENT' || p.value.toUpperCase() == 'VTODO') {
          props = [];
          alarms = [];
        } else if (p.value.toUpperCase() == 'VALARM') {
          alarmProps = [];
        }
        continue;
      }
      if (p.name == 'END') {
        final comp = stack.isEmpty ? '' : stack.removeLast();
        if (comp == 'VALARM') {
          final m = _alarmMinutes(alarmProps);
          if (m != null) alarms.add(m);
        } else if (comp == 'VEVENT' || comp == 'VTODO') {
          final c = _toCandidate(comp, props, alarms);
          if (c != null) out.add(c);
        }
        continue;
      }
      if (stack.isEmpty) continue;
      if (stack.last == 'VALARM') {
        alarmProps.add(p);
      } else if (stack.last == 'VEVENT' || stack.last == 'VTODO') {
        props.add(p);
      }
    }
    return out;
  }

  Candidate? _toCandidate(String comp, List<_Prop> props, List<int> alarms) {
    _Prop? get(String n) => props.where((p) => p.name == n).firstOrNull;
    final status = get('STATUS')?.value.toUpperCase();
    if (status == 'CANCELLED') return null;
    final start = _time(get('DTSTART'));
    var end = _time(get('DTEND'));
    if (end == null && start != null && get('DURATION') != null) end = _plusDuration(start, get('DURATION')!.value);
    final summary = _text(get('SUMMARY')?.value);
    final location = _text(get('LOCATION')?.value);
    final rrule = get('RRULE')?.value.replaceFirst(RegExp('^RRULE:', caseSensitive: false), '');
    final isTodo = comp == 'VTODO';
    return Candidate(
      kind: isTodo ? CandidateKind.task : CandidateKind.event,
      source: 'ics',
      confidence: 0.99,
      rrule: rrule == null || rrule.isEmpty ? null : rrule,
      reminderOffsetsMinutes: (alarms.toSet().toList()..sort()),
      notes: _text(get('DESCRIPTION')?.value),
      fields: CandidateFields(
        title: summary,
        locationText: location,
        startsAt: start,
        endsAt: isTodo ? null : end,
        due: isTodo ? _time(get('DUE')) : null,
      ),
    );
  }

  /// DTSTART;TZID=Asia/Ho_Chi_Minh:20261205T103000 · DTSTART:20261205T033000Z · DTSTART;VALUE=DATE:20261205
  static LocalTime? _time(_Prop? p) {
    if (p == null) return null;
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$').firstMatch(p.value.trim());
    if (m == null) return null;
    final date = '${m[1]}-${m[2]}-${m[3]}';
    if (m[4] == null) return LocalTime(date);
    final local = '${date}T${m[4]}:${m[5]}';
    if (m[7] == 'Z') return LocalTime(local, tz: 'Etc/UTC', utcOffsetMinutes: 0);
    return LocalTime(local, tz: p.params['TZID']);
  }

  /// DURATION: P1D, PT1H30M, P1DT2H.
  static LocalTime? _plusDuration(LocalTime start, String duration) {
    final m = RegExp(r'^P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$').firstMatch(duration.trim());
    if (m == null) return null;
    final minutes = (int.tryParse(m[1] ?? '') ?? 0) * 7 * 1440 +
        (int.tryParse(m[2] ?? '') ?? 0) * 1440 +
        (int.tryParse(m[3] ?? '') ?? 0) * 60 +
        (int.tryParse(m[4] ?? '') ?? 0);
    final base = DateTime.parse(start.hasTime ? '${start.local}:00Z' : '${start.local}T00:00:00Z').add(Duration(minutes: minutes));
    String two(int v) => v.toString().padLeft(2, '0');
    final d = '${base.year.toString().padLeft(4, '0')}-${two(base.month)}-${two(base.day)}';
    return LocalTime(start.hasTime ? '${d}T${two(base.hour)}:${two(base.minute)}' : d, tz: start.tz, utcOffsetMinutes: start.utcOffsetMinutes);
  }

  /// TRIGGER:-PT15M (trước giờ bắt đầu) → -15 (quy ước `offset_minutes`: âm = trước). Nhắc theo thời điểm tuyệt đối hoặc sau giờ bỏ qua.
  static int? _alarmMinutes(List<_Prop> props) {
    final t = props.where((p) => p.name == 'TRIGGER').firstOrNull;
    if (t == null || t.params['VALUE']?.toUpperCase() == 'DATE-TIME' || (t.params['RELATED']?.toUpperCase() == 'END')) return null;
    final m = RegExp(r'^(-)?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$').firstMatch(t.value.trim());
    if (m == null) return null;
    final minutes = (int.tryParse(m[2] ?? '') ?? 0) * 7 * 1440 +
        (int.tryParse(m[3] ?? '') ?? 0) * 1440 +
        (int.tryParse(m[4] ?? '') ?? 0) * 60 +
        (int.tryParse(m[5] ?? '') ?? 0);
    if (m[1] == null && minutes != 0) return null;
    return -minutes;
  }

  /// Bỏ escape TEXT của RFC 5545.
  static String? _text(String? v) {
    if (v == null) return null;
    final s = v.replaceAllMapped(RegExp(r'\\([nN\\;,])'), (m) => switch (m[1]) { 'n' || 'N' => '\n', final c => c! }).trim();
    return s.isEmpty ? null : s;
  }

  /// Dòng dài bị gấp: dòng sau bắt đầu bằng 1 khoảng trắng/tab thì nối vào dòng trước.
  static List<String> _unfold(String s) {
    final out = <String>[];
    for (final line in s.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n')) {
      if ((line.startsWith(' ') || line.startsWith('\t')) && out.isNotEmpty) {
        out[out.length - 1] += line.substring(1);
      } else if (line.isNotEmpty) {
        out.add(line);
      }
    }
    return out;
  }
}

class _Prop {
  _Prop(this.name, this.params, this.value);
  final String name;
  final Map<String, String> params;
  final String value;

  /// NAME;P1=v1;P2="v:2":VALUE (dấu ':' trong tham số có ngoặc kép không tách).
  static _Prop? parse(String line) {
    var inQuote = false;
    var colon = -1;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') inQuote = !inQuote;
      if (c == ':' && !inQuote) {
        colon = i;
        break;
      }
    }
    if (colon < 0) return null;
    final head = line.substring(0, colon).split(';');
    final params = <String, String>{};
    for (final p in head.skip(1)) {
      final eq = p.indexOf('=');
      if (eq > 0) params[p.substring(0, eq).toUpperCase()] = p.substring(eq + 1).replaceAll('"', '');
    }
    return _Prop(head.first.toUpperCase(), params, line.substring(colon + 1));
  }
}
