import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../data/remote/account.dart';
import '../../l10n/app_localizations.dart';

/// Tên tệp xuất (security-privacy.md §6).
const exportZipName = 'remindme-export.zip', exportJsonName = 'remindme-export.json', exportIcsName = 'calendar.ics';

/// ZIP xuất dữ liệu: JSON + ICS, tạo trên máy từ DB local (gồm thay đổi chưa đồng bộ).
Future<Uint8List> buildExportZip(AppDatabase db, {required DateTime now, required String deviceTz}) async {
  final ex = DataExporter(db);
  final archive = Archive()
    ..addFile(ArchiveFile.string(exportJsonName, await ex.json(now: now)))
    ..addFile(ArchiveFile.string(exportIcsName, await ex.ics(now: now, deviceTz: deviceTz, prodId: '-//RemindMe//Export//EN')));
  return ZipEncoder().encodeBytes(archive);
}

/// Lưu tệp qua hộp thoại của hệ điều hành; trả true nếu đã lưu. Test override.
final exportSaverProvider = Provider<Future<bool> Function(String name, Uint8List bytes)>((ref) => (name, bytes) async =>
    await FilePicker.saveFile(fileName: name, bytes: bytes, mimeType: 'application/zip') != null);

TextStyle? _small(BuildContext context) =>
    Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: Theme.of(context).colorScheme.onSurfaceVariant);

/// Khung chung các màn cài đặt: AppBar, dòng phụ, thân cuộn, nút dưới cố định.
class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.title, required this.hint, required this.children, required this.bottom});
  final String title, hint;
  final List<Widget> children;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space3, Tokens.screenMargin, Tokens.space4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < bottom.length; i++) ...[if (i > 0) const SizedBox(height: Tokens.space3), bottom[i]],
              ],
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space5),
          children: [
            Text(hint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: Tokens.space5),
            for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: Tokens.space4), children[i]],
          ],
        ),
      );
}

/// Thẻ thông tin: icon + tiêu đề màu + dòng phụ, nền nhạt.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.body, required this.color, required this.background});
  final AppIcons icon;
  final String title, body;
  final Color color, background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsetsDirectional.all(Tokens.space4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: 22, color: color),
            const SizedBox(width: Tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: color)),
                  const SizedBox(height: 2),
                  Text(body, style: _small(context)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Hàng chạm được trong thẻ trắng: icon, tên (màu nhấn), dòng phụ, mũi tên.
class _LinkRow extends StatelessWidget {
  const _LinkRow({super.key, required this.icon, required this.title, required this.hint, required this.color, this.onTap});
  final AppIcons icon;
  final String title, hint;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(Tokens.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Tokens.space4),
            child: Row(
              children: [
                AppIcon(icon, size: 22, color: color),
                const SizedBox(width: Tokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: color)),
                      const SizedBox(height: 2),
                      Text(hint, style: _small(context)),
                    ],
                  ),
                ),
                if (onTap != null) AppIcon(AppIcons.chevronSmall, size: 17, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _done(BuildContext context) => context.canPop() ? context.pop() : context.go('/me');

/// Tôi → Dữ liệu & quyền riêng tư (Figma C52): giải thích, Xuất dữ liệu, Xóa tài khoản.
/// Chưa có: công tắc giọng nói trên máy, chia sẻ chẩn đoán (chưa có giọng nói, telemetry), giải thích email chuyển tiếp (chưa có worker).
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasAccount = ref.watch(accountProvider) != null;
    return _SettingsPage(
      title: l.mePrivacy,
      hint: l.privacyHint,
      bottom: [
        FilledButton.icon(
          key: const Key('privacyDone'),
          icon: AppIcon(AppIcons.tick, size: 20, color: scheme.onPrimary),
          label: Text(l.settingsDone),
          onPressed: () => _done(context),
        ),
      ],
      children: [
        Container(
          padding: const EdgeInsetsDirectional.all(18),
          decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusXl)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(AppIcons.shield, size: 26, color: scheme.primary),
              const SizedBox(height: Tokens.space3),
              Text(l.privacyHeadline, style: theme.textTheme.titleLarge),
              const SizedBox(height: Tokens.space2),
              Text(l.privacyBody, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        _LinkRow(
          key: const Key('privacyExport'),
          icon: AppIcons.file,
          title: l.privacyExport,
          hint: l.privacyExportHint,
          color: scheme.primary,
          onTap: () => context.push('/me/privacy/export'),
        ),
        _LinkRow(
          key: const Key('privacyDelete'),
          icon: AppIcons.close,
          title: l.privacyDelete,
          hint: hasAccount ? l.privacyDeleteHint : l.privacyDeleteOffline,
          color: scheme.error,
          onTap: hasAccount ? () => context.push('/me/privacy/delete') : null,
        ),
      ],
    );
  }
}

