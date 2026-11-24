import 'package:material_ui/material_ui.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// Quick Add (UX §2.2). NLU (V1) và mic (V2) nối vào ở S2/S4.
Future<void> showQuickAdd(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const QuickAddSheet(),
    );

class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: Tokens.screenMargin,
        end: Tokens.screenMargin,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Tokens.space4,
      ),
      child: TextField(
        key: const Key('quickAddField'),
        autofocus: true,
        decoration: InputDecoration(hintText: l.quickAddHint),
      ),
    );
  }
}
