import '../extract/candidate.dart';
import '../nlu/pack.dart';
import 'airports.dart';
import 'document.dart';
import 'slots.dart';
import 'values.dart';
import 'vocabulary.dart';

class Classification {
  const Classification(this.type, this.scores);
  final DocType type;
  final Map<DocType, int> scores;
}

/// Phân loại tài liệu theo từ khóa có trọng số của các gói (on-device-extraction.md §4.1) + tín hiệu cấu trúc không phụ thuộc
/// ngôn ngữ (cặp mã sân bay). Mỗi từ khóa tính tối đa 2 lần. Loại thắng phải ≥ [minScore] và hơn loại nhì ≥ 2 điểm.
class DocClassifier {
  const DocClassifier(this.packs, {this.minScore = 4});
  final List<GrammarPack> packs;
  final int minScore;

  Classification classify(TextDocument doc, {ValueReader? reader}) {
    final scores = {for (final t in DocType.values) t: 0};
    for (final pack in packs) {
      for (final e in pack.document.classify.entries) {
        for (final k in e.value.entries) {
          var n = 0;
          for (var i = 0; i < doc.lines.length; i++) {
            n += doc.folded(i).approximateMatches(k.key, 0).length;
            if (n >= 2) break;
          }
          scores[e.key] = scores[e.key]! + k.value * (n > 2 ? 2 : n);
        }
      }
    }
    if (reader != null) {
      final strong = [for (var i = 0; i < doc.lines.length; i++) ...reader.airportsIn(doc, i).where((m) => m.strong)];
      if (strong.length >= 2) scores[DocType.flight] = scores[DocType.flight]! + 4;
    }
    final ranked = scores.entries.where((e) => e.key != DocType.unknown).toList()..sort((a, b) => b.value.compareTo(a.value));
    final best = ranked.first, second = ranked[1];
    final type = best.value >= minScore && best.value - second.value >= 2 ? best.key : DocType.unknown;
    return Classification(type, scores);
  }
}

/// Đọc giá trị theo nhãn in trên tài liệu ("Mã đặt chỗ", "Seat") của mọi gói: vùng bên phải trước, rồi bên dưới.
class AnchorReader {
  AnchorReader(this.doc, this.packs);
  final TextDocument doc;
  final List<GrammarPack> packs;

  final _others = <String, Set<String>>{};

  Set<String> _otherLabels(String field) => _others[field] ??= {
        for (final p in packs)
          for (final e in p.document.anchors.entries)
            if (e.key != field)
              for (final a in e.value) FoldedText(a).text,
      }..removeAll({for (final a in anchorsFor(field)) FoldedText(a).text});

  List<String> anchorsFor(String field) {
    final all = {for (final p in packs) ...?p.document.anchors[field]}.toList()..sort((a, b) => b.length.compareTo(a.length));
    return all;
  }

  /// Chỗ xuất hiện các nhãn của [field] theo thứ tự đọc; nhãn ngắn nằm trong nhãn dài đã thấy ("ghế" trong "số ghế") bị bỏ.
  /// Hit gần đúng (lỗi OCR) mà đoạn chữ khớp đúng nhãn của trường khác thì bỏ: bỏ dấu xong "điểm đón" chỉ khác "điểm đến" 1 ký tự.
  List<AnchorHit> hitsFor(String field, {int from = 0, int? to}) {
    final hits = <AnchorHit>[];
    for (final a in anchorsFor(field)) {
      for (final h in doc.findAnchor(a, from: from, to: to)) {
        if (h.score < 1 && _otherLabels(field).contains(FoldedText(doc.lines[h.line].text.substring(h.start, h.end)).text)) continue;
        if (!hits.any((o) => o.line == h.line && h.start < o.end && o.start < h.end)) hits.add(h);
      }
    }
    hits.sort((a, b) => a.line != b.line ? a.line.compareTo(b.line) : a.start.compareTo(b.start));
    return hits;
  }

