import 'dart:math' as math;

/// Khung chữ nhật của 1 dòng chữ, tọa độ chuẩn hóa 0..1 theo trang (OCR trả về; text thuần thì không có).
class TextBox {
  const TextBox(this.left, this.top, this.right, this.bottom);
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get height => bottom - top;

  /// Tỷ lệ chồng nhau theo chiều dọc so với dòng thấp hơn: ≥ 0,5 coi là cùng hàng.
  double verticalOverlap(TextBox o) {
    final h = math.min(height, o.height);
    if (h <= 0) return 0;
    return math.max(0, math.min(bottom, o.bottom) - math.max(top, o.top)) / h;
  }

  bool overlapsHorizontally(TextBox o) => math.min(right, o.right) > math.max(left, o.left);
}

class TextLine {
  const TextLine(this.text, {this.box, this.page = 0});
  final String text;
  final TextBox? box;
  final int page;
}

/// Đầu vào chung của tầng luật T2: text của email/PDF (từng dòng) hoặc kết quả OCR (dòng + bbox).
/// Dạng `OcrDocument` của E2.1: plugin OCR native chuyển kết quả sang [TextDocument] (on-device-extraction.md §3).
class TextDocument {
  TextDocument(List<TextLine> lines, {this.senderDomain, this.language})
      : lines = List.unmodifiable(lines),
        _folded = [for (final l in lines) FoldedText(l.text)];

