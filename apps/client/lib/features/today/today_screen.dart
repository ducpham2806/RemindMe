import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';

/// Hôm nay (UX §2.1): Quá hạn · Hôm nay · Chưa đặt giờ · Sắp tới. Dữ liệu nối với packages/data ở S2.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.navToday)),
      body: EmptyState(icon: Icons.wb_sunny_outlined, title: l.todayEmptyTitle, body: l.todayEmptyBody),
    );
  }
}
