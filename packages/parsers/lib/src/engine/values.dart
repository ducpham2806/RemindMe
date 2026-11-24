import '../extract/candidate.dart';
import '../nlu/pack.dart';
import 'airports.dart';
import 'document.dart';

/// Ngày đọc được trong tài liệu. [year] null = tài liệu không in năm (suy sau theo ngày tham chiếu).
class DocDate {
  const DocDate(this.year, this.month, this.day, {required this.start, required this.end, this.orderAmbiguous = false});
  final int? year;
  final int month;
  final int day;
  final int start;
  final int end;
  /// `03/04` mà không biết thứ tự ngày/tháng của tài liệu: đã giả định theo gói, màn Xem lại hỏi lại.
  final bool orderAmbiguous;

  /// 'YYYY-MM-DD'; thiếu năm thì lấy lần gần nhất từ [reference] trở đi (on-device-extraction.md §4.4).
  String iso(DateTime reference) {
    var y = year ?? reference.year;
    if (year == null && DateTime.utc(y, month, day).isBefore(DateTime.utc(reference.year, reference.month, reference.day))) y++;
    return '${y.toString().padLeft(4, '0')}-${_pad2(month)}-${_pad2(day)}';
  }
}

class DocTime {
  const DocTime(this.hour, this.minute, {required this.start, required this.end});
  final int hour;
  final int minute;
  final int start;
  final int end;

  int get minutes => hour * 60 + minute;
  String get hm => '${_pad2(hour)}:${_pad2(minute)}';
}

class FlightNumber {
  const FlightNumber(this.carrier, this.number, {required this.start, required this.end});
  final String carrier;
  final String number;
  final int start;
  final int end;
}

class AirportMention {
  const AirportMention(this.code, {required this.line, required this.start, required this.end, required this.strong});
  final String code;
  final int line;
  final int start;
  final int end;
  /// Trong ngoặc "(SGN)" hoặc thành cặp "SGN → HAN": chắc là sân bay. Không thì có thể là chữ viết tắt khác.
  final bool strong;
}

class MoneyHit {
  const MoneyHit(this.price, {required this.start, required this.end});
  final Price price;
  final int start;
  final int end;
}

/// Đọc giá trị từ 1 dòng chữ, dùng mẫu ngày/giờ của gói NLU (cùng nguồn với Quick Add) + quy tắc không phụ thuộc ngôn ngữ.
class ValueReader {
  ValueReader(this.packs, {this.region, this.airports, String? language, String? dateOrder})
      : _ordered = [...packs.where((p) => p.lang == language), ...packs.where((p) => p.lang != language)],
        dateOrder = dateOrder ?? _orderFor(packs, region, language);

  final List<GrammarPack> packs;
  /// Vùng của tài liệu/người dùng.
  final String? region;
  final AirportIndex? airports;
  /// Thứ tự ngày số `03/04` của tài liệu (`dmy` | `mdy` | `ymd`); null = không biết (đọc theo dmy, đánh dấu mơ hồ).
  final String? dateOrder;
  final List<GrammarPack> _ordered;

  /// Gói nào khai báo vùng thì theo vùng; không thì mặc định của gói cùng ngôn ngữ tài liệu.
  static String? _orderFor(List<GrammarPack> packs, String? region, String? language) {
    if (region != null) {
      for (final p in packs) {
        final o = p.dateOrderByRegion[region];
        if (o != null) return o;
      }
    }
    return packs.where((p) => p.lang == language).firstOrNull?.dateOrderDefault;
  }

  static final _isoDate = RegExp(r'(?<![\d/.-])(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(?![\d/.-])');

