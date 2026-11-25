import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Icon nét đơn sắc lấy từ file Figma (assets/icons, design-system.md §5). Tô theo màu theme khi vẽ, nên 1 tệp dùng cho cả sáng và tối.
enum AppIcons {
  today,
  calendar,
  trip,
  user,
  search,
  plus,
  check,
  back,
  chevron,
  chevronSmall,
  plane,
  hotel,
  globe;

  String get asset => 'assets/icons/${switch (this) {
        chevronSmall => 'chevron_small',
        _ => name,
      }}.svg';

  /// Icon chỉ hướng: lật ngang khi viết từ phải sang trái.
  bool get directional => this == back || this == chevron || this == chevronSmall;
}

class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.color, this.size, this.semanticLabel});

  final AppIcons icon;
  final Color? color;
  /// Mặc định theo kích thước gốc của SVG (22-24).
  final double? size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(
      icon.asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
    if (!icon.directional || Directionality.of(context) == TextDirection.ltr) return svg;
    return Transform.flip(flipX: true, child: svg);
  }
}
