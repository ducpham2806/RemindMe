import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// Tôi (UX §1 IA). Mục chưa làm thì tắt (bật dần theo sprint).
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = <(IconData, String, String?)>[
      (Icons.list_alt_outlined, l.meLists, '/me/lists'),
      (Icons.upload_file_outlined, l.meImportFile, '/import'),
      (Icons.inbox_outlined, l.meSuggestions, null),
      (Icons.extension_outlined, l.meIntegrations, null),
      (Icons.workspace_premium_outlined, l.mePlanUsage, null),
      (Icons.devices_outlined, l.meAccountDevices, null),
      (Icons.translate_outlined, l.meLanguageRegion, null),
      (Icons.settings_outlined, l.meSettings, null),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.navMe)),
      body: ListView(
        children: [
          for (final (icon, label, route) in rows)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              enabled: route != null,
              // Màn ngoài shell (nhập từ tệp) mở chồng lên để có nút quay lại.
              onTap: route == null ? null : () => route.startsWith('/me') ? context.go(route) : context.push(route),
            ),
        ],
      ),
    );
  }
}