  /// Giá trị đầu tiên [parse] đọc được sau 1 nhãn của [field] trong dòng [from, to).
  /// [asLabel]: chỉ nhận chỗ nhãn đứng như nhãn (theo sau là `:`, `/`, `-` hoặc hết dòng), dùng cho trường chữ tự do
  /// (tên khách sạn, địa chỉ) để không lấy nhầm câu văn "đã đặt phòng tại khách sạn ...".
  /// [excludeField]: bỏ chỗ nhãn nằm trong nhãn của trường này ("date" trong "booking date", "ngày" trong "ngày sinh").
  ({T value, double score})? read<T>(String field, T? Function(String text) parse,
      {int from = 0, int? to, bool below = true, bool asLabel = false, String? excludeField}) {
    final anchors = anchorsFor(field);
    final excluded = excludeField == null ? const <AnchorHit>[] : hitsFor(excludeField, from: from, to: to);
    final hits = [
      for (final h in hitsFor(field, from: from, to: to))
        if (!excluded.any((x) => x.line == h.line && h.start < x.end && x.start < h.end)) h,
    ];
    for (final h in hits) {
      if (asLabel && !RegExp(r'^\s*(?:[:：/|=–—-]|$)').hasMatch(doc.lines[h.line].text.substring(h.end))) continue;
      final right = doc.rightOf(h);
      final first = _clean(doc.regionText(right.first), anchors);
      final rest = [for (final r in right.skip(1)) doc.regionText(r)];
      for (final t in [first, ...rest]) {
        if (t.trim().isEmpty) continue;
        final v = parse(t);
        if (v != null) return (value: v, score: h.score);
      }
      // Bên dưới chỉ khi bên phải trống (nhãn đứng 1 mình trên dòng, giá trị ở dòng sau).
      if (below && first.trim().isEmpty && rest.isEmpty) {
        for (final r in doc.below(h, maxLines: 1)) {
          final v = parse(_clean(doc.regionText(r), anchors));
          if (v != null) return (value: v, score: h.score);
        }
      }
    }
    return null;
  }

  /// Bỏ dấu phân cách và nhãn song ngữ cùng trường ở đầu ("/ Booking code: X" → "X"), cắt ở cột kế tiếp (≥ 3 khoảng trắng, tab, " | ").
  static String _clean(String text, List<String> anchors) {
    var t = text;
    final cut = RegExp(r'\s{3,}|\t|\s\|\s').firstMatch(t.trimLeft());
    if (cut != null) t = t.trimLeft().substring(0, cut.start);
    final sep = RegExp(r'^[\s:/\-–—|·•=]+');
    var changed = true;
    while (changed) {
      changed = false;
      final s = t.replaceFirst(sep, '');
      if (s != t) {
        t = s;
        changed = true;
      }
      // Nhãn chỉ bị bỏ khi theo sau là dấu phân cách: "Khách sạn: Khách sạn Hoa Sen" giữ tên có chữ "Khách sạn".
      final f = FoldedText(t);
      for (final a in anchors) {
        final fa = FoldedText(a).text;
        if (f.text.startsWith(fa) && RegExp(r'^\s*(?:[:：/|=–—-]|$)').hasMatch(f.text.substring(fa.length))) {
          t = t.substring(f.original(fa.length));
          changed = true;
          break;
        }
      }
    }
    return t.trim();
  }
}

/// Extractor chung (on-device-extraction.md §4.3) khi không mẫu nhà cung cấp nào khớp.
class GenericExtractor {
  GenericExtractor(this.packs, {this.airports, this.region});
  final List<GrammarPack> packs;
  final AirportIndex? airports;
  final String? region;

  Set<String> get _stopwords => {for (final p in packs) ...p.document.codeStopwords};

  List<Slots> slots(DocType type, TextDocument doc) {
    final reader = ValueReader(packs, region: region, airports: airports, language: doc.language);
    final anchors = AnchorReader(doc, packs);
    return switch (type) {
      DocType.flight => _flights(doc, reader, anchors),
      DocType.hotel => [_hotel(doc, reader, anchors)],
      DocType.train || DocType.bus => [_ground(doc, reader, anchors)],
      DocType.medical => [_medical(doc, reader, anchors)],
      DocType.event => [_event(doc, reader, anchors)],
      DocType.todoList || DocType.unknown => const [],
    };
  }

