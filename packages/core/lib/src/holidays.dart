import 'dart:convert';

import 'civil.dart';
import 'lunar.dart';

/// Cuối tuần theo vùng (CLDR supplemental weekData: weekendStart/weekendEnd), thứ theo `DateTime.monday` = 1 … `sunday` = 7.
/// Vùng không có trong bảng hoặc null: Thứ Bảy + Chủ nhật.
Set<int> weekendDays(String? region) => switch (region?.toUpperCase()) {
      'AF' => const {DateTime.thursday, DateTime.friday},
      'IR' => const {DateTime.friday},
      'IN' || 'UG' => const {DateTime.sunday},
      'BH' || 'DZ' || 'EG' || 'IL' || 'IQ' || 'JO' || 'KW' || 'LY' || 'OM' || 'QA' || 'SA' || 'SD' || 'SY' || 'YE' =>
        const {DateTime.friday, DateTime.saturday},
      _ => const {DateTime.saturday, DateTime.sunday},
    };

/// Gói ngày lễ đã nạp trong tiến trình (app nạp gói của vùng lúc khởi động, test nạp từ tệp). Lặp "ngày làm việc" tra ở đây;
/// vùng chưa nạp thì chỉ bỏ cuối tuần.
abstract final class HolidayCalendars {
  static final Map<String, HolidayCalendar> _loaded = {};

  static void register(HolidayCalendar c) => _loaded[c.region.toUpperCase()] = c;

  static HolidayCalendar? of(String region) => _loaded[region.toUpperCase()];

  /// Chỉ cho test.
  static void clear() => _loaded.clear();
}

/// Ngày làm việc đầu tiên sau [after]: không phải cuối tuần của [region], không phải ngày nghỉ lễ của gói đã nạp cho vùng đó.
CivilDate nextWorkday(CivilDate after, String? region) {
  final weekend = weekendDays(region);
  final cal = region == null ? null : HolidayCalendars.of(region);
  var d = after.addDays(1);
  while (weekend.contains(d.weekday) || (cal?.isDayOff(d) ?? false)) {
    d = d.addDays(1);
  }
  return d;
}

/// 1 ngày lễ đã tính ra cho 1 năm.
class Holiday {
  const Holiday({required this.date, required this.id, required this.names, this.dayOff = true, this.substitute = false});
  final CivilDate date;
  /// Khóa ổn định trong gói (`new_year`, `tet`), dùng cho gợi ý và telemetry, không hiển thị.
  final String id;
  /// Tên theo mã ngôn ngữ (`vi`, `en`): dữ liệu của gói, không qua ARB (giống gói NLU).
  final Map<String, String> names;
  /// Ngày nghỉ chính thức (dùng cho lặp "ngày làm việc"); false = ngày kỷ niệm chỉ để hiển thị.
  final bool dayOff;
  /// Ngày nghỉ bù cho ngày lễ rơi vào cuối tuần.
  final bool substitute;

  /// Tên theo [lang], không có thì tiếng Anh, rồi tên đầu tiên.
  String name(String lang) => names[lang] ?? names['en'] ?? names.values.first;

  @override
  String toString() => '${date.toIso()} $id${substitute ? ' (bù)' : ''}';
}

/// Ngày lễ của 1 quốc gia, tính trên máy từ gói luật JSON (`packages/core/data/holidays/<REGION>.json`, ADR-017).
/// Luật: `fixed` (ngày/tháng), `nth_weekday` (thứ N của tháng, N = -1 là cuối), `lunar` (ngày âm, `day: "last"` = ngày cuối tháng),
/// `easter` (lệch so với Chủ nhật Phục sinh, lịch Gregory). Tùy chọn: `days` (số ngày liên tiếp), `from`/`until` (năm áp dụng),
/// `observed` (`us`: T7 → T6, CN → T2; `substitute`: T7/CN → ngày thường kế tiếp chưa là ngày lễ), `moved` (năm → ngày thay thế).
/// Cấp gói: `one_off` (ngày lễ 1 lần).
class HolidayCalendar {
  HolidayCalendar._(this.region, this.version, this._rules, this._oneOff);

  factory HolidayCalendar.parse(String source) {
    final j = jsonDecode(source) as Map<String, Object?>;
    return HolidayCalendar._(
      j['region']! as String,
      (j['version']! as num).toInt(),
      [for (final r in j['holidays']! as List<Object?>) _Rule.fromJson((r! as Map).cast<String, Object?>())],
      [
        for (final o in (j['one_off'] as List<Object?>?) ?? const [])
          Holiday(
            date: CivilDate.parse((o! as Map)['date']! as String),
            id: o['id']! as String,
            names: (o['names']! as Map).cast<String, String>(),
            dayOff: (o['day_off'] as bool?) ?? true,
          ),
      ],
    );
  }

  final String region;
  final int version;
  final List<_Rule> _rules;
  final List<Holiday> _oneOff;
  final Map<int, List<Holiday>> _cache = {};

  /// Ngày lễ có ngày nằm trong năm dương [year], theo ngày.
  List<Holiday> inYear(int year) => _cache.putIfAbsent(year, () {
        // Tính cả năm trước/sau: ngày bù của 1/1 có thể rơi vào 31/12 năm trước (US), giao thừa thuộc năm âm trước.
        final all = [for (var y = year - 1; y <= year + 1; y++) ..._compute(y)];
        return all.where((h) => h.date.year == year).toList()..sort((a, b) => a.date.compareTo(b.date));
      });

