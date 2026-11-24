import 'package:remindme_core/remindme_core.dart';

import 'pack.dart';
import 'result.dart';

const _rruleDays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// NLU luật (voice-and-text-input.md §5). Engine không chứa từ ngữ của ngôn ngữ nào: mọi từ nằm trong [GrammarPack].
/// [packs]: gói chính trước, gói phụ sau (câu pha 2 ngôn ngữ: gói phụ chạy trên phần gói chính chưa hiểu).
class NluEngine {
  NluEngine(this.packs) : assert(packs.isNotEmpty);
  final List<GrammarPack> packs;

  static final _tagRe = RegExp(r'(?<![\p{L}\p{N}])#([\p{L}\p{N}_-]+)', unicode: true);
  static final _prioRe = RegExp(r'(?<![\p{L}\p{N}!])(!{1,3})(?![\p{L}\p{N}!])', unicode: true);

  /// Tách nhiều việc theo liên từ của gói ("và", "rồi", "and", "then") chỉ khi mọi phần đều có thời điểm và tiêu đề riêng;
  /// "Mua sữa và bánh" vẫn là 1 việc, "every Monday and Wednesday" không bị tách (liên từ nằm trong đoạn đã hiểu).
  List<NluResult> parseAll(String text, NluContext ctx) {
    final whole = parse(text, ctx);
    final conj = {for (final p in packs) ...p.conjunctions}.toList()..sort((a, b) => b.length.compareTo(a.length));
    if (conj.isEmpty) return [whole];
    final re = RegExp('[,;]?\\s+(?:${conj.map(RegExp.escape).join('|')})\\s+', caseSensitive: false, unicode: true);
    final cuts = [for (final m in re.allMatches(text)) if (!whole.spans.any((s) => s.overlaps(m.start, m.end))) m];
    if (cuts.isEmpty) return [whole];
    final pieces = <String>[];
    var pos = 0;
    for (final m in cuts) {
      pieces.add(text.substring(pos, m.start));
      pos = m.end;
    }
    pieces.add(text.substring(pos));
    final results = [for (final p in pieces) parse(p, ctx)];
    final ok = results.every((r) => (r.when != null || r.recurrence != null) && r.title.isNotEmpty);
    return ok ? results : [whole];
  }

  NluResult parse(String text, NluContext ctx) {
    final f = _Facts();
    final spans = <NluSpan>[];

    bool free(int s, int e) => !spans.any((x) => x.overlaps(s, e));
    void take(int s, int e, SpanKind k, GrammarPack? pack) {
      var start = s;
      final pre = pack?.prepositionRe?.firstMatch(text.substring(0, s));
      if (pre != null && free(pre.start, s)) start = pre.start;
      spans.add(NluSpan(start, e, k));
    }

    for (final m in _tagRe.allMatches(text)) {
      f.tags.add(m[1]!);
      take(m.start, m.end, SpanKind.tag, null);
    }
    for (final m in _prioRe.allMatches(text)) {
      if (f.priority != null) break;
      f.priority = m[1]!.length;
      take(m.start, m.end, SpanKind.priority, null);
    }

    for (final pack in packs) {
      for (final p in pack.patterns) {
        for (final m in p.regex.allMatches(text)) {
          if (!free(m.start, m.end)) continue;
          if (_guarded(pack, text, m)) continue;
          final kind = _apply(pack, p, m, f);
          if (kind != null) take(m.start, m.end, kind, pack);
        }
      }
    }

    // Từ đệm đầu câu ("nhắc tôi", "remind me to").
    GrammarPack? fillerPack;
    for (final pack in packs) {
      final m = pack.fillerRe?.firstMatch(text);
      if (m != null && m.end > m.start && free(m.start, m.end)) {
        spans.add(NluSpan(m.start, m.end, SpanKind.filler));
        fillerPack = pack;
        break;
      }
    }

    final (resolved, ambiguities) = _resolve(f, ctx);
    spans.sort((a, b) => a.start.compareTo(b.start));
    var title = _title(text, spans);
    // "remind me at 6 to leave" → sau khi bỏ giờ còn "to leave": bỏ từ nối của từ đệm.
    final tail = fillerPack?.fillerTailRe?.firstMatch(title);
    if (tail != null) title = _title(title.substring(tail.end), const []);
    return NluResult(
      title: title,
      when: resolved,
      recurrence: f.recurrence(),
      tags: f.tags,
      priority: f.priority,
      ambiguities: ambiguities,
      spans: spans,
    );
  }

