import 'package:material_ui/material_ui.dart';

import '../../core/theme/tokens.dart';

/// Trạng thái trống (UX §6b): icon + tiêu đề + 1 câu hướng dẫn, căn giữa, dùng padding directional (sẵn sàng RTL).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body});

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Tokens.space6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: Tokens.space4),
              Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              if (body != null) ...[
                const SizedBox(height: Tokens.space2),
                Text(body!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
