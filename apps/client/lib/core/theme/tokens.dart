import 'package:material_ui/material_ui.dart';

/// Token thiết kế. Nguồn chuẩn giá trị: docs/uiux/design-system.md §2-4. Widget không dùng mã màu trực tiếp.
abstract final class Tokens {
  // §2 màu: (light, dark)
  static const primary = (Color(0xFF2F6BFF), Color(0xFF8AA9FF));
  static const onPrimary = (Color(0xFFFFFFFF), Color(0xFF0B1B4D));
  static const surface = (Color(0xFFFFFFFF), Color(0xFF121417));
  static const background = (Color(0xFFF6F7F9), Color(0xFF0B0C0E));
  static const textPrimary = (Color(0xFF14171C), Color(0xFFECEEF2));
  static const textSecondary = (Color(0xFF5B6472), Color(0xFFA2AAB7));
  static const divider = (Color(0xFFE4E7EC), Color(0xFF2A2E35));
  static const danger = (Color(0xFFD93A3A), Color(0xFFFF7A7A));
  static const warning = (Color(0xFFC98A00), Color(0xFFFFC94D));
  static const success = (Color(0xFF1E9E62), Color(0xFF5FD39A));
  static const travel = (Color(0xFF0E9AA7), Color(0xFF55D6E0));
  static const health = (Color(0xFFC2410C), Color(0xFFFF9F6E));
  static const lunar = (Color(0xFFB4235A), Color(0xFFFF8DB8));

  // §4 khoảng cách (lưới 4dp), bo góc
  static const space1 = 4.0, space2 = 8.0, space3 = 12.0, space4 = 16.0, space5 = 20.0, space6 = 24.0, space8 = 32.0, space10 = 40.0;
  static const screenMargin = space4;
  static const radiusSm = 8.0, radiusMd = 12.0, radiusLg = 20.0;

  // §3 chữ: font Latin Be Vietnam Pro (bundle ở S1-S2, xem STATE), hệ chữ khác dùng font hệ thống theo thứ tự này.
  static const fontFamily = 'Be Vietnam Pro';
  static const fontFallback = [
    'PingFang SC', 'Noto Sans CJK SC', 'Thonburi', 'Noto Sans Thai', 'SF Arabic', 'Noto Sans Arabic',
    'Kohinoor Devanagari', 'Noto Sans Devanagari',
  ];
  /// Line-height tối thiểu để dấu chồng (ệ, ẫ, tiếng Thái) không bị cắt.
  static const minLineHeight = 1.35;
}