  // ------------------------------------------------------------------ áp từng mẫu

  /// Từ trùng tên riêng ("Mai") viết hoa giữa câu: không hiểu là ngày.
  bool _guarded(GrammarPack pack, String text, RegExpMatch m) {
    final word = GrammarPack.norm(m[0]!);
    if (!pack.properNounGuard.any((g) => word == g || word.endsWith(' $g') || word.startsWith('$g '))) return false;
    final before = text.substring(0, m.start).trimRight();
    final sentenceStart = before.isEmpty || RegExp(r'[.!?:]$').hasMatch(before);
    final first = m[0]!.characters0;
    return !sentenceStart && first != first.toLowerCase();
  }

  SpanKind? _apply(GrammarPack pack, NluPattern p, RegExpMatch m, _Facts f) {
    String? g(String name) => m.groupNames.contains(name) ? m.namedGroup(name) : null;
    int? num(String name) {
      final s = g(name);
      return s == null ? null : pack.number(s);
    }

    final v = p.value;
    final vn = v is Map ? v['n'] as int? : (v is int ? v : null);
    final vu = v is Map ? v['u'] as String? : (v is String ? v : null);
    int? month(String name) {
      final s = g(name);
      return s == null ? null : (pack.months[GrammarPack.norm(s)] ?? pack.number(s));
    }

    String? part() {
      final s = g('part');
      return s == null ? null : GrammarPack.norm(s);
    }

    int? rel() {
      final s = g('rel');
      if (s != null) return pack.relDays[GrammarPack.norm(s)];
      return g('this') != null ? 0 : null;
    }

    switch (p.type) {
      case PatternType.hm || PatternType.half || PatternType.minus || PatternType.past || PatternType.fixedTime:
        if (f.hour != null) return null;
        int h, min;
        if (p.type == PatternType.fixedTime) {
          final t = CivilTime.parse(p.value! as String);
          (h, min) = (t.hour, t.minute);
          f.explicit24 = true;
        } else {
          final hh = num('h');
          if (hh == null || hh > 24) return null;
          h = hh;
          final mm = p.type == PatternType.half ? 30 : (num('m') ?? 0);
          if (mm > 59) return null;
          if (p.type == PatternType.minus) {
            final total = (h * 60 - mm) % (24 * 60);
            (h, min) = (total ~/ 60, total % 60);
          } else {
            min = mm;
          }
          final raw = g('h')!;
          f.explicit24 = hh == 0 || hh > 12 || (raw.length == 2 && raw.startsWith('0'));
        }
        f.hour = h;
        f.minute = min;
        final ap = g('ap');
        if (ap != null) f.ap = pack.meridiem[GrammarPack.norm(ap)];
        f.timePart = part();
        f.timePack = pack;
        final r = rel();
        if (r != null && f.relDays == null) f.relDays = r;
        return SpanKind.time;

      case PatternType.part:
        final pt = part();
        if (pt == null || f.part != null) return null;
        f.part = pt;
        f.partPack = pack;
        final r = rel() ?? pack.dayParts[pt]?.rel;
        if (r != null && f.relDays == null) f.relDays = r;
        return SpanKind.part;

      case PatternType.relday:
        if (f.hasDate) return null;
        final r = rel();
        if (r == null) return null;
        f.relDays = r;
        final pt = part();
        if (pt != null && f.part == null) {
          f.part = pt;
          f.partPack = pack;
        }
        return SpanKind.date;

      case PatternType.weekday:
        if (f.hasDate) return null;
        final w = g('w');
        if (w == null) return null;
        f.weekday = pack.weekdays[GrammarPack.norm(w)];
        final next = g('next');
        f.weekdayMod = next != null ? pack.nextModifiers[GrammarPack.norm(next)] : (g('this') != null ? 'this' : null);
        return f.weekday == null ? null : SpanKind.date;

      case PatternType.nextWeek:
        if (f.hasDate) return null;
        f.relDays = 7;
        return SpanKind.date;

      case PatternType.dayMonth:
        if (f.hasDate) return null;
        final d = num('d');
        final mo = month('mo');
        if (d == null || mo == null || d > 31 || mo > 12) return null;
        f.day = d;
        f.month = mo;
        f.year = _year(g('y'));
        return SpanKind.date;

      case PatternType.numericDate:
        if (f.hasDate) return null;
        final a = int.tryParse(g('a') ?? ''), b = int.tryParse(g('b') ?? '');
        if (a == null || b == null) return null;
        f.numeric = (a, b);
        f.year = _year(g('y'));
        f.datePack = pack;
        return SpanKind.date;

      case PatternType.inDuration:
        if (f.hasDate || f.hour != null) return null;
        final n = num('n') ?? vn ?? 1;
        final u = pack.units[GrammarPack.norm(g('u') ?? '')] ?? vu;
        if (u == null) return null;
        f.inDuration = u == 'fortnight' ? (14 * n, 'day') : (n, u);
        return SpanKind.date;

      case PatternType.daily || PatternType.dailyPart:
        if (f.freq != null) return null;
        f.freq = 'DAILY';
        final pt = part();
        if (pt != null && f.part == null) {
          f.part = pt;
          f.partPack = pack;
        }
        return SpanKind.recurrence;

      case PatternType.weekly || PatternType.weeklyDays:
        if (f.freq != null) return null;
        final days = <int>[];
        final list = g('list');
        if (list != null) {
          for (final tok in RegExp(r'[\p{L}\p{N}]+(?:\s+[\p{L}\p{N}]+)?', unicode: true).allMatches(list)) {
            final w = pack.weekdays[GrammarPack.norm(tok[0]!)] ?? pack.weekdays[GrammarPack.norm(tok[0]!.split(RegExp(r'\s+')).first)];
            if (w != null && !days.contains(w)) days.add(w);
          }
          if (days.isEmpty) return null;
        }
        final w = g('w');
        if (w != null) {
          final d = pack.weekdays[GrammarPack.norm(w)];
          if (d == null) return null;
          days.add(d);
        }
        f.freq = 'WEEKLY';
        f.byDay = days..sort();
        return SpanKind.recurrence;

      case PatternType.weekdays:
        if (f.freq != null) return null;
        f.freq = 'WEEKLY';
        f.byDay = [1, 2, 3, 4, 5];
        return SpanKind.recurrence;

      case PatternType.everyN:
        if (f.freq != null) return null;
        var n = num('n') ?? vn;
        var u = pack.units[GrammarPack.norm(g('u') ?? '')] ?? vu;
        final w = g('w');
        if (n == null || n < 1) return null;
        if (u == 'fortnight') (n, u) = (n * 2, 'week');
        if (w != null) {
          final d = pack.weekdays[GrammarPack.norm(w)];
          if (d == null) return null;
          f.freq = 'WEEKLY';
          f.byDay = [d];
        } else {
          f.freq = switch (u) { 'hour' => 'HOURLY', 'day' => 'DAILY', 'week' => 'WEEKLY', 'month' => 'MONTHLY', 'year' => 'YEARLY', _ => null };
          if (f.freq == null) return null;
        }
        f.interval = n;
        return SpanKind.recurrence;

      case PatternType.monthlyDay:
        if (f.freq != null) return null;
        final d = num('d');
        if (d == null || d < 1 || d > 31) return null;
        f.freq = 'MONTHLY';
        f.byMonthDay = d;
        return SpanKind.recurrence;

      case PatternType.monthly || PatternType.yearly:
        if (f.freq != null) return null;
        f.freq = p.type == PatternType.monthly ? 'MONTHLY' : 'YEARLY';
        return SpanKind.recurrence;

      case PatternType.lunarMonthly || PatternType.lunarYearly:
        if (f.freq != null || pack.lunarSystem == null) return null;
        final d = num('d') ?? vn;
        final mo = p.type == PatternType.lunarYearly ? month('mo') : null;
        if (d == null || d < 1 || d > 30 || (p.type == PatternType.lunarYearly && (mo == null || mo > 12))) return null;
        f.freq = 'LUNAR';
        f.lunar = {'system': pack.lunarSystem, 'month': ?mo, 'day': d};
        return SpanKind.recurrence;
    }
  }

