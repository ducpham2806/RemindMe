import 'document.dart';

/// Loại tài liệu của bộ phân loại T2 (on-device-extraction.md §4.1). `unknown` = không đủ tín hiệu: màn Xem lại cho chọn tay.
enum DocType {
  flight, train, bus, hotel, medical, event, todoList, unknown;

  String get wire => this == todoList ? 'todo_list' : name;

  static DocType? parse(String s) => s == 'todo_list' ? todoList : values.where((v) => v.name == s).firstOrNull;
}

/// Mục `document:` của gói ngôn ngữ (`nlu/packs/<lang>.yaml`): từ khóa phân loại, anchor theo trường, giá trị hạng ghế.
/// Engine không chứa từ của ngôn ngữ nào (giống NLU).
class DocVocabulary {
  const DocVocabulary({
    this.classify = const {},
    this.anchors = const {},
    this.segments = const [],
    this.travelClasses = const {},
    this.passengerUnits = const [],
    this.codeStopwords = const {},
  });

  /// Loại → (từ khóa đã fold → trọng số).
  final Map<DocType, Map<String, int>> classify;
  /// Trường (`confirmation_code`, `seat`, `check_in`...) → nhãn in trên tài liệu.
  final Map<String, List<String>> anchors;
  /// Nhãn mở đầu 1 chặng ("Chuyến đi", "Return flight").
  final List<String> segments;
  /// Hạng ghế in trên vé (đã fold) → `economy` | `premium` | `business` | `first`.
  final Map<String, String> travelClasses;
  /// Đơn vị đếm hành khách đứng sau số ("1 người lớn", "2 adults").
  final List<String> passengerUnits;
  /// Từ in hoa dễ bị nhầm là mã đặt chỗ ("NUMBER", "TICKET").
  final Set<String> codeStopwords;

  bool get isEmpty => classify.isEmpty && anchors.isEmpty;

  factory DocVocabulary.fromMap(Map<String, Object?>? m) {
    if (m == null) return const DocVocabulary();
    String fold(Object? s) => FoldedText('$s').text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final classify = <DocType, Map<String, int>>{};
    for (final e in ((m['classify'] as Map<String, Object?>?) ?? const {}).entries) {
      final type = DocType.parse(e.key) ?? (throw FormatException('document.classify: loại không có: ${e.key}'));
      classify[type] = {for (final k in (e.value! as Map<String, Object?>).entries) fold(k.key): k.value! as int};
    }
    return DocVocabulary(
      classify: classify,
      anchors: {
        for (final e in ((m['anchors'] as Map<String, Object?>?) ?? const {}).entries)
          e.key: [for (final x in e.value! as List<Object?>) '$x'],
      },
      segments: [for (final x in (m['segments'] as List<Object?>? ?? const [])) '$x'],
      travelClasses: {
        for (final e in ((m['travel_classes'] as Map<String, Object?>?) ?? const {}).entries) fold(e.key): '${e.value}',
      },
      passengerUnits: [for (final x in (m['passenger_units'] as List<Object?>? ?? const [])) fold(x)],
      codeStopwords: {for (final x in (m['code_stopwords'] as List<Object?>? ?? const [])) '$x'.toUpperCase()},
    );
  }
}
