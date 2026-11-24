import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.navTrips)),
      body: EmptyState(icon: Icons.luggage_outlined, title: l.tripsEmptyTitle, body: l.tripsEmptyBody),
    );
  }
}