  /// Mỗi dòng của text thuần là 1 [TextLine] (giữ cả dòng trống để biết khối).
  factory TextDocument.fromText(String text, {String? senderDomain, String? language}) => TextDocument(
        [for (final l in text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n')) TextLine(l.trimRight())],
        senderDomain: senderDomain,
        language: language,
      );

  final List<TextLine> lines;
  /// Tên miền người gửi (email) để khớp mẫu nhà cung cấp; null với ảnh/PDF.
  final String? senderDomain;
  /// Ngôn ngữ đoán được của tài liệu (BCP 47) nếu tầng trước biết.
  final String? language;
  final List<FoldedText> _folded;

  String get text => lines.map((l) => l.text).join('\n');

  FoldedText folded(int line) => _folded[line];

  /// Tài liệu con gồm các dòng [from, to) (khối của 1 chặng bay).
  TextDocument slice(int from, int to) =>
      TextDocument(lines.sublist(from, to), senderDomain: senderDomain, language: language);

  /// Tìm [anchor] (nhãn như "Mã đặt chỗ", "Booking code") trong dòng [from, to): so không dấu, không phân biệt hoa thường,
  /// chịu lỗi OCR (sai tối đa 1 ký tự mỗi 6 ký tự). Chỉ khớp trọn từ.
  List<AnchorHit> findAnchor(String anchor, {int from = 0, int? to}) {
    final needle = FoldedText(anchor).text.trim();
    if (needle.isEmpty) return const [];
    final maxErrors = needle.length ~/ 6;
    final hits = <AnchorHit>[];
    for (var i = from; i < (to ?? lines.length); i++) {
      for (final m in _folded[i].approximateMatches(needle, maxErrors)) {
        hits.add(AnchorHit(i, m.start, m.end, 1 - m.errors / needle.length));
      }
    }
    return hits;
  }

  /// Vùng giá trị bên phải anchor: phần còn lại của dòng; có bbox thì thêm các dòng cùng hàng nằm bên phải.
  List<Region> rightOf(AnchorHit hit) {
    final out = <Region>[Region(hit.line, hit.end, lines[hit.line].text.length)];
    final box = lines[hit.line].box;
    if (box != null) {
      final same = <int>[
        for (var i = 0; i < lines.length; i++)
          if (i != hit.line && lines[i].page == lines[hit.line].page && lines[i].box != null &&
              lines[i].box!.verticalOverlap(box) >= 0.5 && lines[i].box!.left >= box.right - 0.01)
            i,
      ]..sort((a, b) => lines[a].box!.left.compareTo(lines[b].box!.left));
      out.addAll(same.map((i) => Region(i, 0, lines[i].text.length)));
    }
    return out;
  }

  /// Vùng giá trị bên dưới anchor: có bbox thì các dòng phía dưới chồng theo chiều ngang (gần nhất trước);
  /// text thuần thì [maxLines] dòng không trống kế tiếp.
  List<Region> below(AnchorHit hit, {int maxLines = 2}) {
    final box = lines[hit.line].box;
    final out = <Region>[];
    if (box != null) {
      final cand = <int>[
        for (var i = 0; i < lines.length; i++)
          if (lines[i].page == lines[hit.line].page && lines[i].box != null && lines[i].box!.top >= box.bottom - 0.005 &&
              lines[i].box!.overlapsHorizontally(box))
            i,
      ]..sort((a, b) => lines[a].box!.top.compareTo(lines[b].box!.top));
      out.addAll(cand.take(maxLines).map((i) => Region(i, 0, lines[i].text.length)));
    } else {
      for (var i = hit.line + 1; i < lines.length && out.length < maxLines; i++) {
        if (lines[i].text.trim().isEmpty) continue;
        out.add(Region(i, 0, lines[i].text.length));
      }
    }
    return out;
  }

  String regionText(Region r) => lines[r.line].text.substring(r.start, r.end);
}

class AnchorHit {
  const AnchorHit(this.line, this.start, this.end, this.score);
  final int line;
  /// Vị trí trong `lines[line].text` (chuỗi gốc, không phải chuỗi đã fold).
  final int start;
  final int end;
  /// 1 = khớp đúng; thấp hơn khi có lỗi OCR.
  final double score;
}

/// Đoạn [start, end) của 1 dòng.
class Region {
  const Region(this.line, this.start, this.end);
  final int line;
  final int start;
  final int end;
}

class ApproxMatch {
  const ApproxMatch(this.start, this.end, this.errors);
  final int start;
  final int end;
  final int errors;
}

/// Chuỗi đã bỏ dấu + hạ chữ thường, giữ nguyên độ dài theo từng ký tự để ánh xạ vị trí về chuỗi gốc
/// (khác `foldForSearch` của core: không gộp khoảng trắng).
class FoldedText {
  FoldedText(String source) {
    final b = StringBuffer();
    final map = <int>[];
    final units = source.codeUnits;
    for (var i = 0; i < units.length; i++) {
      final c = units[i];
      if (c >= 0x300 && c <= 0x36f) continue; // dấu kết hợp (NFD)
      if (c >= 0xD800 && c <= 0xDBFF && i + 1 < units.length) {
        // Ký tự ngoài BMP (emoji, CJK mở rộng): giữ nguyên 2 đơn vị.
        b.writeCharCode(c);
        b.writeCharCode(units[i + 1]);
        map..add(i)..add(i + 1);
        i++;
        continue;
      }
      final ch = String.fromCharCode(c).toLowerCase();
      final f = _fold[ch] ?? (ch.length == 1 ? ch : String.fromCharCode(c));
      b.write(f[0]);
      map.add(i);
    }
    map.add(units.length);
    text = b.toString();
    _map = map;
  }

  late final String text;
  late final List<int> _map;

  /// Vị trí trong chuỗi gốc ứng với vị trí [i] của [text].
  int original(int i) => _map[i];

  /// Mọi vị trí khớp gần đúng [needle] (đã fold) với ≤ [maxErrors] lỗi (Sellers: chèn/xóa/thay), trọn từ, không chồng nhau.
  List<ApproxMatch> approximateMatches(String needle, int maxErrors) {
    final out = <ApproxMatch>[];
    if (maxErrors == 0) {
      var from = 0;
      while (true) {
        final i = text.indexOf(needle, from);
        if (i < 0) break;
        if (_wordBoundary(i, i + needle.length)) out.add(ApproxMatch(_map[i], _map[i + needle.length], 0));
        from = i + 1;
      }
      return out;
    }
    final m = needle.length, n = text.length;
    // d[j]: số lỗi nhỏ nhất của needle[0..j) khớp đoạn kết thúc tại vị trí hiện tại; s[j]: điểm bắt đầu đoạn đó.
    var prev = List<int>.generate(m + 1, (j) => j), prevStart = List<int>.filled(m + 1, 0);
    final ends = <ApproxMatch>[];
    for (var i = 1; i <= n; i++) {
      final cur = List<int>.filled(m + 1, 0), curStart = List<int>.filled(m + 1, i);
      for (var j = 1; j <= m; j++) {
        final sub = prev[j - 1] + (needle.codeUnitAt(j - 1) == text.codeUnitAt(i - 1) ? 0 : 1);
        final del = prev[j] + 1; // ký tự thừa trong text
        final ins = cur[j - 1] + 1; // thiếu ký tự trong text
        if (sub <= del && sub <= ins) {
          cur[j] = sub;
          curStart[j] = j == 1 ? i - 1 : prevStart[j - 1];
        } else if (del <= ins) {
          cur[j] = del;
          curStart[j] = prevStart[j];
        } else {
          cur[j] = ins;
          curStart[j] = curStart[j - 1];
        }
      }
      if (cur[m] <= maxErrors) ends.add(ApproxMatch(curStart[m], i, cur[m]));
      prev = cur;
      prevStart = curStart;
    }
    // Giữ đoạn ít lỗi nhất trong mỗi cụm chồng nhau, trọn từ.
    ends.sort((a, b) => a.errors != b.errors ? a.errors.compareTo(b.errors) : a.start.compareTo(b.start));
    final taken = <ApproxMatch>[];
    for (final e in ends) {
      if (!_wordBoundary(e.start, e.end)) continue;
      if (taken.any((t) => e.start < t.end && t.start < e.end)) continue;
      taken.add(e);
    }
    taken.sort((a, b) => a.start.compareTo(b.start));
    return [for (final t in taken) ApproxMatch(_map[t.start], _map[t.end], t.errors)];
  }

  bool _wordBoundary(int start, int end) {
    bool word(int i) => i >= 0 && i < text.length && _isWordChar(text.codeUnitAt(i));
    if (start >= end) return false;
    return !(word(start - 1) && word(start)) && !(word(end - 1) && word(end));
  }

  /// Chữ/số của hệ chữ có khoảng trắng giữa từ. CJK, kana không tính: "予約番号ABC123" vẫn khớp anchor "予約番号".
  static bool _isWordChar(int c) =>
      (c >= 0x30 && c <= 0x39) || (c >= 0x61 && c <= 0x7a) || (c >= 0x41 && c <= 0x5a) || (c >= 0xc0 && c != 0xd7 && c != 0xf7 && c < 0x2000);
}

final Map<String, String> _fold = () {
  const groups = {
    'a': 'àáảãạăằắẳẵặâầấẩẫậäåāą',
    'e': 'èéẻẽẹêềếểễệëēęě',
    'i': 'ìíỉĩịîïī',
    'o': 'òóỏõọôồốổỗộơờớởỡợöøō',
    'u': 'ùúủũụưừứửữựûüūů',
    'y': 'ỳýỷỹỵÿ',
    'd': 'đď',
    'c': 'çćč',
    'n': 'ñńň',
    's': 'śšşß',
    'z': 'źżž',
    'r': 'ř',
    't': 'ť',
    'l': 'ł',
    'g': 'ğ',
  };
  return {
    for (final e in groups.entries)
      for (final ch in e.value.split('')) ch: e.key,
  };
}();
