import 'package:remindme_core/remindme_core.dart';
import 'package:yaml/yaml.dart';

import '../engine/vocabulary.dart';

/// Loại mẫu (ngữ nghĩa do engine định nghĩa; từ ngữ nằm trong gói). Xem `nlu/packs/README.md`.
enum PatternType {
  // giờ
  hm, half, minus, past, fixedTime,
  // ngày
  relday, weekday, dayMonth, numericDate, inDuration, nextWeek,
  // buổi
  part,
  // lặp
  daily, dailyPart, weekly, weeklyDays, weekdays, everyN, monthlyDay, monthly, yearly, lunarMonthly, lunarYearly;

  static PatternType parse(String s) =>
      values.firstWhere((v) => v.name == s, orElse: () => throw FormatException('type không hỗ trợ: $s'));
}

class DayPart {
  const DayPart({required this.from, required this.to, required this.defaultTime, this.rel});
  /// Khung giờ [from, to] (gồm 2 đầu); from > to nghĩa là qua nửa đêm (đêm 22-4).
  final int from;
  final int to;
  final CivilTime defaultTime;
  /// Buổi có sẵn ngày tương đối ("tonight", "tối nay" viết liền 1 từ): 0 = hôm nay.
  final int? rel;

  bool contains(int h) => from <= to ? h >= from && h <= to : h >= from || h <= to;
}

class NluPattern {
  NluPattern(this.type, this.regex, {this.value});
  final PatternType type;
  final RegExp regex;
  /// Tham số cố định của mẫu (ví dụ fixedTime '12:00', lunarMonthly ngày 15).
  final Object? value;
}

/// Gói ngữ pháp 1 ngôn ngữ (dữ liệu, không phải code). Định dạng: `packages/parsers/nlu/packs/README.md`.
class GrammarPack {
  GrammarPack._({
    required this.lang,
    required this.lunarSystem,
    required this.fillers,
    required this.prepositions,
    required this.conjunctions,
    required this.numbers,
    required this.relDays,
    required this.weekdays,
    required this.months,
    required this.dayParts,
    required this.meridiem,
    required this.units,
    required this.nextModifiers,
    required this.properNounGuard,
    required this.dateOrderDefault,
    required this.dateOrderByRegion,
    required this.patterns,
    required this.prepositionRe,
    required this.fillerRe,
    required this.fillerTailRe,
    required this.tableColumns,
    required this.tablePriority,
    required this.tableDone,
    required this.document,
  });

  final String lang;
  /// Hệ âm lịch của gói ('lunar_vi' với vi): "rằm", "mùng 1". null = gói không có mẫu âm lịch.
  final String? lunarSystem;
  final List<String> fillers;
  final List<String> prepositions;
  final List<String> conjunctions;
  final Map<String, int> numbers;
  final Map<String, int> relDays;
  /// từ → thứ ISO (1 = thứ Hai).
  final Map<String, int> weekdays;
  final Map<String, int> months;
  final Map<String, DayPart> dayParts;
  /// từ → 'am' | 'pm'.
  final Map<String, String> meridiem;
  /// từ → 'minute' | 'hour' | 'day' | 'week' | 'month'.
  final Map<String, String> units;
  /// từ chỉ "tuần sau": 'next_week' (chắc chắn tuần sau) | 'next_ambiguous' (en "next Friday": có thể là thứ 6 tới).
  final Map<String, String> nextModifiers;
  /// Từ trùng tên riêng ("Mai"): viết hoa giữa câu thì không hiểu là ngày.
  final Set<String> properNounGuard;
  final String? dateOrderDefault;
  final Map<String, String> dateOrderByRegion;
  /// Theo thứ tự chạy: lặp → giờ → ngày → buổi.
  final List<NluPattern> patterns;
  final RegExp? prepositionRe;
  final RegExp? fillerRe;
  final RegExp? fillerTailRe;
  /// Nhập bảng: trường (`title`, `date`...) → tên cột đã [foldForSearch].
  final Map<String, List<String>> tableColumns;
  /// Giá trị cột Ưu tiên (đã fold) → 1..3.
  final Map<String, int> tablePriority;
  /// Giá trị cột Trạng thái nghĩa là đã xong (đã fold).
  final Set<String> tableDone;
  /// Đọc tài liệu (tầng luật T2): mục `document:` của gói.
  final DocVocabulary document;

  static String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Thứ tự ngày số cho vùng: 'dmy' | 'mdy' | 'ymd'; null = không biết (hỏi khi mơ hồ).
  String? dateOrderFor(String? region) => region == null ? dateOrderDefault : (dateOrderByRegion[region] ?? dateOrderDefault);

  int? number(String s) => int.tryParse(s) ?? numbers[norm(s)];

  factory GrammarPack.fromYaml(String source) => GrammarPack.fromMap(_plain(loadYaml(source)) as Map<String, Object?>);

