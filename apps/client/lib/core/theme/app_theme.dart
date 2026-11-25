import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Màu ngoài Material (design-system.md §10).
@immutable
class RemindColors extends ThemeExtension<RemindColors> {
  const RemindColors({
    required this.travel,
    required this.health,
    required this.lunar,
    required this.warning,
    required this.success,
    required this.primaryTrack,
    required this.checkOutline,
    required this.checkOverdue,
  });

  final Color travel, health, lunar, warning, success, primaryTrack, checkOutline, checkOverdue;

  static RemindColors of(BuildContext context) => Theme.of(context).extension<RemindColors>()!;

  @override
  RemindColors copyWith({
    Color? travel,
    Color? health,
    Color? lunar,
    Color? warning,
    Color? success,
    Color? primaryTrack,
    Color? checkOutline,
    Color? checkOverdue,
  }) =>
      RemindColors(
        travel: travel ?? this.travel,
        health: health ?? this.health,
        lunar: lunar ?? this.lunar,
        warning: warning ?? this.warning,
        success: success ?? this.success,
        primaryTrack: primaryTrack ?? this.primaryTrack,
        checkOutline: checkOutline ?? this.checkOutline,
        checkOverdue: checkOverdue ?? this.checkOverdue,
      );

  @override
  RemindColors lerp(RemindColors? other, double t) => other == null
      ? this
      : RemindColors(
          travel: Color.lerp(travel, other.travel, t)!, health: Color.lerp(health, other.health, t)!,
          lunar: Color.lerp(lunar, other.lunar, t)!, warning: Color.lerp(warning, other.warning, t)!,
          success: Color.lerp(success, other.success, t)!, primaryTrack: Color.lerp(primaryTrack, other.primaryTrack, t)!,
          checkOutline: Color.lerp(checkOutline, other.checkOutline, t)!, checkOverdue: Color.lerp(checkOverdue, other.checkOverdue, t)!);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  Color pick((Color, Color) t) => dark ? t.$2 : t.$1;
  final scheme = ColorScheme(
    brightness: b,
    primary: pick(Tokens.primary),
    onPrimary: pick(Tokens.onPrimary),
    primaryContainer: pick(Tokens.primaryContainer),
    onPrimaryContainer: pick(Tokens.textPrimary),
    secondary: pick(Tokens.travel),
    onSecondary: pick(Tokens.onPrimary),
    error: pick(Tokens.danger),
    onError: pick(Tokens.onPrimary),
    surface: pick(Tokens.surface),
    surfaceContainerLowest: pick(Tokens.background),
    onSurface: pick(Tokens.textPrimary),
    onSurfaceVariant: pick(Tokens.textSecondary),
    outlineVariant: pick(Tokens.divider),
  );

  TextStyle style(double size, double line, FontWeight w) => TextStyle(
        fontFamily: Tokens.fontFamily,
        fontFamilyFallback: Tokens.fontFallback,
        fontSize: size,
        height: (line / size) < Tokens.minLineHeight ? Tokens.minLineHeight : line / size,
        fontWeight: w,
        color: scheme.onSurface,
      );

  // design-system.md §3 (theo Figma): tiêu đề màn 30/44, thẻ 16/23, tên việc 14/20 medium, giờ 13/19, nhóm 12/17, phụ đề 11/16, nhãn tab 10/15.
  final text = TextTheme(
    headlineLarge: style(30, 44, FontWeight.w600),
    titleLarge: style(22, 28, FontWeight.w600),
    titleMedium: style(16, 23, FontWeight.w600),
    titleSmall: style(14, 20, FontWeight.w500),
    bodyLarge: style(16, 24, FontWeight.w400),
    bodyMedium: style(14, 20, FontWeight.w400),
    bodySmall: style(12, 17, FontWeight.w400).copyWith(color: scheme.onSurfaceVariant),
    labelLarge: style(12, 17, FontWeight.w600),
    labelMedium: style(13, 19, FontWeight.w600),
    labelSmall: style(11, 16, FontWeight.w500),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: pick(Tokens.background),
    textTheme: text,
    dividerColor: pick(Tokens.divider),
    cardTheme: CardThemeData(
      elevation: 0,
      color: pick(Tokens.surface),
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd)),
    ),
    appBarTheme: AppBarTheme(backgroundColor: pick(Tokens.background), surfaceTintColor: Colors.transparent, scrolledUnderElevation: 0),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radiusLg))),
    ),
    extensions: [
      RemindColors(
        travel: pick(Tokens.travel), health: pick(Tokens.health), lunar: pick(Tokens.lunar),
        warning: pick(Tokens.warning), success: pick(Tokens.success), primaryTrack: pick(Tokens.primaryTrack),
        checkOutline: pick(Tokens.checkOutline), checkOverdue: pick(Tokens.checkOverdue)),
    ],
  );
}
