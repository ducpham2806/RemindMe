import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.navCalendar)),
      body: EmptyState(icon: Icons.calendar_month_outlined, title: l.calendarEmptyTitle),
    );
  }
}
