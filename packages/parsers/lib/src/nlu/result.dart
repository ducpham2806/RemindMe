import 'package:remindme_core/remindme_core.dart';

/// Ngữ cảnh phân tích: giờ hiện tại trên máy (giờ tường, không múi giờ) và vùng của người dùng (quyết định dd/mm hay mm/dd).
class NluContext {
  const NluContext({required this.now, this.region});
  final DateTime now;
  /// ISO 3166-1 alpha-2 hoặc null (không biết: ngày số mơ hồ thì hỏi).
  final String? region;

  CivilDate get today => CivilDate.of(now);
  CivilTime get nowTime => CivilTime.of(now);
}

enum SpanKind { date, time, part, recurrence, tag, priority, filler }

/// Đoạn văn bản engine đã hiểu (để tô màu/đổi thành chip). [start, end) theo chỉ số trong chuỗi gốc.
class NluSpan {
  const NluSpan(this.start, this.end, this.kind);
  final int start;
  final int end;
  final SpanKind kind;
  bool overlaps(int s, int e) => s < end && e > start;
  @override
  String toString() => '$kind[$start,$end)';
}

/// Thời điểm: ngày + giờ (null = cả ngày). Cùng kiểu với recurrence engine ở core.
typedef When = CivilDateTime;

enum AmbiguityKind {
  /// '03/04' khi không biết vùng: 3/4 hay 4/3.
  dateOrder,
  /// "thứ 6" khi hôm nay là thứ 6: hôm nay hay tuần sau.
  sameWeekday,
  /// en "next Friday": thứ 6 tới hay thứ 6 tuần sau.
  nextWeekday,
  /// "3 giờ" không có buổi/am-pm: 3:00 hay 15:00.
  meridiem,
}

/// Chỗ mơ hồ: app hiện chip có các lựa chọn, [chosen] là mặc định đang dùng trong [NluResult.when].
class Ambiguity {
  const Ambiguity(this.kind, this.options, this.chosen);
  final AmbiguityKind kind;
  final List<When> options;
  final int chosen;
  @override
  String toString() => '$kind$options@$chosen';
}

/// Lặp lại, cùng dạng cột bảng `recurrences` (data-model.md): kind rrule | calendar | after_completion.
class RecurrenceSpec {
  const RecurrenceSpec.rrule(String this.rrule)
      : kind = 'rrule',
        calendar = null;
  const RecurrenceSpec.calendar(Map<String, Object?> this.calendar)
      : kind = 'calendar',
        rrule = null;

  final String kind;
  final String? rrule;
  final Map<String, Object?>? calendar;

  Map<String, Object?> toPayload() => {'kind': kind, 'rrule': ?rrule, 'calendar': ?calendar};

  @override
  bool operator ==(Object other) =>
      other is RecurrenceSpec && other.kind == kind && other.rrule == rrule && other.calendar.toString() == calendar.toString();
  @override
  int get hashCode => Object.hash(kind, rrule, calendar.toString());
  @override
  String toString() => rrule ?? 'calendar$calendar';
}

class NluResult {
  const NluResult({
    required this.title,
    this.when,
    this.recurrence,
    this.tags = const [],
    this.priority,
    this.ambiguities = const [],
    this.spans = const [],
  });

  final String title;
  final When? when;
  final RecurrenceSpec? recurrence;
  /// Từ `#tag` (không có dấu #): app khớp với tên list/tag của người dùng.
  final List<String> tags;
  /// 1-3 từ "!", "!!", "!!!".
  final int? priority;
  final List<Ambiguity> ambiguities;
  final List<NluSpan> spans;

  /// Item lặp "8h sáng mỗi ngày" kêu theo giờ nơi đang đứng (reminder-engine.md §5).
  bool get suggestsFloating => recurrence != null;

  @override
  String toString() => 'NluResult("$title", when: $when, rec: $recurrence, tags: $tags, prio: $priority, amb: $ambiguities)';
}
