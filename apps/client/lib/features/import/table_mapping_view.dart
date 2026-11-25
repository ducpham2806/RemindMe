import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'import_decode.dart';

/// Trường người dùng chọn được cho 1 cột (assignee chỉ để nhận ra cột, không nhập nên không có ở đây).
const mappableFields = [
  TableField.title,
  TableField.date,
  TableField.time,
  TableField.notes,
  TableField.priority,
  TableField.status,
  TableField.location,
  TableField.list,
];

String tableFieldLabel(AppLocalizations l, TableField? f) => switch (f) {
      TableField.title => l.importFieldTitle,
      TableField.date => l.importFieldDate,
      TableField.time => l.importFieldTime,
      TableField.notes => l.importFieldNotes,
      TableField.priority => l.importFieldPriority,
      TableField.status => l.importFieldStatus,
      TableField.location => l.importFieldLocation,
      TableField.list => l.importFieldList,
      _ => l.importFieldSkip,
    };

/// Tên cột kiểu bảng tính: 0 → A, 25 → Z, 26 → AA.
String columnLetter(int c) {
  var n = c + 1;
  final letters = <int>[];
  while (n > 0) {
    letters.insert(0, 0x41 + (n - 1) % 26);
    n = (n - 1) ~/ 26;
  }
  return String.fromCharCodes(letters);
}

/// Ghép [column] vào [field] (null = bỏ qua). Trường đã ở cột khác thì chuyển sang cột này; cột chỉ giữ 1 trường.
Map<TableField, int> remapColumn(Map<TableField, int> columns, int column, TableField? field) => {
      for (final e in columns.entries)
        if (e.value != column && e.key != field) e.key: e.value,
      ?field: column,
    };

/// Màn Ghép cột bảng tính (Figma 18, on-device-extraction §6 bước 5): tệp + trang tính, thứ tự ngày, dòng tiêu đề,
/// cột trong tệp → trường của app, xem trước 10 dòng, "Nhớ cách ghép" theo chữ ký dòng tiêu đề.
class TableMappingView extends StatelessWidget {
  const TableMappingView({
    super.key,
    required this.request,
    required this.preview,
    required this.remember,
    required this.onRemember,
    required this.onRequest,
  });

  final ImportRequest request;
  final ImportPreview preview;
  final bool remember;
  final ValueChanged<bool> onRemember;
  /// Đọc lại tệp với lựa chọn mới.
  final ValueChanged<ImportRequest> onRequest;