/// Xuất dữ liệu (Figma C53): tạo ZIP ngay khi mở, rồi Lưu tệp qua hộp thoại hệ điều hành.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  late final Future<Uint8List> _zip = buildExportZip(ref.read(appDatabaseProvider),
      now: ref.read(nowProvider)(), deviceTz: ref.read(deviceTimeZoneProvider));

  Future<void> _save(Uint8List bytes) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(exportSaverProvider)(exportZipName, bytes);
    if (ok) messenger.showSnackBar(SnackBar(content: Text(l.exportSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    return FutureBuilder<Uint8List>(
      future: _zip,
      builder: (context, snap) {
        final ready = snap.hasData;
        Widget fileRow(String name, String hint) => Container(
              padding: const EdgeInsetsDirectional.all(Tokens.space4),
              decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
              child: Row(
                children: [
                  AppIcon(AppIcons.file, size: 22, color: scheme.primary),
                  const SizedBox(width: Tokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        Text(hint, style: _small(context)),
                      ],
                    ),
                  ),
                  if (ready) AppIcon(AppIcons.tick, size: 18, color: colors.travel),
                ],
              ),
            );
        return _SettingsPage(
          title: l.exportTitle,
          hint: l.exportHint,
          bottom: [
            FilledButton.icon(
              key: const Key('exportSave'),
              icon: AppIcon(AppIcons.file, size: 20, color: ready ? scheme.onPrimary : null),
              label: Text(l.exportSave),
              onPressed: ready ? () => _save(snap.data!) : null,
            ),
            OutlinedButton(key: const Key('exportDone'), onPressed: () => _done(context), child: Text(l.settingsDone)),
          ],
          children: [
            Container(
              key: const Key('exportStatus'),
              padding: const EdgeInsetsDirectional.all(Tokens.space5),
              decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusXl)),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: colors.travelContainer, borderRadius: BorderRadius.circular(18)),
                    child: snap.hasError
                        ? AppIcon(AppIcons.alert, size: 30, color: scheme.error)
                        : ready
                            ? AppIcon(AppIcons.file, size: 30, color: colors.travel)
                            : const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  ),
                  const SizedBox(height: Tokens.space4),
                  Text(snap.hasError ? l.exportFailed : (ready ? l.exportReady : l.exportPreparing),
                      textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                  if (ready) ...[
                    const SizedBox(height: Tokens.space2),
                    Text(exportZipName, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            fileRow(exportJsonName, l.exportJsonHint),
            fileRow(exportIcsName, l.exportIcsHint),
            _InfoCard(
              icon: AppIcons.shield,
              title: l.exportOnDevice,
              body: l.exportOnDeviceBody,
              color: scheme.primary,
              background: scheme.primaryContainer,
            ),
            Text(l.exportPrivateNote, style: _small(context)),
          ],
        );
      },
    );
  }
}

