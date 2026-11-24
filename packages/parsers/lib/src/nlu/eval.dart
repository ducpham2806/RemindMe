import 'dart:convert';

import 'engine.dart';
import 'result.dart';

/// Chấm bộ câu theo voice-and-text-input.md §7.
/// - Đúng ý (intent): tiêu đề + thời điểm + lặp khớp (và tag/ưu tiên nếu fixture có).
/// - Sai nguy hiểm: thời điểm sai mà không hiện chip mơ hồ có chứa đáp án đúng.
class NluEvalReport {
  int total = 0;
  int correct = 0;
  int dangerous = 0;
  final failures = <String>[];
  final byDialect = <String, (int, int)>{};

  double get accuracy => total == 0 ? 0 : correct / total;
  double get dangerousRate => total == 0 ? 0 : dangerous / total;

  @override
  String toString() {
    final b = StringBuffer('intent ${(accuracy * 100).toStringAsFixed(1)}% ($correct/$total), '
        'sai nguy hiểm ${(dangerousRate * 100).toStringAsFixed(1)}% ($dangerous)');
    byDialect.forEach((k, v) => b.write('\n  $k: ${v.$1}/${v.$2}'));
    for (final f in failures) {
      b.write('\n  ✗ $f');
    }
    return b.toString();
  }
}

NluEvalReport evaluateNlu(NluEngine engine, String fixturesJson) {
  final data = jsonDecode(fixturesJson) as Map<String, Object?>;
  final report = NluEvalReport();
  for (final raw in (data['cases']! as List<Object?>).cast<Map<String, Object?>>()) {
    final text = raw['text']! as String;
    final region = raw['region'] as String?;
    final ctx = NluContext(now: DateTime.parse(raw['now']! as String), region: region);
    final exp = raw['expect'];
    final expected = exp is List ? exp.cast<Map<String, Object?>>() : [exp! as Map<String, Object?>];
    final got = engine.parseAll(text, ctx);
    report.total++;

    var ok = got.length == expected.length;
    var danger = false;
    final why = <String>[];
    if (!ok) why.add('số việc ${got.length} ≠ ${expected.length}');
    for (var i = 0; ok && i < expected.length; i++) {
      final e = expected[i], r = got[i];
      if (r.title != e['title']) {
        ok = false;
        why.add('tiêu đề "${r.title}" ≠ "${e['title']}"');
      }
      final whenAny = (e['when_any'] as List<Object?>?)?.cast<String>();
      final wantWhen = e['when'] as String?;
      final gotWhen = r.when?.toString();
      final whenOk = whenAny != null ? whenAny.contains(gotWhen) : gotWhen == wantWhen;
      if (!whenOk) {
        ok = false;
        why.add('thời điểm $gotWhen ≠ ${whenAny ?? wantWhen}');
        final truth = whenAny ?? [?wantWhen];
        final offered = r.ambiguities.any((a) => a.options.any((o) => truth.contains(o.toString())));
        if (!offered) danger = true;
      }
      final wantRec = e['rec'];
      final gotRec = r.recurrence == null ? null : (r.recurrence!.rrule ?? r.recurrence!.calendar);
      if (_canon(gotRec) != _canon(wantRec)) {
        ok = false;
        why.add('lặp ${jsonEncode(gotRec)} ≠ ${jsonEncode(wantRec)}');
      }
      for (final k in (e['ambiguous'] as List<Object?>? ?? const []).cast<String>()) {
        if (!r.ambiguities.any((a) => a.kind.name == k)) {
          ok = false;
          why.add('thiếu chip mơ hồ $k');
        }
      }
      if (e.containsKey('tags') && jsonEncode(r.tags) != jsonEncode(e['tags'])) {
        ok = false;
        why.add('tags ${r.tags}');
      }
      if (e.containsKey('priority') && r.priority != e['priority']) {
        ok = false;
        why.add('ưu tiên ${r.priority}');
      }
    }
    if (ok) report.correct++;
    if (danger) report.dangerous++;
    final dialect = raw['dialect'] as String? ?? region ?? '-';
    final (c, t) = report.byDialect[dialect] ?? (0, 0);
    report.byDialect[dialect] = (c + (ok ? 1 : 0), t + 1);
    if (!ok) report.failures.add('${raw['id']} "$text": ${why.join('; ')}${danger ? ' [NGUY HIỂM]' : ''}');
  }
  return report;
}

/// JSON không phụ thuộc thứ tự key.
String _canon(Object? v) => switch (v) {
      Map<Object?, Object?> m => '{${(m.keys.map((k) => '$k').toList()..sort()).map((k) => '$k:${_canon(m[k])}').join(',')}}',
      List<Object?> l => '[${l.map(_canon).join(',')}]',
      _ => jsonEncode(v),
    };
