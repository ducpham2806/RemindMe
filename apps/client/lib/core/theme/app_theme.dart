import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Màu ngoài Material (design-system.md §10).
@immutable
class RemindColors extends ThemeExtension<RemindColors> {
  const RemindColors({required this.travel, required this.health, required this.lunar, required this.warning, required this.success});

  final Color travel, health, lunar, warning, success;

  static RemindColors of(BuildContext context) => Theme.of(context).extension<RemindColors>()!;

  @override
  RemindColors copyWith({Color? travel, Color? health, Color? lunar, Color? warning, Color? success}) => RemindColors(
        travel: travel ?? this.travel, health: health ?? this.health, lunar: lunar ?? this.lunar,
        warning: warning ?? this.warning, success: success ?? this.success);

  @override
  RemindColors lerp(RemindColors? other, double t) => other == null
      ? this
      : RemindColors(
          travel: Color.lerp(travel, other.travel, t)!, health: Color.lerp(health, other.health, t)!,
          lunar: Color.lerp(lunar, other.lunar, t)!, warning: Color.lerp(warning, other.warning, t)!,
          success: Color.lerp(success, other.success, t)!);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  Color pick((Color, Color) t) => dark ? t.$2 : t.$1;
  final scheme = ColorScheme(
    brightness: b,
    primary: pick(Tokens.primary),
    onPrimary: pick(Tokens.onPrimary),
    secondary: pick(Tokens.travel),
    onSecondary: pick(Tokens.onPrimary),
    error: pick(Tokens.danger),
    onError: pick(Tokens.onPrimary),
    surface: pick(Tokens.surface),
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

  // design-system.md §3: display 32/40, title 22/28, headline 18/24, body 16/24, bodySmall 14/20, label 13/16, caption 12/16.
  final text = TextTheme(
    headlineLarge: style(32, 40, FontWeight.w600),
    titleLarge: style(22, 28, FontWeight.w600),
    titleMedium: style(18, 24, FontWeight.w600),
    bodyLarge: style(16, 24, FontWeight.w400),
    bodyMedium: style(14, 20, FontWeight.w400),
    labelLarge: style(13, 16, FontWeight.w500),
    bodySmall: style(12, 16, FontWeight.w400),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: pick(Tokens.background),
    textTheme: text,
    dividerColor: pick(Tokens.divider),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        side: BorderSide(color: pick(Tokens.divider)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radiusLg))),
    ),
    extensions: [
      RemindColors(
        travel: pick(Tokens.travel), health: pick(Tokens.health), lunar: pick(Tokens.lunar),
        warning: pick(Tokens.warning), success: pick(Tokens.success)),
    ],
  );
}
