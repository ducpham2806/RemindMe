import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';

/// Quick Add (UX §2.2). Bản S2: gõ tiêu đề, Enter/Lưu tạo việc chưa đặt giờ. Chip phân tích (V1 NLU) và mic (V2) thêm sau.
Future<void> showQuickAdd(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const QuickAddSheet(),
    );

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _text = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSave => _text.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    await ref.read(itemsRepositoryProvider).create(title: _text.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: Tokens.screenMargin,
        end: Tokens.screenMargin,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Tokens.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('quickAddField'),
            controller: _text,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: l.quickAddHint),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: Tokens.space3),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              key: const Key('quickAddSave'),
              onPressed: _canSave ? _save : null,
              child: Text(l.quickAddSave),
            ),
          ),
        ],
      ),
    );
  }
}
