import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/tokens.dart';

/// Hàng thiết lập trong thẻ trắng (Figma 04): icon primary, nhãn nhỏ, giá trị (chữ hoặc widget), mũi tên khi cả hàng chạm được.
class SettingRow extends StatelessWidget {
  const SettingRow({super.key, required this.icon, required this.label, this.value, this.child, this.onTap, this.enabled = true});
  final AppIcons icon;
  final String label;
  final String? value;
  /// Thay [value] khi giá trị có nhiều phần chạm riêng (ngày, giờ, chip nhắc).
  final Widget? child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(14),
          child: Row(
            children: [
              AppIcon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    child ?? Text(value ?? '', style: theme.textTheme.titleSmall),
                  ],
                ),
              ),
              if (onTap != null && enabled) AppIcon(AppIcons.chevronSmall, size: 16, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phần giá trị chạm được bên trong [SettingRow] (ngày, giờ): chữ màu primary.
class SettingValueButton extends StatelessWidget {
  const SettingValueButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(Tokens.radiusSm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 2, horizontal: 2),
        child: Text(label, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
      ),
    );
  }
}
