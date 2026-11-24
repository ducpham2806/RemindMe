/// HTML → chữ thuần cho tầng luật T2 (email đặt chỗ không có JSON-LD). Không dựng DOM: bỏ script/style/head,
/// thẻ khối thành xuống dòng, ô bảng thành tab, giải mã thực thể. Đủ cho email; không dùng để hiển thị.
String htmlToText(String html) {
  var s = html
      .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
      .replaceAll(RegExp(r'<(script|style|head|title)\b[\s\S]*?</\1\s*>', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ');
  s = s
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</?(p|div|tr|li|h[1-6]|table|ul|ol|section|article|header|footer|blockquote)\b[^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</?(td|th)\b[^>]*>', caseSensitive: false), '\t')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  s = decodeHtmlEntities(s);
  final lines = [
    for (final l in s.split('\n'))
      l.replaceAll('\u00A0', ' ').replaceAll(RegExp(r'[ ]{2,}'), ' ').replaceAll(RegExp(r'\s*\t\s*'), '\t').replaceAll(RegExp(r'^\t+|\t+$'), '').trim(),
  ];
  return lines.where((l) => l.isNotEmpty).join('\n');
}

const _named = {
  'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'nbsp': '\u00A0', 'ndash': '–', 'mdash': '—',
  'rsquo': '’', 'lsquo': '‘', 'rdquo': '”', 'ldquo': '“', 'hellip': '…', 'euro': '€', 'pound': '£', 'yen': '¥',
  'copy': '©', 'reg': '®', 'middot': '·', 'bull': '•', 'rarr': '→', 'times': '×',
};

String decodeHtmlEntities(String s) => s.replaceAllMapped(RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);'), (m) {
      final e = m[1]!;
      if (e.startsWith('#')) {
        final code = e[1] == 'x' || e[1] == 'X' ? int.tryParse(e.substring(2), radix: 16) : int.tryParse(e.substring(1));
        return code == null || code > 0x10FFFF ? m[0]! : String.fromCharCode(code);
      }
      return _named[e.toLowerCase()] ?? m[0]!;
    });
