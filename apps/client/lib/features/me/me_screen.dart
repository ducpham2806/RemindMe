import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// Tôi (UX §1 IA). Mỗi mục mở màn riêng ở các sprint sau.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = <(IconData, String)>[
      (Icons.list_alt_outlined, l.meLists),
      (Icons.inbox_outlined, l.meSuggestions),
      (Icons.extension_outlined, l.meIntegrations),
      (Icons.workspace_premium_outlined, l.mePlanUsage),
      (Icons.devices_outlined, l.meAccountDevices),
      (Icons.translate_outlined, l.meLanguageRegion),
      (Icons.settings_outlined, l.meSettings),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.navMe)),
      body: ListView(
        children: [
          for (final (icon, label) in rows)
            ListTile(leading: Icon(icon), title: Text(label), trailing: const Icon(Icons.chevron_right), onTap: () {}),
        ],
      ),
    );
  }
}