  factory GrammarPack.fromMap(Map<String, Object?> m) {
    List<String> strs(String k) => [for (final x in (m[k] as List<Object?>? ?? const [])) norm(x! as String)];
    Map<String, V> map<V>(String k, V Function(Object?) f) =>
        {for (final e in (m[k] as Map<Object?, Object?>? ?? const {}).entries) norm(e.key! as String): f(e.value)};
    Map<String, int> ints(String k) => map(k, (v) => v! as int);

    final numbers = ints('numbers');
    final relDays = ints('relative_days');
    final weekdays = ints('weekdays');
    final months = ints('months');
    final weekdayListTokens = ints('weekday_list_tokens');
    final meridiem = map('meridiem', (v) => v! as String);
    final units = map('units', (v) => v! as String);
    final nextModifiers = map('next_modifiers', (v) => v! as String);
    final dayParts = map('day_parts', (v) {
      final p = v! as Map<String, Object?>;
      final r = (p['range']! as List<Object?>).cast<int>();
      return DayPart(from: r[0], to: r[1], defaultTime: CivilTime.parse(p['default']! as String), rel: p['rel'] as int?);
    });
    final thisWords = strs('this_words');
    final ordinal = m['ordinal_suffix'] as String? ?? '';
    final listSeparators = strs('list_separators');

    String alt(Iterable<String> words) {
      final sorted = words.toSet().toList()..sort((a, b) => b.length.compareTo(a.length));
      return sorted.map((w) => RegExp.escape(w).replaceAll(' ', r'\s+')).join('|');
    }

    final weekdayTok = alt([...weekdays.keys, ...weekdayListTokens.keys]);
    final classes = <String, String>{
      'num': r'\d{1,2}' '${numbers.isEmpty ? '' : '|${alt(numbers.keys)}'}',
      'year': r'\d{4}',
      'weekday': alt(weekdays.keys),
      'month': alt(months.keys),
      'mon': '${alt(months.keys)}|\\d{1,2}${numbers.isEmpty ? '' : '|${alt(numbers.keys)}'}',
      'relday': alt(relDays.keys),
      'daypart': alt(dayParts.keys),
      'this': alt(thisWords),
      'ap': alt(meridiem.keys),
      'unit': alt(units.keys),
      'next': alt(nextModifiers.keys),
      'ord': ordinal,
      'wdlist': '(?:$weekdayTok)(?:\\s*(?:${alt(listSeparators)})\\s*(?:$weekdayTok))+',
    };

    RegExp compile(String template) {
      final body = template.replaceAllMapped(RegExp(r'\{([a-z]\w*)(?::(\w+))?\}'), (x) {
        final cls = classes[x[1]] ?? (throw FormatException('lớp không có: {${x[1]}}', template));
        if (cls.isEmpty) throw FormatException('lớp {${x[1]}} rỗng trong gói', template);
        return x[2] == null ? '(?:$cls)' : '(?<${x[2]}>$cls)';
      });
      // Ranh giới từ theo Unicode (\b của Dart chỉ hiểu ASCII, sai với chữ có dấu).
      return RegExp('(?<![\\p{L}\\p{N}])(?:$body)(?![\\p{L}\\p{N}])', caseSensitive: false, unicode: true);
    }

    final patterns = <NluPattern>[];
    for (final section in const ['recurrence', 'times', 'dates', 'parts']) {
      for (final p in (m[section] as List<Object?>? ?? const [])) {
        final e = p! as Map<String, Object?>;
        patterns.add(NluPattern(PatternType.parse(e['type']! as String), compile(e['re']! as String), value: e['value']));
      }
    }

    final table = (m['table'] as Map<String, Object?>?) ?? const {};
    final tableColumns = {
      for (final e in ((table['columns'] as Map<String, Object?>?) ?? const {}).entries)
        e.key: [for (final x in (e.value! as List<Object?>)) foldForSearch('$x')],
    };

    final fillers = strs('fillers');
    final tails = strs('filler_tails');
    final preps = strs('prepositions');
    final weekdaysAll = {...weekdays, ...weekdayListTokens};
    return GrammarPack._(
      lang: m['lang']! as String,
      lunarSystem: m['lunar_system'] as String?,
      fillers: fillers,
      prepositions: preps,
      conjunctions: strs('conjunctions'),
      numbers: numbers,
      relDays: relDays,
      weekdays: weekdaysAll,
      months: months,
      dayParts: dayParts,
      meridiem: meridiem,
      units: units,
      nextModifiers: nextModifiers,
      properNounGuard: strs('proper_noun_guard').toSet(),
      dateOrderDefault: (m['date_order'] as Map<Object?, Object?>?)?['default'] as String?,
      dateOrderByRegion: {
        for (final e in (((m['date_order'] as Map<Object?, Object?>?)?['regions'] as Map<Object?, Object?>?) ?? const {}).entries)
          e.key! as String: e.value! as String,
      },
      patterns: patterns,
      prepositionRe: preps.isEmpty
          ? null
          : RegExp('(?<![\\p{L}\\p{N}])(?:${alt(preps)})\\s*\$', caseSensitive: false, unicode: true),
      fillerRe: fillers.isEmpty
          ? null
          : RegExp('^\\s*(?:${alt(fillers)})(?![\\p{L}\\p{N}])[\\s,:]*', caseSensitive: false, unicode: true),
      tableColumns: tableColumns,
      tablePriority: {
        for (final e in ((table['priority'] as Map<String, Object?>?) ?? const {}).entries) foldForSearch(e.key): e.value! as int,
      },
      tableDone: {for (final x in (table['done'] as List<Object?>? ?? const [])) foldForSearch('$x')},
      document: DocVocabulary.fromMap(m['document'] as Map<String, Object?>?),
      fillerTailRe: tails.isEmpty
          ? null
          : RegExp('^\\s*(?:${alt(tails)})(?![\\p{L}\\p{N}])\\s*', caseSensitive: false, unicode: true),
    );
  }

  static Object? _plain(Object? y) => switch (y) {
        YamlMap m => {for (final e in m.entries) '${e.key}': _plain(e.value)},
        YamlList l => [for (final x in l) _plain(x)],
        _ => y,
      };
}