  Slots _header(TextDocument doc, ValueReader reader, AnchorReader anchors, {required bool flight}) {
    final s = Slots();
    final code = anchors.read('confirmation_code', (t) => confirmationCodeIn(t, flight: flight, stopwords: _stopwords));
    if (code != null) s.confirmationCode = Slot(code.value, Slot.anchored * code.score);
    final total = anchors.read('total', (t) => reader.money(t).firstOrNull?.price);
    if (total != null) s.price = Slot(total.value, Slot.anchored * total.score);
    return s;
  }

  List<Slots> _flights(TextDocument doc, ValueReader reader, AnchorReader anchors) {
    final header = _header(doc, reader, anchors, flight: true);
    final pax = _passengerCount(doc);
    if (pax != null) header.passengerCount = Slot(pax, Slot.pattern);

    final mentions = [for (var i = 0; i < doc.lines.length; i++) ...reader.airportsIn(doc, i)];
    final strong = mentions.where((m) => m.strong).toList();
    final use = strong.length >= 2 ? strong : mentions;
    final legs = <(AirportMention, AirportMention)>[];
    for (var i = 0; i + 1 < use.length;) {
      final a = use[i], b = use[i + 1];
      if (a.code != b.code && b.line - a.line <= 2) {
        legs.add((a, b));
        i += 2;
      } else {
        i++;
      }
    }

    final dates = [for (var i = 0; i < doc.lines.length; i++) [for (final d in reader.dates(doc.lines[i].text)) (i, d)]];
    final flightNos = [
      for (var i = 0; i < doc.lines.length; i++)
        for (final f in reader.flightNumbers(doc.lines[i].text))
          if (f.carrier + f.number != header.confirmationCode?.value && !_insideDate(dates[i], f.start)) (i, f),
    ];

    // Khối của chặng k: từ dòng mở đầu chặng (nhãn "Chuyến về", số chuyến, ngày ngay trên dòng sân bay, không qua dòng trống)
    // tới dòng mở đầu chặng sau. Chặng đầu tính từ đầu tài liệu.
    final segmentAnchors = {for (final p in packs) ...p.document.segments};
    final starts = <int>[];
    for (var k = 0; k < legs.length; k++) {
      final floor = k == 0 ? 0 : legs[k - 1].$2.line + 1;
      var start = legs[k].$1.line;
      for (var i = start - 1; i >= floor; i--) {
        if (doc.lines[i].text.trim().isEmpty) break;
        final marks = dates[i].isNotEmpty || flightNos.any((f) => f.$1 == i) || segmentAnchors.any((a) => doc.findAnchor(a, from: i, to: i + 1).isNotEmpty);
        if (marks) start = i;
      }
      starts.add(k == 0 ? 0 : start);
    }

    final out = <Slots>[];
    for (var k = 0; k < legs.length; k++) {
      final (o, d) = legs[k];
      final lo = starts[k];
      final hi = k + 1 < legs.length ? starts[k + 1] : doc.lines.length;
      final s = Slots()
        ..origin = Slot(o.code, o.strong ? Slot.anchored : Slot.pattern)
        ..destination = Slot(d.code, d.strong ? Slot.anchored : Slot.pattern);

      // Ngày, số chuyến: gần dòng sân bay nhất trong khối của chặng (ưu tiên dòng trước/cùng dòng).
      int dist(int line) => line <= o.line ? (o.line - line) * 2 : (line - d.line) * 2 + 1;
      final nearDate = [for (var i = lo; i < hi; i++) ...dates[i]]..sort((x, y) => dist(x.$1).compareTo(dist(y.$1)));
      if (nearDate.isNotEmpty && dist(nearDate.first.$1) <= 8) s.departureDate = Slot(nearDate.first.$2, Slot.pattern);
      final nearFn = flightNos.where((f) => f.$1 >= lo && f.$1 < hi).toList()..sort((x, y) => dist(x.$1).compareTo(dist(y.$1)));
      if (nearFn.isNotEmpty && dist(nearFn.first.$1) <= 8) {
        s.carrierCode = Slot(nearFn.first.$2.carrier, Slot.pattern);
        s.number = Slot(nearFn.first.$2.number, Slot.pattern);
      }
      _legTimes(doc, reader, o, d, s);

      final seat = anchors.read('seat', _seat, from: lo, to: hi);
      if (seat != null) s.seat = Slot(seat.value, Slot.anchored * seat.score);
      final terminal = anchors.read('terminal', _terminal, from: lo, to: hi);
      if (terminal != null) s.originTerminal = Slot(terminal.value, Slot.anchored * terminal.score);
      final gate = anchors.read('gate', _terminal, from: lo, to: hi);
      if (gate != null) s.gate = Slot(gate.value, Slot.anchored * gate.score);
      final cls = anchors.read('class', _travelClass, from: lo, to: hi);
      if (cls != null) s.travelClass = Slot(cls.value, Slot.anchored * cls.score);
      s.fillFrom(header);
      // Tổng tiền là của cả đặt chỗ: chỉ gắn khi có 1 chặng.
      if (legs.length == 1) s.price = header.price;
      out.add(s);
    }
    return out;
  }

