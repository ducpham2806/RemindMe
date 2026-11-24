import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// Hỏi 1 dòng chữ (đặt tên list, sửa tên mục ở màn Xem lại). Trả chuỗi đã trim, null nếu hủy hoặc rỗng.
Future<String?> askText(BuildContext context, {required String title, String? initial, String? hint, Key? fieldKey}) async {
  final v = await showDialog<String>(
      context: context, builder: (_) => _TextDialog(title: title, initial: initial, hint: hint, fieldKey: fieldKey));
  final t = v?.trim();
  return t == null || t.isEmpty ? null : t;
}

/// Dialog tự giữ controller: TextField còn được vẽ trong lúc dialog đóng (animation), nên không được dispose sớm hơn widget.
class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title, this.initial, this.hint, this.fieldKey});
  final String title;
  final String? initial;
  final String? hint;
  final Key? fieldKey;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, _controller.text), child: Text(l.quickAddSave)),
      ],
    );
  }
}
