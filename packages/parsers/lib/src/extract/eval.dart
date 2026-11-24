import 'candidate.dart';

/// Chấm trích xuất theo on-device-extraction.md §11: % trường bắt buộc đúng, tỷ lệ "điền sai" (có giá trị nhưng sai ở trường bắt buộc
/// hoặc tùy chọn, hoặc điền vào trường vé không có). Trường tùy chọn chỉ báo cáo % đúng, không chặn.
/// So theo thứ tự candidate; chỉ so các khóa có trong expected (ví dụ `starts_at.tz` vắng thì không chấm).
class ExtractEvalReport {
  int docs = 0;
  int skipped = 0;
  int requiredTotal = 0;
  int requiredCorrect = 0;
  int optionalTotal = 0;
  int optionalCorrect = 0;
  int wrongFills = 0;
  final failures = <String>[];

  double get requiredAccuracy => requiredTotal == 0 ? 1 : requiredCorrect / requiredTotal;
  double get optionalAccuracy => optionalTotal == 0 ? 1 : optionalCorrect / optionalTotal;
  double get wrongFillRate => requiredTotal == 0 ? 0 : wrongFills / requiredTotal;

  @override
  String toString() {
    final b = StringBuffer('tài liệu $docs (bỏ qua $skipped chưa có tầng xử lý), trường bắt buộc đúng '
        '${(requiredAccuracy * 100).toStringAsFixed(1)}% ($requiredCorrect/$requiredTotal), tùy chọn ${(optionalAccuracy * 100).toStringAsFixed(1)}% '
        '($optionalCorrect/$optionalTotal), điền sai $wrongFills');
    for (final f in failures) {
      b.write('\n  ✗ $f');
    }
    return b.toString();
  }
}

/// Chấm 1 tài liệu: [expected] là nội dung `expected.json`; [actual] null = chưa có tầng xử lý loại input này.
void scoreDocument(ExtractEvalReport report, String id, Map<String, Object?> expected, List<Candidate>? actual) {
  if (actual == null) {
    report.skipped++;
    return;
  }
  report.docs++;
  final exp = (expected['candidates']! as List<Object?>).cast<Map<String, Object?>>();
  for (var i = 0; i < exp.length; i++) {
    final e = exp[i];
    final got = i < actual.length ? _flatten(actual[i].fields.toJson()) : const <String, Object?>{};
    if (i >= actual.length) report.failures.add('$id: thiếu candidate #${i + 1}');
    if (i < actual.length && e['kind'] != actual[i].kind.name) report.failures.add('$id #${i + 1}: kind ${actual[i].kind.name} ≠ ${e['kind']}');
    _flatten((e['required']! as Map).cast<String, Object?>()).forEach((path, want) {
      report.requiredTotal++;
      final have = got[path];
      if (have == want) {
        report.requiredCorrect++;
      } else {
        if (have != null) report.wrongFills++;
        report.failures.add('$id #${i + 1}: $path = ${have ?? '∅'} ≠ $want');
      }
    });
    _flatten(((e['optional'] as Map?) ?? const {}).cast<String, Object?>()).forEach((path, want) {
      report.optionalTotal++;
      final have = got[path];
      if (have == want) {
        report.optionalCorrect++;
      } else if (have != null) {
        report.wrongFills++;
        report.failures.add('$id #${i + 1}: (tùy chọn) $path = $have ≠ $want');
      }
    });
    for (final path in (e['must_not_fill'] as List<Object?>? ?? const []).cast<String>()) {
      if (got.keys.any((k) => k == path || k.startsWith('$path.'))) {
        report.wrongFills++;
        report.failures.add('$id #${i + 1}: điền vào trường không có: $path');
      }
    }
  }
}

Map<String, Object?> _flatten(Map<String, Object?> m, [String prefix = '']) => {
      for (final e in m.entries)
        if (e.value is Map)
          ..._flatten((e.value! as Map).cast<String, Object?>(), '$prefix${e.key}.')
        else if (e.value != null)
          '$prefix${e.key}': e.value,
    };