  static int? _year(String? y) {
    if (y == null) return null;
    final n = int.parse(y);
    return y.length == 2 ? 2000 + n : n;
  }

  // ------------------------------------------------------------------ ghép thành thời điểm

  (When?, List<Ambiguity>) _resolve(_Facts f, NluContext ctx) {
    final today = ctx.today;
    final amb = <Ambiguity>[];

    // Giờ: danh sách lựa chọn (1 phần tử nếu không mơ hồ).
    var times = <CivilTime>[];
    var timeChosen = 0;
    final partName = f.timePart ?? f.part;
    final part = partName == null ? null : (f.partPack ?? f.timePack ?? packs.first).dayParts[partName] ??
        packs.map((p) => p.dayParts[partName]).firstWhere((x) => x != null, orElse: () => null);
    if (f.hour != null) {
      var h = f.hour!;
      final m = f.minute ?? 0;
      if (h == 24) h = 0;
      if (f.ap != null) {
        h = h % 12 + (f.ap == 'pm' ? 12 : 0);
        times = [CivilTime(h, m)];
      } else if (part != null && h <= 12) {
        final cands = [h % 12, h % 12 + 12];
        times = [CivilTime(cands.firstWhere(part.contains, orElse: () => h), m)];
      } else if (!f.explicit24 && h >= 1 && h <= 11) {
        times = [CivilTime(h, m), CivilTime(h + 12, m)];
        // Mặc định: 1-6 giờ là buổi chiều (ít ai hẹn 3 giờ sáng), 7-11 là buổi sáng.
        timeChosen = h <= 6 ? 1 : 0;
      } else {
        times = [CivilTime(h, m)];
      }
    } else if (part != null) {
      times = [part.defaultTime];
    }

    // Khoảng thời gian tính từ bây giờ ("30 phút nữa", "in 2 hours").
    if (f.inDuration case (final n, final unit) when unit == 'minute' || unit == 'hour') {
      final at = ctx.now.add(unit == 'minute' ? Duration(minutes: n) : Duration(hours: n));
      return (When(CivilDate.of(at), CivilTime.of(at)), amb);
    }

    // Ngày.
    var dates = <CivilDate>[];
    var dateChosen = 0;
    AmbiguityKind? dateAmbKind;
    if (f.numeric case (final a, final b)) {
      final order = (f.datePack ?? packs.first).dateOrderFor(ctx.region);
      CivilDate? mk(int d, int mo) => CivilDate.isValid(f.year ?? today.year, mo, d) ? _inferYear(d, mo, f.year, today) : null;
      final dmy = mk(a, b), mdy = mk(b, a);
      if (order == 'mdy' && mdy != null) {
        dates = [mdy];
      } else if (order == 'dmy' && dmy != null) {
        dates = [dmy];
      } else if (order == null && dmy != null && mdy != null && dmy != mdy) {
        dates = [dmy, mdy];
        dateAmbKind = AmbiguityKind.dateOrder;
      } else if (dmy ?? mdy case final d?) {
        dates = [d];
      }
    } else if (f.day != null && f.month != null) {
      if (CivilDate.isValid(f.year ?? today.year, f.month!, f.day!) || f.year == null) {
        final d = _inferYear(f.day!, f.month!, f.year, today);
        if (d != null) dates = [d];
      }
    } else if (f.relDays != null) {
      dates = [today.addDays(f.relDays!)];
    } else if (f.weekday != null) {
      final w = f.weekday!;
      final nextWeekStart = today.addDays(8 - today.weekday);
      switch (f.weekdayMod) {
        case 'next_week':
          dates = [nextWeekStart.nextOrSame(w)];
        case 'next_ambiguous':
          final coming = today.addDays(1).nextOrSame(w), following = nextWeekStart.nextOrSame(w);
          dates = coming == following ? [coming] : [coming, following];
          dateChosen = dates.length - 1;
          if (dates.length > 1) dateAmbKind = AmbiguityKind.nextWeekday;
        case 'this':
          dates = [today.nextOrSame(w)];
        default:
          if (w == today.weekday) {
            dates = [today, today.addDays(7)];
            final laterToday = times.isNotEmpty && times[timeChosen].compareTo(ctx.nowTime) > 0;
            dateChosen = laterToday ? 0 : 1;
            dateAmbKind = AmbiguityKind.sameWeekday;
          } else {
            dates = [today.nextOrSame(w)];
          }
      }
    } else if (f.inDuration case (final n, final unit)) {
      dates = [switch (unit) { 'week' => today.addDays(7 * n), 'month' => today.addMonths(n), _ => today.addDays(n) }];
    }

    // Lặp mà chưa có ngày: lần đầu tiên từ hôm nay.
    if (dates.isEmpty && f.freq != null && f.freq != 'LUNAR') {
      final first = _firstOccurrence(f, today, times.isEmpty ? null : times[timeChosen], ctx.nowTime);
      if (first != null) dates = [first];
    }

    // Chỉ có giờ: hôm nay nếu giờ chưa qua, không thì ngày mai (tính riêng cho từng lựa chọn giờ).
    if (dates.isEmpty && times.isNotEmpty) {
      final options = [for (final t in times) When(t.compareTo(ctx.nowTime) > 0 ? today : today.addDays(1), t)];
      if (options.length > 1) amb.add(Ambiguity(AmbiguityKind.meridiem, options, timeChosen));
      return (options[timeChosen], amb);
    }
    if (dates.isEmpty) return (null, amb);

    final t = times.isEmpty ? null : times[timeChosen];
    if (dateAmbKind != null) amb.add(Ambiguity(dateAmbKind, [for (final d in dates) When(d, t)], dateChosen));
    final d = dates[dateChosen];
    if (times.length > 1) amb.add(Ambiguity(AmbiguityKind.meridiem, [for (final x in times) When(d, x)], timeChosen));
    return (When(d, t), amb);
  }

