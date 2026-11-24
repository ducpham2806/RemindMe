import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:material_ui/material_ui.dart';

/// Múi giờ IANA của máy (lưu kèm thời điểm UTC, AGENTS quy tắc 5). Plugin lỗi thì dùng `Etc/GMT±N` theo độ lệch hiện tại
/// (tên IANA hợp lệ, không giả định vùng nào).
Future<String> deviceTimeZone() async {
  try {
    final id = (await FlutterTimezone.getLocalTimezone()).identifier;
    if (id.isNotEmpty) return id;
  } on Object {
    // rơi xuống dưới
  }
  return etcZoneFor(DateTime.now().timeZoneOffset);
}

/// `Etc/GMT-7` = UTC+7 (dấu ngược theo quy ước POSIX). Độ lệch lẻ phút không có tên Etc: dùng giờ tròn gần nhất.
String etcZoneFor(Duration offset) {
  final h = (offset.inMinutes / 60).round();
  if (h == 0) return 'Etc/UTC';
  return 'Etc/GMT${h > 0 ? '-' : '+'}${h.abs()}';
}

/// Vùng (ISO 3166-1) theo cài đặt máy; null nếu máy không đặt vùng. Dùng để đọc ngày số dd/mm hay mm/dd.
String? deviceRegion() => WidgetsBinding.instance.platformDispatcher.locale.countryCode;