  static bool _insideDate(List<(int, DocDate)> dates, int pos) => dates.any((d) => pos >= d.$2.start && pos < d.$2.end);

  /// Giờ đi = giờ đứng sau mã nơi đi (trước mã nơi đến), giờ đến = giờ sau mã nơi đến. Không có thì giờ đứng trước mỗi mã.
  void _legTimes(TextDocument doc, ValueReader reader, AirportMention o, AirportMention d, Slots s) {
    final oText = doc.lines[o.line].text, dText = doc.lines[d.line].text;
    final oTimes = reader.times(oText), dTimes = o.line == d.line ? oTimes : reader.times(dText);
    final oLimit = o.line == d.line ? d.start : oText.length;
    DocTime? dep = oTimes.where((t) => t.start >= o.end && t.start < oLimit).firstOrNull;
    DocTime? arr = dTimes.where((t) => t.start >= d.end).firstOrNull;
    if (dep == null && arr == null) {
      // "10:30 SGN → 12:40 HAN"
      dep = oTimes.where((t) => t.end <= o.start).lastOrNull;
      arr = dTimes.where((t) => t.end <= d.start && (o.line != d.line || t.start >= o.end)).lastOrNull;
    }
    if (dep != null) s.departureTime = Slot(dep, Slot.pattern);
    if (arr != null && (dep == null || arr.start != dep.start || o.line != d.line)) {
      s.arrivalTime = Slot(arr, Slot.pattern);
      final after = dText.substring(arr.end);
      if (RegExp(r'^\s*(\(\s*)?\+\s?1\b').hasMatch(after)) s.arrivalNextDay = true;
    }
  }

  static String? _seat(String t) => RegExp(r'^0*(\d{1,3}[A-K])(?![A-Za-z0-9])').firstMatch(t)?[1];

  static String? _terminal(String t) => RegExp(r'^([A-Z]?\d{1,2}[A-Z]?|[A-Z])(?![A-Za-z0-9])').firstMatch(t)?[1];

  String? _travelClass(String t) {
    final f = FoldedText(t);
    final words = {for (final p in packs) ...p.document.travelClasses.keys}.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (final w in words) {
      final m = f.approximateMatches(w, 0);
      if (m.isNotEmpty && m.first.start <= 2) return t.substring(m.first.start, m.first.end);
    }
    return null;
  }

  int? _passengerCount(TextDocument doc) {
    final units = {for (final p in packs) ...p.document.passengerUnits}.toList()..sort((a, b) => b.length.compareTo(a.length));
    if (units.isEmpty) return null;
    final re = RegExp('(?<![\\p{N}])(\\d{1,2})\\s*(?:${units.map(RegExp.escape).join('|')})(?![\\p{L}])', unicode: true);
    var total = 0;
    for (var i = 0; i < doc.lines.length; i++) {
      for (final m in re.allMatches(doc.folded(i).text)) {
        total += int.parse(m[1]!);
      }
    }
    return total == 0 ? null : total;
  }