  /// Ngày/tháng không có năm: năm nay, hoặc năm sau nếu đã qua.
  static CivilDate? _inferYear(int d, int mo, int? year, CivilDate today) {
    if (year != null) return CivilDate.isValid(year, mo, d) ? CivilDate(year, mo, d) : null;
    for (final y in [today.year, today.year + 1]) {
      if (CivilDate.isValid(y, mo, d) && !CivilDate(y, mo, d).isBefore(today)) return CivilDate(y, mo, d);
    }
    return CivilDate.isValid(today.year + 1, mo, d) ? CivilDate(today.year + 1, mo, d) : null;
  }

  static CivilDate? _firstOccurrence(_Facts f, CivilDate today, CivilTime? time, CivilTime now) {
    final passedToday = time != null && time.compareTo(now) <= 0;
    bool ok(CivilDate d) => d != today || !passedToday;
    for (var i = 0; i < 400; i++) {
      final d = today.addDays(i);
      final hit = switch (f.freq) {
        'DAILY' => true,
        'WEEKLY' => f.byDay.isEmpty || f.byDay.contains(d.weekday),
        'MONTHLY' => f.byMonthDay == null || d.day == f.byMonthDay,
        _ => i == 0,
      };
      if (hit && ok(d)) return d;
    }
    return null;
  }