  /// Mọi ngày trong [text]. Các mẫu chồng nhau thì giữ đoạn dài nhất ("ZY 5  Dec 20, 2026": "Dec 20, 2026", không phải "5 Dec").
  List<DocDate> dates(String text) {
    final all = <DocDate>[];
    for (final m in _isoDate.allMatches(text)) {
      final mo = int.parse(m[2]!), d = int.parse(m[3]!);
      if (_valid(mo, d)) all.add(DocDate(int.parse(m[1]!), mo, d, start: m.start, end: m.end));
    }
    for (final pack in _ordered) {
      for (final p in pack.patterns) {
        if (p.type != PatternType.dayMonth && p.type != PatternType.numericDate) continue;
        for (final m in p.regex.allMatches(text)) {
          final d = p.type == PatternType.dayMonth ? _dayMonth(pack, m, text) : _numeric(m);
          if (d != null) all.add(d);
        }
      }
    }
    // Sắp ổn định theo độ dài giảm dần: cùng độ dài thì giữ thứ tự gói (gói của ngôn ngữ tài liệu trước).
    final ranked = [for (var i = 0; i < all.length; i++) (i, all[i])]
      ..sort((a, b) {
        final l = (b.$2.end - b.$2.start).compareTo(a.$2.end - a.$2.start);
        return l != 0 ? l : a.$1.compareTo(b.$1);
      });
    final out = <DocDate>[];
    for (final (_, d) in ranked) {
      if (!out.any((o) => d.start < o.end && o.start < d.end)) out.add(d);
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  DocDate? _dayMonth(GrammarPack pack, RegExpMatch m, String text) {
    final d = pack.number(_g(m, 'd') ?? '');
    final moText = _g(m, 'mo') ?? '';
    final mo = int.tryParse(moText) ?? pack.months[GrammarPack.norm(moText)] ?? pack.number(moText);
    if (d == null || mo == null || !_valid(mo, d)) return null;
    final y = _year(_g(m, 'y'));
    return DocDate(y, mo, d, start: m.start, end: m.end);
  }

  DocDate? _numeric(RegExpMatch m) {
    final a = int.parse(_g(m, 'a')!), b = int.parse(_g(m, 'b')!);
    final yText = _g(m, 'y');
    // Tài liệu luôn in năm với ngày số; "12/40" không có năm dễ là thứ khác (tỉ số, số trang).
    if (yText == null) return null;
    final y = _year(yText);
    final order = dateOrder;
    int day, month;
    var ambiguous = false;
    if (a > 12 && b <= 12) {
      (day, month) = (a, b);
    } else if (b > 12 && a <= 12) {
      (day, month) = (b, a);
    } else if (order == 'mdy') {
      (day, month) = (b, a);
    } else {
      (day, month) = (a, b);
      ambiguous = order == null && a != b;
    }
    if (!_valid(month, day)) return null;
    return DocDate(y, month, day, start: m.start, end: m.end, orderAmbiguous: ambiguous);
  }

  /// Giờ:phút. Chỉ nhận dạng có phút, có am/pm hoặc có đơn vị giờ ("14h", "14 giờ"); bỏ phần chồng lên ngày đã đọc.
  List<DocTime> times(String text, {List<DocDate>? dates}) {
    final taken = [for (final d in dates ?? this.dates(text)) (d.start, d.end)];
    final out = <DocTime>[];
    bool free(int s, int e) => !taken.any((t) => s < t.$2 && t.$1 < e) && !out.any((t) => s < t.end && t.start < e);
    for (final pack in _ordered) {
      for (final p in pack.patterns) {
        if (p.type != PatternType.hm) continue;
        for (final m in p.regex.allMatches(text)) {
          if (!free(m.start, m.end)) continue;
          final hText = _g(m, 'h'), mText = _g(m, 'm'), ap = _g(m, 'ap');
          final raw = m[0]!.trim();
          if (mText == null && ap == null && !RegExp(r'^\d{1,2}\s*\p{L}', unicode: true).hasMatch(raw)) continue;
          var h = pack.number(hText ?? '');
          final min = mText == null ? 0 : int.tryParse(mText);
          if (h == null || min == null || min > 59) continue;
          if (ap != null) {
            final mer = pack.meridiem[GrammarPack.norm(ap)];
            if (h < 1 || h > 12) continue;
            if (mer == 'pm' && h < 12) h += 12;
            if (mer == 'am' && h == 12) h = 0;
          }
          if (h > 23) continue;
          out.add(DocTime(h, min, start: m.start, end: m.end));
        }
      }
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  static final _flightRe = RegExp(r'(?<![A-Z0-9])([A-Z]{2}|[A-Z][0-9]|[0-9][A-Z])\s?(\d{1,4})(?![A-Z0-9])');

  /// Số hiệu chuyến bay: mã hãng IATA 2 ký tự (chữ hoặc chữ + số) + 1-4 số, chữ in hoa.
  List<FlightNumber> flightNumbers(String text) => [
        for (final m in _flightRe.allMatches(text)) FlightNumber(m[1]!, int.parse(m[2]!).toString(), start: m.start, end: m.end),
      ];

  static final _parenCode = RegExp(r'\(\s*([A-Z]{3})\s*\)');
  static final _pairCode = RegExp(r'(?<![A-Za-z])([A-Z]{3})\s*(?:→|->|–|—|-|>|✈|\bto\b)\s*([A-Z]{3})(?![A-Za-z])');
  static final _bareCode = RegExp(r'(?<![A-Za-z])([A-Z]{3})(?![A-Za-z])');

  /// Mã sân bay trong dòng [line] của [doc], theo thứ tự xuất hiện. Có từ điển thì chỉ nhận mã có thật.
  List<AirportMention> airportsIn(TextDocument doc, int line) {
    final text = doc.lines[line].text;
    final out = <AirportMention>[];
    void add(String code, int s, int e, bool strong) {
      if (!(airports?.contains(code) ?? true) || out.any((o) => s < o.end && o.start < e)) return;
      // Mã đứng một mình trùng mã tiền tệ ("VND", "USD") thì bỏ; trong ngoặc/thành cặp vẫn nhận (MAD là Madrid).
      if (!strong && _currencyCodes.contains(code)) return;
      out.add(AirportMention(code, line: line, start: s, end: e, strong: strong));
    }

    for (final m in _parenCode.allMatches(text)) {
      add(m[1]!, m.start, m.end, true);
    }
    for (final m in _pairCode.allMatches(text)) {
      final s2 = m.start + m[0]!.lastIndexOf(m[2]!);
      add(m[1]!, m.start, m.start + 3, true);
      add(m[2]!, s2, s2 + 3, true);
    }
    // Mã đứng một mình ("SGN 10:30") chỉ tính khi từ điển có và có giờ ngay sát bên: chữ in hoa 3 ký tự khác ("THE", "END")
    // cũng là mã sân bay có thật.
    if (airports != null) {
      final times = this.times(text);
      bool besideTime(int s, int e) => times.any((t) =>
          (t.start >= e && RegExp(r'^[\s:,()-]{0,3}$').hasMatch(text.substring(e, t.start))) ||
          (t.end <= s && RegExp(r'^[\s:,()-]{0,3}$').hasMatch(text.substring(t.end, s))));
      for (final m in _bareCode.allMatches(text)) {
        if (besideTime(m.start, m.end)) add(m[1]!, m.start, m.end, false);
      }
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  static final _moneyRe = RegExp(
    r'(?<pre>US\$|S\$|A\$|C\$|R\$|HK\$|NT\$|RM|Rp|[A-Z]{3}|[€£¥₫₩฿₹₱₺₪])?\s?'
    r"(?<amt>\d{1,3}(?:[.,\u00a0\u202f']\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)"
    r'\s?(?<post>[A-Z]{3}(?![A-Za-z])|[€£¥₫₩฿₹₱₺₪]|đ(?![\p{L}])|zł|Kč|kr(?![\p{L}]))?',
    unicode: true,
  );

  /// Số tiền có đơn vị rõ ràng (mã ISO 4217 hoặc ký hiệu không mơ hồ). "$" một mình không đoán là USD.
  List<MoneyHit> money(String text) {
    final out = <MoneyHit>[];
    for (final m in _moneyRe.allMatches(text)) {
      final pre = m.namedGroup('pre'), post = m.namedGroup('post');
      final cur = _currency(post) ?? _currency(pre);
      if (cur == null) continue;
      final amount = _amount(m.namedGroup('amt')!, cur);
      if (amount == null) continue;
      out.add(MoneyHit(Price(amount, cur), start: m.start, end: m.end));
    }
    return out;
  }

  static String? _currency(String? s) {
    if (s == null) return null;
    if (_currencyCodes.contains(s)) return s;
    return const {
      'US\$': 'USD', 'S\$': 'SGD', 'A\$': 'AUD', 'C\$': 'CAD', 'R\$': 'BRL', 'HK\$': 'HKD', 'NT\$': 'TWD', 'RM': 'MYR', 'Rp': 'IDR',
      '€': 'EUR', '£': 'GBP', '₫': 'VND', 'đ': 'VND', '₩': 'KRW', '฿': 'THB', '₹': 'INR', '₱': 'PHP', '₺': 'TRY', '₪': 'ILS', 'zł': 'PLN',
      'Kč': 'CZK',
    }[s];
  }

  /// '1.890.000' (VND) → '1890000'; '1.234,50' → '1234.50'; '1,234.50' → '1234.50'; '12.50' → '12.50'.
  static String? _amount(String raw, String currency) {
    final s = raw.replaceAll(RegExp(r"[\u00a0\u202f']"), ',');
    final last = s.lastIndexOf(RegExp('[.,]'));
    if (last < 0) return s;
    final tail = s.substring(last + 1);
    // Phần sau dấu cuối 1-2 chữ số là phần lẻ; tiền không có phần lẻ (VND, JPY) thì bỏ ",00".
    if (tail.length <= 2) {
      final intPart = s.substring(0, last).replaceAll(RegExp('[.,]'), '');
      return _zeroDecimal.contains(currency) ? intPart : '$intPart.${tail.padRight(2, '0')}';
    }
    if (tail.length != 3) return null;
    return s.replaceAll(RegExp('[.,]'), '');
  }

  static String? _g(RegExpMatch m, String name) => m.groupNames.contains(name) ? m.namedGroup(name) : null;

  static int? _year(String? y) {
    if (y == null) return null;
    final v = int.parse(y);
    return y.length == 2 ? 2000 + v : v;
  }

  static bool _valid(int month, int day) =>
      month >= 1 && month <= 12 && day >= 1 && day <= const [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
}

/// Mã đặt chỗ trong [text]: chữ in hoa + số, có ít nhất 1 chữ cái (PNR hãng bay 6 ký tự; khách sạn có thể dài hơn hoặc toàn số).
String? confirmationCodeIn(String text, {required bool flight, Set<String> stopwords = const {}}) {
  final re = flight ? RegExp(r'(?<![A-Za-z0-9])([A-Z0-9]{5,8})(?![A-Za-z0-9])') : RegExp(r'(?<![A-Za-z0-9-])([A-Z0-9][A-Z0-9-]{3,19})(?![A-Za-z0-9-])');
  for (final m in re.allMatches(text)) {
    final c = m[1]!;
    if (stopwords.contains(c)) continue;
    if (flight && !c.contains(RegExp('[A-Z]'))) continue;
    if (!flight && !c.contains(RegExp(r'\d')) && c.length < 5) continue;
    return c;
  }
  return null;
}

String _pad2(int v) => v.toString().padLeft(2, '0');

/// ISO 4217 đang dùng (để không nhầm mã tiền với mã sân bay và ngược lại).
const _currencyCodes = {
  'AED', 'AFN', 'ALL', 'AMD', 'ANG', 'AOA', 'ARS', 'AUD', 'AWG', 'AZN', 'BAM', 'BBD', 'BDT', 'BGN', 'BHD', 'BIF', 'BMD', 'BND', 'BOB',
  'BRL', 'BSD', 'BTN', 'BWP', 'BYN', 'BZD', 'CAD', 'CDF', 'CHF', 'CLP', 'CNY', 'COP', 'CRC', 'CUP', 'CVE', 'CZK', 'DJF', 'DKK', 'DOP',
  'DZD', 'EGP', 'ERN', 'ETB', 'EUR', 'FJD', 'FKP', 'GBP', 'GEL', 'GHS', 'GIP', 'GMD', 'GNF', 'GTQ', 'GYD', 'HKD', 'HNL', 'HTG', 'HUF',
  'IDR', 'ILS', 'INR', 'IQD', 'IRR', 'ISK', 'JMD', 'JOD', 'JPY', 'KES', 'KGS', 'KHR', 'KMF', 'KPW', 'KRW', 'KWD', 'KYD', 'KZT', 'LAK',
  'LBP', 'LKR', 'LRD', 'LSL', 'LYD', 'MAD', 'MDL', 'MGA', 'MKD', 'MMK', 'MNT', 'MOP', 'MRU', 'MUR', 'MVR', 'MWK', 'MXN', 'MYR', 'MZN',
  'NAD', 'NGN', 'NIO', 'NOK', 'NPR', 'NZD', 'OMR', 'PAB', 'PEN', 'PGK', 'PHP', 'PKR', 'PLN', 'PYG', 'QAR', 'RON', 'RSD', 'RUB', 'RWF',
  'SAR', 'SBD', 'SCR', 'SDG', 'SEK', 'SGD', 'SHP', 'SLE', 'SOS', 'SRD', 'SSP', 'STN', 'SYP', 'SZL', 'THB', 'TJS', 'TMT', 'TND', 'TOP',
  'TRY', 'TTD', 'TWD', 'TZS', 'UAH', 'UGX', 'USD', 'UYU', 'UZS', 'VES', 'VND', 'VUV', 'WST', 'XAF', 'XCD', 'XOF', 'XPF', 'YER', 'ZAR',
  'ZMW', 'ZWG',
};

/// Tiền tệ không có phần lẻ (ISO 4217 minor unit 0): mọi dấu chấm/phẩy là phân cách nghìn.
const _zeroDecimal = {'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', 'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF'};
