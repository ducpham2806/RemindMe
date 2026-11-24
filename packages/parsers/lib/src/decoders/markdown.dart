import 'package:remindme_core/remindme_core.dart';
import 'package:yaml/yaml.dart';

import '../extract/candidate.dart';
import '../nlu/engine.dart';
import '../nlu/result.dart';

/// Markdown → việc (on-device-extraction.md §7). `- [ ]`/`- [x]` là việc (không có ô nào thì mọi gạch đầu dòng là việc);
/// heading là tên list; dòng thụt lề dưới 1 việc là việc con (checklist). Hiểu cú pháp Obsidian Tasks (emoji và dạng Dataview
/// `[due:: ...]`) và front-matter YAML `due`, `tags`. Dòng không có ngày dạng máy đọc được thì chạy NLU theo gói ngôn ngữ (nếu có).
class MarkdownDecoder {
  const MarkdownDecoder({this.nlu, this.region});

  final NluEngine? nlu;
  final String? region;

  static final _item = RegExp(r'^([ \t]*)(?:[-*+]|\d{1,9}[.)])[ \t]+(?:\[([^\]])\][ \t]+)?(.*)$');
  static final _heading = RegExp(r'^(#{1,6})[ \t]+(.+?)[ \t]*#*[ \t]*$');
  static final _fence = RegExp(r'^[ \t]*(```|~~~)');

  List<Candidate> decode(String source, {required DateTime now}) {
    var text = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text.startsWith('﻿')) text = text.substring(1);
    final (front, body) = _frontMatter(text);
    // Khối code (``` / ~~~) không chứa việc.
    final lines = <String>[];
    String? fence;
    for (final line in body.split('\n')) {
      final f = _fence.firstMatch(line);
      if (f != null && (fence == null || fence == f[1])) {
        fence = fence == null ? f[1] : null;
        continue;
      }
      if (fence == null) lines.add(line);
    }
    final hasCheckbox = lines.any((l) => _item.firstMatch(l)?[2] != null);