  Slots _hotel(TextDocument doc, ValueReader reader, AnchorReader anchors) {
    final s = _header(doc, reader, anchors, flight: false);
    ({DocDate date, DocTime? time})? dateTime(String t) {
      final ds = reader.dates(t);
      if (ds.isEmpty) return null;
      final ts = reader.times(t, dates: ds);
      return (date: ds.first, time: ts.firstOrNull);
    }

    final ci = anchors.read('check_in', dateTime);
    if (ci != null) {
      s.checkInDate = Slot(ci.value.date, Slot.anchored * ci.score);
      if (ci.value.time != null) s.checkInTime = Slot(ci.value.time!, Slot.anchored * ci.score);
    }
    final co = anchors.read('check_out', dateTime);
    if (co != null) {
      s.checkOutDate = Slot(co.value.date, Slot.anchored * co.score);
      if (co.value.time != null) s.checkOutTime = Slot(co.value.time!, Slot.anchored * co.score);
    }
    final name = anchors.read('property', (t) => _name(t, reader), asLabel: true);
    if (name != null) s.property = Slot(name.value, Slot.anchored * name.score);
    final addr = anchors.read('address', (t) => _name(t, reader), asLabel: true);
    if (addr != null) s.address = Slot(addr.value, Slot.anchored * addr.score);
    return s;
  }

  /// Tên/địa chỉ: phần chữ còn lại sau nhãn, không phải ngày giờ, có ít nhất 1 chữ cái.
  static String? _name(String t, ValueReader reader) {
    final v = t.trim();
    if (v.length < 2 || !RegExp(r'\p{L}', unicode: true).hasMatch(v)) return null;
    if (reader.dates(v).isNotEmpty) return null;
    return v;
  }

  // ---- Tàu, xe khách -------------------------------------------------------------------------------------------------

  Slots _ground(TextDocument doc, ValueReader reader, AnchorReader anchors) {
    final s = _header(doc, reader, anchors, flight: false);
    final no = anchors.read('train_number', _trainNumber);
    if (no != null) s.number = Slot(no.value, Slot.anchored * no.score);
    final op = anchors.read('operator', (t) => _name(t, reader), asLabel: true);
    if (op != null) s.provider = Slot(op.value, Slot.anchored * op.score);

    // Ga/điểm đi, đến theo nhãn: tên + giờ (+ ngày) in cùng vùng ("Ga đi: Sài Gòn 22:00").
    ({String name, DocTime? time, DocDate? date, bool nextDay})? stop(String t) => _stop(t, reader);
    final from = anchors.read('origin', stop, asLabel: true);
    final to = anchors.read('destination', stop, asLabel: true);
    if (from != null && to != null) {
      s.originName = Slot(from.value.name, Slot.anchored * from.score);
      s.destinationName = Slot(to.value.name, Slot.anchored * to.score);
      if (from.value.time != null) s.departureTime = Slot(from.value.time!, Slot.anchored * from.score);
      if (from.value.date != null) s.departureDate = Slot(from.value.date!, Slot.anchored * from.score);
      if (to.value.time != null) s.arrivalTime = Slot(to.value.time!, Slot.anchored * to.score);
      if (to.value.date != null) s.arrivalDate = Slot(to.value.date!, Slot.anchored * to.score);
      s.arrivalNextDay = to.value.nextDay;
    } else {
      _route(doc, reader, s);
    }

    s.departureDate ??= _anchoredDate(anchors, reader, 'departure_date') ?? _firstFreeDate(doc, reader, anchors);
    if (s.departureTime == null) {
      final t = anchors.read('departure_time', (t) => reader.times(t).firstOrNull);
      if (t != null) s.departureTime = Slot(t.value, Slot.anchored * t.score);
    }
    if (s.arrivalTime == null) {
      final t = anchors.read('arrival_time', (t) => reader.times(t).firstOrNull);
      if (t != null) s.arrivalTime = Slot(t.value, Slot.anchored * t.score);
    }
    final car = anchors.read('carriage', _carriage);
    if (car != null) s.carriage = Slot(car.value, Slot.anchored * car.score);
    // "chỗ" cũng nằm trong "Mã đặt chỗ".
    final seat = anchors.read('seat', _groundSeat, excludeField: 'confirmation_code');
    if (seat != null) s.seat = Slot(seat.value, Slot.anchored * seat.score);
    return s;
  }