  List<Holiday> on(CivilDate d) => [for (final h in inYear(d.year)) if (h.date == d) h];

  /// Ngày nghỉ lễ chính thức (không tính cuối tuần).
  bool isDayOff(CivilDate d) => on(d).any((h) => h.dayOff);

  /// Ngày lễ trong [from, to] (gồm 2 đầu).
  List<Holiday> between(CivilDate from, CivilDate to) => [
        for (var y = from.year; y <= to.year; y++)
          for (final h in inYear(y))
            if (!h.date.isBefore(from) && !h.date.isAfter(to)) h,
      ];

  /// Ngày lễ do luật của năm [year] sinh ra (ngày có thể lệch sang năm khác), kèm ngày bù.
  List<Holiday> _compute(int year) {
    final actual = <Holiday>[];
    final observed = <(Holiday, String)>[];
    for (final r in _rules) {
      if ((r.from != null && year < r.from!) || (r.until != null && year > r.until!)) continue;
      for (final start in r.starts(year)) {
        for (var i = 0; i < r.days; i++) {
          final h = Holiday(date: start.addDays(i), id: r.id, names: r.names, dayOff: r.dayOff);
          actual.add(h);
          if (r.observed != null) observed.add((h, r.observed!));
        }
      }
    }
    actual.addAll(_oneOff.where((h) => h.date.year == year));
    final taken = {for (final h in actual) if (h.dayOff) h.date};
    final subs = <Holiday>[];
    observed.sort((a, b) => a.$1.date.compareTo(b.$1.date));
    for (final (h, kind) in observed) {
      final wd = h.date.weekday;
      if (wd != DateTime.saturday && wd != DateTime.sunday) continue;
      CivilDate d;
      if (kind == 'us') {
        d = h.date.addDays(wd == DateTime.saturday ? -1 : 1);
      } else {
        d = h.date.addDays(1);
        while (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday || taken.contains(d)) {
          d = d.addDays(1);
        }
      }
      taken.add(d);
      subs.add(Holiday(date: d, id: h.id, names: h.names, dayOff: true, substitute: true));
    }
    return [...actual, ...subs];
  }
}

class _Rule {
  _Rule({
    required this.id,
    required this.names,
    required this.rule,
    required this.dayOff,
    required this.days,
    this.observed,
    this.from,
    this.until,
    this.moved = const {},
  });

  factory _Rule.fromJson(Map<String, Object?> j) {
    final rule = (j['rule']! as Map).cast<String, Object?>();
    final type = rule['type'];
    if (!const {'fixed', 'nth_weekday', 'lunar', 'easter'}.contains(type)) {
      throw FormatException('luật ngày lễ không hỗ trợ: $type', j['id']);
    }
    final observed = j['observed'] as String?;
    if (observed != null && observed != 'us' && observed != 'substitute') throw FormatException('observed không hỗ trợ: $observed', j['id']);
    return _Rule(
      id: j['id']! as String,
      names: (j['names']! as Map).cast<String, String>(),
      rule: rule,
      dayOff: (j['day_off'] as bool?) ?? true,
      days: (j['days'] as num?)?.toInt() ?? 1,
      observed: observed,
      from: (j['from'] as num?)?.toInt(),
      until: (j['until'] as num?)?.toInt(),
      moved: {for (final e in ((j['moved'] as Map?) ?? const {}).entries) int.parse(e.key as String): CivilDate.parse(e.value as String)},
    );
  }

  final String id;
  final Map<String, String> names;
  final Map<String, Object?> rule;
  final bool dayOff;
  final int days;
  final String? observed;
  final int? from;
  final int? until;
  final Map<int, CivilDate> moved;

  int _int(String k) => (rule[k]! as num).toInt();

  /// Ngày bắt đầu của lễ do năm [year] sinh ra (lễ âm lịch: theo năm âm [year]).
  List<CivilDate> starts(int year) {
    if (moved[year] case final d?) return [d];
    switch (rule['type']) {
      case 'fixed':
        return CivilDate.isValid(year, _int('month'), _int('day')) ? [CivilDate(year, _int('month'), _int('day'))] : const [];
      case 'nth_weekday':
        final month = _int('month'), weekday = _int('weekday'), n = _int('n');
        if (n > 0) {
          final d = CivilDate(year, month, 1).nextOrSame(weekday).addDays(7 * (n - 1));
          return d.month == month ? [d] : const [];
        }
        final last = CivilDate(year, month, 1).addMonths(1).addDays(-1);
        return [last.addDays(-((last.weekday - weekday) % 7))];
      case 'easter':
        return [easterSunday(year).addDays(rule['offset'] == null ? 0 : _int('offset'))];
      case 'lunar':
        final cal = LunarCalendar(LunarSystem.fromWire(rule['calendar']! as String));
        final m = cal.monthOf(year, _int('month'));
        if (m == null) return const [];
        final day = rule['day'] == 'last' ? m.length : _int('day');
        return day <= m.length ? [m.start.addDays(day - 1)] : const [];
    }
    return const [];
  }
}

/// Chủ nhật Phục sinh theo lịch Gregory (thuật toán Meeus/Jones/Butcher).
CivilDate easterSunday(int y) {
  final a = y % 19, b = y ~/ 100, c = y % 100, d = b ~/ 4, e = b % 4;
  final f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3, h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4, k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31, day = ((h + l - 7 * m + 114) % 31) + 1;
  return CivilDate(y, month, day);
}
