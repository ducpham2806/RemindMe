import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/tokens.dart';

/// Mở bottom sheet theo Figma 05-08: nền surface, bo 24 ở trên, tay nắm, cao theo nội dung (tối đa gần cả màn).
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: builder,
    );

/// Khung nội dung sheet: tiêu đề + nút đóng, phần thân cuộn được (các khối cách 16), nút chính cố định ở đáy.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.title,
    required this.children,
    this.primaryLabel,
    this.primaryIcon = AppIcons.tick,
    this.onPrimary,
    this.primaryKey,
  });

  final String title;
  final List<Widget> children;
  final String? primaryLabel;
  final AppIcons primaryIcon;
  /// null: nút chính mờ (chưa chọn đủ).
  final VoidCallback? onPrimary;
  final Key? primaryKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(Tokens.space5, 0, Tokens.space2, Tokens.space2),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, height: 29 / 20, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  IconButton(
                    key: const Key('sheetClose'),
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: AppIcon(AppIcons.close, size: 22, color: scheme.onSurface),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(Tokens.space5, Tokens.space2, Tokens.space5, Tokens.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      if (i > 0) const SizedBox(height: Tokens.space4),
                      children[i],
                    ],
                  ],
                ),
              ),
            ),
            if (primaryLabel != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Tokens.space5, 0, Tokens.space5, Tokens.space4),
                child: FilledButton.icon(
                  key: primaryKey,
                  onPressed: onPrimary,
                  icon: AppIcon(primaryIcon, size: 20, color: onPrimary == null ? null : scheme.onPrimary),
                  label: Text(primaryLabel!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Một lựa chọn trong sheet (Figma 06, 08): icon, tên, dòng phụ, giá trị bên phải; đang chọn thì nền nhạt màu nhấn + dấu ✓.
class SheetOption extends StatelessWidget {
  const SheetOption({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.selected = false,
    this.onTap,
    this.filled = true,
    this.accent,
    this.accentContainer,
  });

  final AppIcons icon;
  final String title;
  final String? subtitle;
  /// Chữ bên phải (giờ hoãn tới).
  final String? trailing;
  final bool selected;
  final VoidCallback? onTap;
  /// false: không nền khi chưa chọn (danh sách hoãn nhắc).
  final bool filled;
  /// Mặc định primary / primaryContainer; âm lịch dùng màu lunar.
  final Color? accent, accentContainer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = this.accent ?? scheme.primary;
    final bg = selected ? accentContainer ?? scheme.primaryContainer : (filled ? scheme.surfaceContainerLowest : Colors.transparent);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(Tokens.space3),
              child: Row(
                children: [
                  AppIcon(icon, size: 20, color: selected ? accent : scheme.onSurfaceVariant),
                  const SizedBox(width: Tokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? accent : scheme.onSurface)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: Tokens.space2),
                    Text(trailing!, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, color: selected ? accent : scheme.onSurfaceVariant)),
                  ],
                  const SizedBox(width: Tokens.space2),
                  if (selected)
                    ExcludeSemantics(child: AppIcon(AppIcons.tick, size: 18, color: accent))
                  else if (onTap != null)
                    AppIcon(AppIcons.chevronSmall, size: 18, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hàng nút chọn nhanh nhỏ (Figma 05 "Hôm nay / Ngày mai / Cuối tuần", 07 "Mùng 1 / Ngày rằm / Ngày riêng").
class SheetChips extends StatelessWidget {
  const SheetChips({super.key, required this.keyPrefix, required this.options, required this.selected, required this.onTap, this.accent, this.accentContainer});
  final String keyPrefix;
  /// (giá trị, nhãn).
  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String> onTap;
  final Color? accent, accentContainer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (value, label)) in options.indexed) ...[
            if (i > 0) const SizedBox(width: Tokens.space2),
            Expanded(
              child: Semantics(
                selected: value == selected,
                button: true,
                child: Material(
                  color: value == selected ? accentContainer ?? scheme.primaryContainer : scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(9),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: Key('$keyPrefix-$value'),
                    onTap: () => onTap(value),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.space1, vertical: 10),
                      child: Center(
                        child: Text(label,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: value == selected ? accent ?? scheme.primary : scheme.onSurfaceVariant)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