    final out = <_Draft>[];
    final headings = <int, String>{};
    _Draft? parent;
    var parentIndent = 0;
    for (final line in lines) {
      final h = _heading.firstMatch(line);
      if (h != null) {
        final level = h[1]!.length;
        headings.removeWhere((k, _) => k >= level);
        headings[level] = _inline(h[2]!);
        parent = null;
        continue;
      }
      final m = _item.firstMatch(line);
      if (m == null) {
        if (line.trim().isEmpty) continue;
        // Dòng thường (không thụt lề) kết thúc danh sách con.
        if (!line.startsWith(RegExp(r'[ \t]'))) parent = null;
        continue;
      }
      final indent = m[1]!.replaceAll('\t', '    ').length;
      final box = m[2];
      final content = m[3]!.trim();
      if (content.isEmpty) continue;
      final isTask = box != null || !hasCheckbox;
      if (parent != null && indent > parentIndent) {
        if (box == '-') continue;
        parent.checklist.add(ChecklistEntry(_inline(_stripFields(content)), done: box == 'x' || box == 'X'));
        continue;
      }
      parent = null;
      if (!isTask || box == '-') continue; // [-] = đã hủy
      final d = _Draft(content, done: box == 'x' || box == 'X', list: headings.isEmpty ? null : headings[headings.keys.reduce((a, b) => a > b ? a : b)]);
      out.add(d);
      parent = d;
      parentIndent = indent;
    }
    return [for (final d in out) _toCandidate(d, front, now, hasCheckbox)];
  }

  Candidate _toCandidate(_Draft d, _Front front, DateTime now, bool fromCheckbox) {
    final f = _Fields.parse(d.raw);
    var title = _inline(f.rest);
    var due = f.due ?? f.scheduled ?? f.start;
    var time = f.time;
    var rrule = f.recurrence == null ? null : obsidianRecurrenceToRrule(f.recurrence!);
    var priority = f.priority;
    final tags = [...front.tags, ...f.tags];
    if (due == null && time == null && rrule == null && nlu != null) {
      final r = nlu!.parse(title, NluContext(now: now, region: region));
      if ((r.when != null || r.recurrence != null) && r.title.isNotEmpty) {
        title = r.title;
        due = r.when?.date;
        time = r.when?.time;
        rrule = r.recurrence?.rrule;
        priority ??= r.priority;
        tags.addAll(r.tags);
      }
    }
    due ??= front.due;
    final notes = f.recurrence != null && rrule == null ? '🔁 ${f.recurrence}' : null;
    return Candidate(
      kind: CandidateKind.task,
      source: 'md',
      confidence: fromCheckbox ? 0.95 : 0.8,
      done: d.done || f.doneOn != null,
      priority: priority,
      tags: {for (final t in tags) t}.toList(),
      listName: d.list,
      checklist: d.checklist,
      rrule: rrule,
      notes: notes,
      fields: CandidateFields(
        title: title,
        due: due == null ? null : LocalTime(time == null ? '$due' : '${due}T$time'),
      ),
    );
  }

  static (_Front, String) _frontMatter(String text) {
    final m = RegExp(r'^---[ \t]*\n([\s\S]*?)\n(?:---|\.\.\.)[ \t]*(?:\n|$)').firstMatch(text);
    if (m == null) return (const _Front(), text);
    Object? y;
    try {
      y = loadYaml(m[1]!);
    } on Object {
      return (const _Front(), text.substring(m.end));
    }
    if (y is! Map) return (const _Front(), text.substring(m.end));
    final rawTags = y['tags'] ?? y['tag'];
    final tags = <String>[
      if (rawTags is List)
        for (final t in rawTags) '$t'.replaceFirst('#', '').trim()
      else if (rawTags != null)
        for (final t in '$rawTags'.split(RegExp(r'[,\s]+'))) t.replaceFirst('#', '').trim(),
    ].where((t) => t.isNotEmpty).toList();
    final dueRaw = '${y['due'] ?? ''}';
    final dm = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(dueRaw);
    final due = dm != null && CivilDate.isValid(int.parse(dm[1]!), int.parse(dm[2]!), int.parse(dm[3]!))
        ? CivilDate(int.parse(dm[1]!), int.parse(dm[2]!), int.parse(dm[3]!))
        : null;
    return (_Front(tags: tags, due: due), text.substring(m.end));
  }

  /// Bỏ định dạng inline: **đậm**, _nghiêng_, ~~gạch~~, `code`, [chữ](url), [[Trang|bí danh]].
  static String _inline(String s) => s
      .replaceAllMapped(RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]'), (m) => m[2] ?? m[1]!)
      .replaceAllMapped(RegExp(r'!?\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!)
      .replaceAll(RegExp(r'(\*\*|__|~~|`)'), '')
      .replaceAllMapped(RegExp(r'(^|\s)[*_]([^*_\s][^*_]*?)[*_](?=\s|$)'), (m) => '${m[1]}${m[2]}')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _stripFields(String s) => _Fields.parse(s).rest;
}

class _Draft {
  _Draft(this.raw, {required this.done, this.list});
  final String raw;
  final bool done;
  final String? list;
  final checklist = <ChecklistEntry>[];
}

class _Front {
  const _Front({this.tags = const [], this.due});
  final List<String> tags;
  final CivilDate? due;
}

/// Trường Obsidian Tasks trong 1 dòng (emoji hoặc `[key:: value]`).
class _Fields {
  CivilDate? due, scheduled, start, doneOn;
  CivilTime? time;
  String? recurrence;
  int? priority;
  final tags = <String>[];
  String rest = '';

  static const _date = r'(\d{4}-\d{2}-\d{2})';
  static const _stop = '📅⏳⌛🛫✅➕❌⏰🔁⏫🔼🔽🔺⏬🆔⛔🏁#\\[';

  static _Fields parse(String input) {
    final f = _Fields();
    var s = input.replaceAll('️', '');
    CivilDate? date(String? v) {
      if (v == null) return null;
      final p = v.split('-').map(int.parse).toList();
      return CivilDate.isValid(p[0], p[1], p[2]) ? CivilDate(p[0], p[1], p[2]) : null;
    }

    String take(RegExp re, void Function(RegExpMatch m) on) {
      final m = re.firstMatch(s);
      if (m == null) return s;
      on(m);
      return s.replaceRange(m.start, m.end, ' ');
    }

    s = take(RegExp('📅\\s*$_date', unicode: true), (m) => f.due = date(m[1]));
    s = take(RegExp('[⏳⌛]\\s*$_date', unicode: true), (m) => f.scheduled = date(m[1]));
    s = take(RegExp('🛫\\s*$_date', unicode: true), (m) => f.start = date(m[1]));
    s = take(RegExp('✅\\s*$_date', unicode: true), (m) => f.doneOn = date(m[1]));
    s = take(RegExp('[➕❌]\\s*$_date', unicode: true), (_) {});
    s = take(RegExp('⏰\\s*(?:$_date\\s*)?(\\d{1,2}):(\\d{2})', unicode: true), (m) {
      f.due ??= date(m[1]);
      f.time = _time(m[2]!, m[3]!);
    });
    s = take(RegExp('🔁\\s*([^$_stop]+)', unicode: true), (m) => f.recurrence = m[1]!.trim());
    s = take(RegExp('[🔺⏫🔼🔽⏬]', unicode: true), (m) => f.priority = const {'🔺': 3, '⏫': 3, '🔼': 2, '🔽': 1, '⏬': 1}[m[0]]);
    s = take(RegExp('🆔\\s*\\S+', unicode: true), (_) {});
    s = take(RegExp('⛔\\s*\\S+', unicode: true), (_) {});
    // Dạng Dataview.
    for (final m in RegExp(r'[\[(](\w+)::\s*([^\])]*)[\])]').allMatches(s).toList().reversed) {
      final v = m[2]!.trim();
      switch (m[1]!.toLowerCase()) {
        case 'due':
          f.due ??= date(RegExp(_date).firstMatch(v)?[1]);
        case 'scheduled':
          f.scheduled ??= date(RegExp(_date).firstMatch(v)?[1]);
        case 'start':
          f.start ??= date(RegExp(_date).firstMatch(v)?[1]);
        case 'completion':
          f.doneOn ??= date(RegExp(_date).firstMatch(v)?[1]);
        case 'repeat':
          f.recurrence ??= v;
        case 'priority':
          f.priority ??= const {'highest': 3, 'high': 3, 'medium': 2, 'low': 1, 'lowest': 1}[v.toLowerCase()];
        default:
          continue;
      }
      s = s.replaceRange(m.start, m.end, ' ');
    }
    for (final m in RegExp(r'(?<![\p{L}\p{N}&/#])#([\p{L}\p{N}_/-]*[\p{L}_][\p{L}\p{N}_/-]*)', unicode: true).allMatches(s)) {
      f.tags.add(m[1]!);
    }
    s = s.replaceAll(RegExp(r'(?<![\p{L}\p{N}&/#])#[\p{L}\p{N}_/-]*[\p{L}_][\p{L}\p{N}_/-]*', unicode: true), ' ');
    f.rest = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return f;
  }

  static CivilTime? _time(String h, String m) {
    final hh = int.parse(h), mm = int.parse(m);
    return hh < 24 && mm < 60 ? CivilTime(hh, mm) : null;
  }
}

const _days = {
  'monday': 'MO', 'tuesday': 'TU', 'wednesday': 'WE', 'thursday': 'TH', 'friday': 'FR', 'saturday': 'SA', 'sunday': 'SU',
  'mon': 'MO', 'tue': 'TU', 'wed': 'WE', 'thu': 'TH', 'fri': 'FR', 'sat': 'SA', 'sun': 'SU',
};

/// Cú pháp lặp của Obsidian Tasks (luôn tiếng Anh, theo plugin): `every day`, `every 2 weeks`, `every weekday`,
/// `every week on Monday, Friday`, `every Monday and Thursday`, `every month on the 15th`, `every month on the last`, `every year`.
/// "when done" (lặp tính từ lúc xong) chưa có trong candidate: bỏ, lặp theo lịch. Không hiểu thì null.
String? obsidianRecurrenceToRrule(String text) {
  var s = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  s = s.replaceAll(RegExp(r'\s*when done$'), '').trim();
  if (s == 'every weekday') return 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
  final m = RegExp(r'^every (?:(\d+) )?(day|week|month|year)s?(?: on (.+))?$').firstMatch(s);
  if (m != null) {
    final n = int.tryParse(m[1] ?? '') ?? 1;
    final freq = const {'day': 'DAILY', 'week': 'WEEKLY', 'month': 'MONTHLY', 'year': 'YEARLY'}[m[2]]!;
    final parts = ['FREQ=$freq', if (n > 1) 'INTERVAL=$n'];
    final on = m[3];
    if (on != null) {
      if (freq == 'WEEKLY') {
        final days = _dayList(on);
        if (days == null) return null;
        parts.add('BYDAY=${days.join(',')}');
      } else if (freq == 'MONTHLY') {
        final last = RegExp(r'^the last(?: day)?$').hasMatch(on);
        final d = RegExp(r'^the (\d{1,2})(?:st|nd|rd|th)?$').firstMatch(on);
        if (!last && d == null) return null;
        parts.add('BYMONTHDAY=${last ? -1 : int.parse(d![1]!)}');
      } else {
        return null;
      }
    }
    return parts.join(';');
  }
  final w = RegExp(r'^every (.+)$').firstMatch(s);
  final days = w == null ? null : _dayList(w[1]!);
  return days == null ? null : 'FREQ=WEEKLY;BYDAY=${days.join(',')}';
}

List<String>? _dayList(String s) {
  final tokens = s.split(RegExp(r'\s*(?:,|\band\b|&)\s*')).where((t) => t.isNotEmpty).toList();
  final out = <String>[];
  for (final t in tokens) {
    final d = _days[t.trim()];
    if (d == null) return null;
    if (!out.contains(d)) out.add(d);
  }
  return out.isEmpty ? null : out;
}