  /// Không có nhãn ga: dòng "Sài Gòn 22:00 → Đà Nẵng 15:40" (mũi tên giữa 2 tên có chữ).
  void _route(TextDocument doc, ValueReader reader, Slots s) {
    final arrow = RegExp(r'\s(?:→|->|⇒|—>|➝|➔)\s');
    for (var i = 0; i < doc.lines.length; i++) {
      final text = doc.lines[i].text;
      final m = arrow.firstMatch(text);
      if (m == null) continue;
      final a = _stop(text.substring(0, m.start), reader), b = _stop(text.substring(m.end), reader);
      if (a == null || b == null) continue;
      s.originName = Slot(a.name, Slot.pattern);
      s.destinationName = Slot(b.name, Slot.pattern);
      if (a.time != null) s.departureTime = Slot(a.time!, Slot.pattern);
      if (b.time != null) s.arrivalTime = Slot(b.time!, Slot.pattern);
      if (a.date != null) s.departureDate = Slot(a.date!, Slot.pattern);
      s.arrivalNextDay = b.nextDay;
      return;
    }
  }

  /// "Sài Gòn  22:00" → tên + giờ; "Đà Nẵng 15:40 (+1)" → hôm sau. Tên là phần chữ trước ngày/giờ đầu tiên.
  static ({String name, DocTime? time, DocDate? date, bool nextDay})? _stop(String t, ValueReader reader) {
    final dates = reader.dates(t);
    final times = reader.times(t, dates: dates);
    final cut = [t.length, ?dates.firstOrNull?.start, ?times.firstOrNull?.start].reduce((a, b) => a < b ? a : b);
    final name = t.substring(0, cut).replaceAll(RegExp(r'^[\s:/\-–—|·•,()]+|[\s:/\-–—|·•,(]+$'), '');
    if (name.length < 2 || !RegExp(r'\p{L}', unicode: true).hasMatch(name) || name.length > 60) return null;
    final time = times.firstOrNull;
    final next = time != null && RegExp(r'^\s*\(?\s*\+\s?1\b').hasMatch(t.substring(time.end));
    return (name: name, time: time, date: dates.firstOrNull, nextDay: next);
  }

  static String? _trainNumber(String t) => RegExp(r'^([A-Z]{1,4}\s?\d{1,5}[A-Z]?|\d{1,5})(?![A-Za-z0-9])').firstMatch(t)?[1];

  static String? _carriage(String t) => RegExp(r'^0*(\d{1,3}[A-Z]?)(?![A-Za-z0-9])').firstMatch(t)?[1];

  /// Chỗ/giường tàu, ghế xe: số, có thể kèm chữ ("23", "A12", "12B").
  static String? _groundSeat(String t) => RegExp(r'^([A-Z]?\d{1,3}[A-Z]?)(?![A-Za-z0-9])').firstMatch(t)?[1];

  // ---- Ngày không có nhãn của loại --------------------------------------------------------------------------------

  Slot<DocDate>? _anchoredDate(AnchorReader anchors, ValueReader reader, String field) {
    final d = anchors.read(field, (t) => reader.dates(t).firstOrNull, excludeField: 'excluded_dates');
    return d == null ? null : Slot(d.value, Slot.anchored * d.score);
  }

  /// Ngày đầu tiên trong tài liệu không thuộc nhãn loại trừ (ngày sinh, ngày đặt vé): độ tin cậy "chỉ pattern".
  Slot<DocDate>? _firstFreeDate(TextDocument doc, ValueReader reader, AnchorReader anchors) {
    final first = _freeDates(doc, reader, anchors).firstOrNull;
    return first == null ? null : Slot(first.$2, Slot.pattern);
  }

