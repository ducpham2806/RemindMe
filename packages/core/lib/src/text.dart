/// Chuẩn hóa chuỗi để so khớp/tìm kiếm không phân biệt hoa thường và dấu (tiếng Việt và Latin có dấu).
/// "Công Việc" → "cong viec", "Đà Lạt" → "da lat", "Ñandú" → "nandu". Hệ chữ khác (CJK, Thái...) giữ nguyên, chỉ hạ chữ thường.
String foldForSearch(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    // Dấu kết hợp (chuỗi dạng NFD, ví dụ từ một số bàn phím/STT): bỏ.
    if (r >= 0x300 && r <= 0x36f) continue;
    final c = String.fromCharCode(r);
    b.write(_fold[c] ?? c);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
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
    's': 'śšş',
    'z': 'źżž',
    'r': 'ř',
    't': 'ť',
    'l': 'ł',
    'g': 'ğ',
  };
  return {
    for (final e in groups.entries)
      for (final ch in e.value.split('')) ch: e.key,
    'ß': 'ss',
  };
}();