  // ------------------------------------------------------------------ tiêu đề

  static String _title(String text, List<NluSpan> spans) {
    final b = StringBuffer();
    var pos = 0;
    for (final s in spans) {
      if (s.start > pos) b.write(text.substring(pos, s.start));
      b.write(' ');
      if (s.end > pos) pos = s.end;
    }
    if (pos < text.length) b.write(text.substring(pos));
    var t = b.toString().replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1');
    t = t.replaceAll(RegExp(r'^[\s,.;:\-–—]+|[\s,;:\-–—]+$'), '');
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }
}

class _Facts {
  final tags = <String>[];
  int? priority;
  // giờ
  int? hour, minute;
  String? ap, timePart;
  GrammarPack? timePack;
  bool explicit24 = false;
  // buổi
  String? part;
  GrammarPack? partPack;
  // ngày
  int? relDays, weekday, day, month, year;
  String? weekdayMod;
  (int, int)? numeric;
  GrammarPack? datePack;
  (int, String)? inDuration;
  // lặp
  String? freq;
  int interval = 1;
  List<int> byDay = const [];
  int? byMonthDay;
  Map<String, Object?>? lunar;

  bool get hasDate => relDays != null || weekday != null || day != null || numeric != null || inDuration != null;

  RecurrenceSpec? recurrence() {
    if (freq == null) return null;
    if (freq == 'LUNAR') return RecurrenceSpec.calendar(lunar!);
    final parts = ['FREQ=$freq', if (interval > 1) 'INTERVAL=$interval'];
    if (byDay.isNotEmpty) parts.add('BYDAY=${byDay.map((d) => _rruleDays[d - 1]).join(',')}');
    if (byMonthDay != null) parts.add('BYMONTHDAY=$byMonthDay');
    return RecurrenceSpec.rrule(parts.join(';'));
  }
}

extension on String {
  String get characters0 => isEmpty ? '' : this[0];
}