  List<(int, DocDate)> _freeDates(TextDocument doc, ValueReader reader, AnchorReader anchors) {
    final excluded = anchors.hitsFor('excluded_dates');
    final out = <(int, DocDate)>[];
    final skip = <(int, int)>{};
    for (final x in excluded) {
      final onLine = reader.dates(doc.lines[x.line].text).where((d) => d.start >= x.end).firstOrNull;
      if (onLine != null) {
        skip.add((x.line, onLine.start));
      } else if (doc.lines[x.line].text.substring(x.end).replaceAll(RegExp(r'[\s:：]'), '').isEmpty) {
        for (var i = x.line + 1; i < doc.lines.length; i++) {
          final d = reader.dates(doc.lines[i].text).firstOrNull;
          if (doc.lines[i].text.trim().isEmpty) continue;
          if (d != null) skip.add((i, d.start));
          break;
        }
      }
    }
    for (var i = 0; i < doc.lines.length; i++) {
      for (final d in reader.dates(doc.lines[i].text)) {
        if (!skip.contains((i, d.start))) out.add((i, d));
      }
    }
    return out;
  }

  /// Ngày + giờ của lịch hẹn/sự kiện: nhãn ngày (giờ cùng vùng hoặc nhãn giờ riêng), không thì ngày tự do đầu tiên và giờ cùng dòng.
  void _when(TextDocument doc, ValueReader reader, AnchorReader anchors, Slots s, {required String dateField, String? timeField}) {
    ({DocDate date, DocTime? time})? dateTime(String t) {
      final ds = reader.dates(t);
      if (ds.isEmpty) return null;
      return (date: ds.first, time: reader.times(t, dates: ds).firstOrNull);
    }

    final d = anchors.read(dateField, dateTime, excludeField: 'excluded_dates', asLabel: true) ??
        anchors.read(dateField, dateTime, excludeField: 'excluded_dates');
    if (d != null) {
      s.departureDate = Slot(d.value.date, Slot.anchored * d.score);
      if (d.value.time != null) s.departureTime = Slot(d.value.time!, Slot.anchored * d.score);
    }
    if (s.departureTime == null && timeField != null) {
      final t = anchors.read(timeField, (t) => reader.times(t).firstOrNull, asLabel: true);
      if (t != null) s.departureTime = Slot(t.value, Slot.anchored * t.score);
    }
    if (s.departureDate == null) {
      final free = _freeDates(doc, reader, anchors).firstOrNull;
      if (free != null) {
        s.departureDate = Slot(free.$2, Slot.pattern);
        if (s.departureTime == null) {
          final line = doc.lines[free.$1].text;
          final t = reader.times(line).where((t) => t.start >= free.$2.end).firstOrNull;
          if (t != null) s.departureTime = Slot(t, Slot.pattern);
        }
      }
    }
  }

  // ---- Lịch khám -----------------------------------------------------------------------------------------------------

  Slots _medical(TextDocument doc, ValueReader reader, AnchorReader anchors) {
    final s = Slots();
    _when(doc, reader, anchors, s, dateField: 'appointment_date', timeField: 'appointment_time');
    final facility = anchors.read('facility', (t) => _name(t, reader), asLabel: true);
    if (facility != null) {
      s.property = Slot(facility.value, Slot.anchored * facility.score);
    } else {
      final line = _lineWith(doc, {for (final p in packs) ...p.document.facilityWords}, reader);
      if (line != null) s.property = Slot(line, Slot.pattern);
    }
    final dept = anchors.read('department', (t) => _name(t, reader), asLabel: true);
    if (dept != null) s.department = Slot(dept.value, Slot.anchored * dept.score);
    final queue = anchors.read('queue_number', (t) => RegExp(r'^([A-Z]?\d{1,4}[A-Z]?)(?![A-Za-z0-9])').firstMatch(t)?[1]);
    if (queue != null) s.queueNumber = Slot(queue.value, Slot.anchored * queue.score);
    final prep = anchors.read('preparation', (t) => _name(t, reader), asLabel: true);
    if (prep != null) {
      s.preparation = Slot(prep.value, Slot.anchored * prep.score);
    } else {
      final words = {for (final p in packs) ...p.document.preparationWords};
      for (var i = 0; i < doc.lines.length && s.preparation == null; i++) {
        if (words.any((w) => doc.folded(i).approximateMatches(w, 0).isNotEmpty)) s.preparation = Slot(doc.lines[i].text.trim(), Slot.pattern);
      }
    }
    final addr = anchors.read('address', (t) => _name(t, reader), asLabel: true) ?? anchors.read('venue', (t) => _name(t, reader), asLabel: true);
    if (addr != null) s.address = Slot(addr.value, Slot.anchored * addr.score);
    return s;
  }