  static const _maxColumns = 30;
  static const _previewRows = 10;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final table = preview.table!;
    const gap = SizedBox(height: Tokens.space4);
    final ambiguous = preview.dateOrderAmbiguous && request.dateOrder == null;
    final orderLabel = ambiguous
        ? l.importMapOrderPick
        : switch (preview.dateOrder) {
            'mdy' => l.importMapOrderMdy,
            'ymd' => l.importMapOrderYmd,
            _ => l.importMapOrderDmy,
          };
    final fieldOf = {for (final e in table.columns.entries) e.value: e.key};
    final shown = preview.candidates.take(_previewRows).toList();
    final hasTitle = table.columns.containsKey(TableField.title);

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space5),
      children: [
        Text(l.importMapHint, style: theme.textTheme.bodySmall),
        gap,
        _card(
          context,
          child: InkWell(
            key: const Key('importSheet'),
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
            onTap: preview.sheetNames.length > 1 ? () => _pickSheet(context) : null,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(Tokens.space4),
              child: Row(
                children: [
                  Icon(Icons.table_chart_outlined, color: colors.success, size: 26),
                  const SizedBox(width: Tokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          [
                            if (preview.sheetNames.isNotEmpty) l.importMapSheet(preview.sheetNames[preview.sheetIndex]),
                            l.importMapRows(table.dataRows),
                          ].join(' · '),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (preview.sheetNames.length > 1) Icon(Icons.expand_more, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Tokens.space3),
        Wrap(
          spacing: Tokens.space2,
          runSpacing: Tokens.space2,
          children: [
            _chip(
              context,
              key: const Key('importDateOrder'),
              label: orderLabel,
              warning: ambiguous,
              onTap: () => _pickOrder(context),
            ),
            _chip(
              context,
              key: const Key('importHeader'),
              label: l.importMapHeader,
              selected: table.hasHeader,
              onTap: () => onRequest(request.copyWith(hasHeader: !table.hasHeader, columns: table.columns)),
            ),
          ],
        ),
        if (table.remembered) ...[
          const SizedBox(height: Tokens.space2),
          Text(l.importMapRemembered, key: const Key('importRemembered'), style: theme.textTheme.bodySmall),
        ],
        gap,
        _card(
          context,
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.space4, Tokens.space3, Tokens.space4, Tokens.space2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(l.importMapFileColumn, style: theme.textTheme.labelSmall)),
                  Text(l.importMapAppField, style: theme.textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: Tokens.space2),
              for (var c = 0; c < table.labels.length && c < _maxColumns; c++)
                _mappingRow(context, c, table.labels[c] ?? l.importMapColumn(columnLetter(c)), fieldOf[c], table),
            ],
          ),
        ),
        if (!hasTitle) ...[
          const SizedBox(height: Tokens.space2),
          Text(l.importMapNoTitle, key: const Key('importMapNoTitle'), style: theme.textTheme.bodySmall?.copyWith(color: colors.onWarningContainer)),
        ],
        gap,
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l.importMapPreview(shown.length), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.space2, vertical: Tokens.space1),
              decoration: BoxDecoration(color: colors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.radiusSm)),
              child: Text(l.importMapValid(preview.candidates.length),
                  key: const Key('importMapValid'), style: theme.textTheme.labelSmall?.copyWith(color: colors.success)),
            ),
          ],
        ),
        const SizedBox(height: Tokens.space3),
        if (shown.isNotEmpty) _previewTable(context, shown),
        if (table.signature != null) ...[
          const SizedBox(height: Tokens.space2),
          MergeSemantics(
            child: Row(
              children: [
                Checkbox(key: const Key('importRemember'), value: remember, onChanged: (v) => onRemember(v ?? false)),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onRemember(!remember),
                    child: Text(l.importMapRemember, style: theme.textTheme.bodySmall),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _card(BuildContext context, {required Widget child, EdgeInsetsGeometry? padding}) => Container(
        padding: padding,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
        child: child,
      );

  Widget _chip(BuildContext context, {required Key key, required String label, bool selected = true, bool warning = false, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final bg = warning ? colors.warningContainer : (selected ? scheme.primaryContainer : scheme.surface);
    final fg = warning ? colors.onWarningContainer : (selected ? scheme.primary : scheme.onSurfaceVariant);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.space3, vertical: Tokens.space2),
            child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }

  Widget _mappingRow(BuildContext context, int c, String label, TableField? field, TableInfo table) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: l.importMapColumnSemantics(label, tableFieldLabel(l, field)),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: ExcludeSemantics(child: Text(label, style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis))),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.space2),
              child: Icon(Icons.arrow_forward, size: 18, color: scheme.onSurfaceVariant, textDirection: Directionality.of(context)),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 128),
              padding: const EdgeInsetsDirectional.fromSTEB(Tokens.space2, 6, Tokens.space1, 6),
              decoration: BoxDecoration(
                color: field == null ? scheme.surfaceContainerLowest : scheme.primaryContainer,
                borderRadius: BorderRadius.circular(Tokens.radiusSm),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TableField?>(
                  key: Key('importColumn-$c'),
                  value: field,
                  isDense: true,
                  borderRadius: BorderRadius.circular(Tokens.radiusMd),
                  style: theme.textTheme.bodyMedium?.copyWith(color: field == null ? scheme.onSurfaceVariant : scheme.primary),
                  iconEnabledColor: field == null ? scheme.onSurfaceVariant : scheme.primary,
                  items: [
                    for (final f in [...mappableFields, null])
                      DropdownMenuItem<TableField?>(value: f, child: Text(tableFieldLabel(l, f))),
                  ],
                  onChanged: (f) {
                    if (f == field) return;
                    onRequest(request.copyWith(columns: remapColumn(table.columns, c, f), hasHeader: table.hasHeader));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewTable(BuildContext context, List<Candidate> rows) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final h24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final mat = MaterialLocalizations.of(context);
    (String, String) split(Candidate c) {
      final raw = c.fields.due?.local;
      if (raw == null) return ('', '');
      final dt = DateTime.tryParse(raw);
      if (dt == null) return ('', '');
      final date = DateFormat.Md(locale).format(dt);
      final time = raw.contains('T') ? mat.formatTimeOfDay(TimeOfDay(hour: dt.hour, minute: dt.minute), alwaysUse24HourFormat: h24) : '';
      return (date, time);
    }

    Widget row(List<String> cells, {bool header = false, Key? key}) {
      final style = header
          ? theme.textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)
          : theme.textTheme.bodyMedium;
      return Container(
        key: key,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.space2, vertical: 6),
        decoration: header ? BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusSm)) : null,
        child: Row(
          children: [
            Expanded(flex: 5, child: Text(cells[0], style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text(cells[1], style: style)),
            Expanded(flex: 2, child: Text(cells[2], style: style)),
          ],
        ),
      );
    }

    return _card(
      context,
      padding: const EdgeInsetsDirectional.all(Tokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row([l.importFieldTitle, l.importFieldDate, l.importFieldTime], header: true),
          for (final (i, c) in rows.indexed)
            row([c.fields.title ?? '', split(c).$1, split(c).$2], key: Key('importMapRow-$i')),
        ],
      ),
    );
  }

  Future<void> _pickSheet(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final i = await showAppSheet<int>(
      context,
      (context) => AppSheet(
        title: l.importSheet,
        children: [
          for (var i = 0; i < preview.sheetNames.length; i++)
            SheetOption(
              key: Key('importSheet-$i'),
              icon: AppIcons.list,
              title: preview.sheetNames[i],
              selected: i == preview.sheetIndex,
              onTap: () => Navigator.pop(context, i),
            ),
        ],
      ),
    );
    if (i != null && i != preview.sheetIndex) onRequest(request.copyWith(sheetIndex: i));
  }

  Future<void> _pickOrder(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final order = await showAppSheet<String>(
      context,
      (context) => AppSheet(
        title: l.importDateOrderQuestion,
        children: [
          for (final (o, label) in [('dmy', l.importMapOrderDmy), ('mdy', l.importMapOrderMdy), ('ymd', l.importMapOrderYmd)])
            SheetOption(
              key: Key('importOrder-$o'),
              icon: AppIcons.calendar,
              title: label,
              selected: request.dateOrder == o || (request.dateOrder == null && !preview.dateOrderAmbiguous && preview.dateOrder == o),
              onTap: () => Navigator.pop(context, o),
            ),
        ],
      ),
    );
    if (order != null) onRequest(request.copyWith(dateOrder: order));
  }
}
