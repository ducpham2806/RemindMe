import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/tokens.dart';

/// Hàng nút chọn 1 trong vài lựa chọn (Figma 27, C50): mục đang chọn nền primary + dấu ✓. Các nút cao bằng nhau khi 1 nút xuống dòng.
class ChoiceButtons extends StatelessWidget {
  const ChoiceButtons({
    super.key,
    required this.keyPrefix,
    required this.value,
    required this.options,
    required this.onChanged,
    this.unselectedColor,
  });

  /// Khóa từng nút: `<keyPrefix>-<giá trị>`.
  final String keyPrefix;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;
  /// Mặc định nền trang (nút nằm trên thẻ trắng).
  final Color? unselectedColor;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: Tokens.space2),
              Expanded(child: _option(context, options[i].$1, options[i].$2)),
            ],
          ],
        ),
      );

  Widget _option(BuildContext context, String v, String text) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = v == value;
    final fg = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primary : unselectedColor ?? scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('$keyPrefix-$v'),
          onTap: selected ? null : () => onChanged(v),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 42),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.space1, vertical: Tokens.space2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[ExcludeSemantics(child: AppIcon(AppIcons.tick, size: 18, color: fg)), const SizedBox(width: Tokens.space1)],
                  Flexible(
                    child: Text(text, textAlign: TextAlign.center, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: fg)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
