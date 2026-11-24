import 'package:material_ui/material_ui.dart';

/// Window size class Material 3 (architecture/multi-platform.md §2 quy tắc 4).
enum WindowSize {
  compact,
  medium,
  expanded;

  static const mediumMin = 600.0;
  static const expandedMin = 840.0;

  static WindowSize fromWidth(double w) => w >= expandedMin ? expanded : (w >= mediumMin ? medium : compact);

  static WindowSize of(BuildContext context) => fromWidth(MediaQuery.sizeOf(context).width);
}
