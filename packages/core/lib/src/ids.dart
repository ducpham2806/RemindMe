import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

final _random = Random.secure();

/// UUIDv7 (RFC 9562): 48 bit thời gian ms + ngẫu nhiên. Id do client sinh (system-architecture.md §4),
/// tăng dần theo thời gian nên index B-tree trên server không bị phân mảnh.
String uuidV7({int? nowMillis}) {
  final ms = nowMillis ?? DateTime.now().millisecondsSinceEpoch;
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  for (var i = 0; i < 6; i++) {
    bytes[i] = (ms >> (8 * (5 - i))) & 0xff;
  }
  bytes[6] = (bytes[6] & 0x0f) | 0x70; // version 7
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10
  return _format(bytes);
}

/// Id list Inbox của user: giống hệt `md5(user_id || ':inbox')::uuid` trong `profile_init`,
/// nên máy offline tự tính ra cùng id và không tạo Inbox trùng.
String inboxListId(String userId) {
  final digest = md5.convert(utf8.encode('${userId.toLowerCase()}:inbox')).bytes;
  return _format(digest);
}

String _format(List<int> b) {
  final hex = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