  /// Tên nơi khám không có nhãn: dòng ngắn (≤ 60 ký tự, không `:`, không ngày giờ) chứa 1 trong [words] ("BỆNH VIỆN ĐA KHOA X");
  /// không có thì cụm từ viết hoa quanh từ đó trong câu ("... at Riverside Dental Clinic.").
  static String? _lineWith(TextDocument doc, Set<String> words, ValueReader reader) {
    for (var i = 0; i < doc.lines.length; i++) {
      final t = doc.lines[i].text.trim();
      if (t.isEmpty || t.length > 60 || t.contains(':') || reader.dates(t).isNotEmpty || reader.times(t).isNotEmpty) continue;
      if (words.any((w) => doc.folded(i).approximateMatches(w, 0).isNotEmpty)) return t;
    }
    for (var i = 0; i < doc.lines.length; i++) {
      for (final w in words) {
        for (final m in doc.folded(i).approximateMatches(w, 0)) {
          final name = _capitalizedAround(doc.lines[i].text, m.start, m.end);
          if (name != null) return name;
        }
      }
    }
    return null;
  }

  /// Mở rộng [start, end) sang trái/phải theo các từ viết hoa liền kề. Cần ít nhất 1 từ viết hoa ngoài chính từ khóa.
  static String? _capitalizedAround(String text, int start, int end) {
    final upper = RegExp(r'^\p{Lu}', unicode: true);
    final word = RegExp(r'[\p{L}\p{N}&\x27-]+', unicode: true);
    final tokens = word.allMatches(text).toList();
    var first = tokens.indexWhere((t) => t.end > start), last = tokens.lastIndexWhere((t) => t.start < end);
    if (first < 0 || last < first || !upper.hasMatch(tokens[first][0]!)) return null;
    final core = (first, last);
    bool joined(int a, int b) => RegExp(r'^ $').hasMatch(text.substring(tokens[a].end, tokens[b].start));
    while (first > 0 && upper.hasMatch(tokens[first - 1][0]!) && joined(first - 1, first)) {
      first--;
    }
    while (last + 1 < tokens.length && upper.hasMatch(tokens[last + 1][0]!) && joined(last, last + 1)) {
      last++;
    }
    if ((first, last) == core) return null;
    return text.substring(tokens[first].start, tokens[last].end);
  }

  // ---- Vé sự kiện -----------------------------------------------------------------------------------------------------

  Slots _event(TextDocument doc, ValueReader reader, AnchorReader anchors) {
    final s = _header(doc, reader, anchors, flight: false);
    _when(doc, reader, anchors, s, dateField: 'event_date');
    final name = anchors.read('event_name', (t) => _name(t, reader), asLabel: true);
    if (name != null) s.property = Slot(name.value, Slot.anchored * name.score);
    final venue = anchors.read('venue', (t) => _name(t, reader), asLabel: true) ?? anchors.read('address', (t) => _name(t, reader), asLabel: true);
    if (venue != null) s.address = Slot(venue.value, Slot.anchored * venue.score);
    final seat = anchors.read('seat', _groundSeat, excludeField: 'confirmation_code');
    if (seat != null) s.seat = Slot(seat.value, Slot.anchored * seat.score);
    return s;
  }
}

/// Ghép extractor chung + assembler: tiện cho test và cho đường đi không có mẫu.
List<Candidate> genericCandidates(
  DocType type,
  TextDocument doc, {
  required List<GrammarPack> packs,
  required DateTime reference,
  AirportIndex? airports,
  String? region,
}) {
  final assembler = CandidateAssembler(airports: airports, reference: reference);
  return [
    for (final s in GenericExtractor(packs, airports: airports, region: region).slots(type, doc)) ?assembler.assemble(type, s, source: 'generic'),
  ];
}