/// Xóa tài khoản (Figma C54): phạm vi xóa, nhắc hủy gói ở cửa hàng, xuất trước, gõ từ xác nhận rồi gửi.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  bool _matches(AppLocalizations l) => _confirm.text.trim().toUpperCase() == l.deleteConfirmWord.toUpperCase();

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final account = ref.read(accountProvider);
    if (account == null) return;
    setState(() => _busy = true);
    try {
      await account.deleteAccount();
      if (mounted) context.go('/account-deleted');
    } on AccountException {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.deleteFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final info = ref.watch(accountInfoProvider).value ?? ref.watch(accountProvider)?.current;
    final email = info?.isAnonymous ?? true ? null : info?.email;
    return _SettingsPage(
      title: l.privacyDelete,
      hint: l.deleteHint,
      bottom: [
        FilledButton.tonalIcon(
          key: const Key('deleteKeep'),
          style: FilledButton.styleFrom(backgroundColor: scheme.primaryContainer, foregroundColor: scheme.primary),
          icon: AppIcon(AppIcons.back, size: 20, color: scheme.primary),
          label: Text(l.deleteKeep),
          onPressed: _busy ? null : () => _done(context),
        ),
        FilledButton.icon(
          key: const Key('deleteSend'),
          style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
          icon: _busy
              ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onError))
              : AppIcon(AppIcons.close, size: 20, color: _matches(l) ? scheme.onError : null),
          label: Text(l.deleteSend),
          onPressed: !_busy && _matches(l) ? _delete : null,
        ),
      ],
      children: [
        Container(
          padding: const EdgeInsetsDirectional.all(18),
          decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(Tokens.radiusXl)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(AppIcons.alert, size: 26, color: scheme.error),
              const SizedBox(height: Tokens.space3),
              Text(l.deleteHeadline, style: theme.textTheme.titleLarge),
              const SizedBox(height: Tokens.space2),
              Text(l.deleteBody, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        _InfoCard(
          icon: AppIcons.alert,
          title: l.deleteSubscriptionTitle,
          body: l.deleteSubscriptionBody,
          color: colors.onWarningContainer,
          background: colors.warningContainer,
        ),
        _LinkRow(
          key: const Key('deleteExport'),
          icon: AppIcons.file,
          title: l.deleteExportFirst,
          hint: l.deleteExportFirstHint,
          color: scheme.primary,
          onTap: () => context.push('/me/privacy/export'),
        ),
        Container(
          padding: const EdgeInsetsDirectional.all(Tokens.space4),
          decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.deleteAccountLabel, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: Tokens.space2),
              Text(email ?? l.deleteAnonymous, style: theme.textTheme.titleSmall),
              const SizedBox(height: Tokens.space4),
              TextField(
                key: const Key('deleteConfirm'),
                controller: _confirm,
                enabled: !_busy,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                style: theme.textTheme.titleMedium?.copyWith(color: scheme.error),
                decoration: InputDecoration(labelText: l.deleteTypeToConfirm(l.deleteConfirmWord)),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        Text(l.deleteTiming, style: _small(context)),
      ],
    );
  }
}

/// Đã nhận yêu cầu xóa (Figma C55). App đã về dùng ẩn danh với dữ liệu trống.
class AccountDeletedScreen extends StatelessWidget {
  const AccountDeletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    return PopScope(
      canPop: false,
      child: _SettingsPage(
        title: l.deletedTitle,
        hint: l.deletedHint,
        bottom: [
          FilledButton(key: const Key('deletedHome'), onPressed: () => context.go('/today'), child: Text(l.deletedHome)),
        ],
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(Tokens.space5),
            decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusXl)),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: colors.travelContainer, shape: BoxShape.circle),
                  child: AppIcon(AppIcons.tick, size: 30, color: colors.travel),
                ),
                const SizedBox(height: Tokens.space4),
                Text(l.deletedHeadline, key: const Key('deletedHeadline'), textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              ],
            ),
          ),
          _InfoCard(icon: AppIcons.clock, title: l.deleted30Title, body: l.deleted30Body, color: scheme.primary, background: scheme.primaryContainer),
          _InfoCard(icon: AppIcons.shield, title: l.deleted35Title, body: l.deleted35Body, color: colors.travel, background: colors.travelContainer),
          _InfoCard(
            icon: AppIcons.alert,
            title: l.deletedStoreTitle,
            body: l.deletedStoreBody,
            color: colors.onWarningContainer,
            background: colors.warningContainer,
          ),
        ],
      ),
    );
  }
}
