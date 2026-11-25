import 'dart:async';

import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../data/remote/account.dart';
import '../../l10n/app_localizations.dart';

String accountErrorText(AppLocalizations l, AccountError e) => switch (e) {
      AccountError.invalidEmail => l.accountErrorInvalidEmail,
      AccountError.rateLimited => l.accountErrorRateLimited,
      AccountError.invalidCode => l.accountErrorInvalidCode,
      AccountError.network => l.accountErrorNetwork,
      AccountError.unknown => l.accountErrorUnknown,
    };

Widget _card(BuildContext context, {required Widget child, Color? color, Key? key}) => Container(
      key: key,
      padding: const EdgeInsetsDirectional.all(Tokens.space4),
      decoration: BoxDecoration(color: color ?? Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
      child: child,
    );

Widget _primary(BuildContext context, {required Key key, required String label, required VoidCallback? onPressed, bool busy = false}) =>
    FilledButton(
      key: key,
      onPressed: busy ? null : onPressed,
      child: busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(label),
    );

/// Đăng nhập bằng email (Figma C35). Google/Apple thêm khi có cấu hình OAuth.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.email});
  final String? email;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final _email = TextEditingController(text: widget.email ?? ref.read(accountProvider)?.current?.email);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _valid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  Future<void> _send() async {
    final account = ref.read(accountProvider);
    if (account == null || !_valid) return;
    final l = AppLocalizations.of(context);
    final email = _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final mode = await account.sendCode(email);
      if (!mounted) return;
      unawaited(context.push(Uri(path: '/login/verify', queryParameters: {'email': email, 'mode': mode.name}).toString()));
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = accountErrorText(l, e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.loginTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space5),
        children: [
          Text(l.loginHeadline, style: theme.textTheme.headlineLarge),
          const SizedBox(height: Tokens.space3),
          Text(l.loginBody(l.appTitle), style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: Tokens.space6),
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  AppIcon(AppIcons.mail, size: 16, color: scheme.primary),
                  const SizedBox(width: Tokens.space2),
                  Text(l.loginEmailLabel, style: theme.textTheme.titleSmall),
                ]),
                TextField(
                  key: const Key('loginEmail'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(border: InputBorder.none, filled: false, errorText: _error),
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _send(),
                ),
                Text(l.loginEmailHint, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: Tokens.space5),
          _primary(context, key: const Key('loginSend'), label: l.loginSendCode, onPressed: _valid ? _send : null, busy: _busy),
          const SizedBox(height: Tokens.space3),
          TextButton(
            key: const Key('loginSkip'),
            onPressed: () => context.canPop() ? context.pop() : context.go('/today'),
            child: Text(l.loginSkip),
          ),
        ],
      ),
    );
  }
}

/// Nhập mã gửi qua email (Figma C36).
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key, required this.email, required this.mode});
  final String email;
  final OtpMode mode;

  static const resendAfter = 60;

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  int _wait = VerifyScreen.resendAfter;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _wait = VerifyScreen.resendAfter;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _wait--);
      if (_wait <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    final l = AppLocalizations.of(context);
    try {
      await ref.read(accountProvider)!.resend(widget.email, widget.mode);
      if (mounted) setState(_startTimer);
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = accountErrorText(l, e.code));
    }
  }

  Future<void> _verify() async {
    final account = ref.read(accountProvider)!;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await account.verify(widget.email, _code.text, widget.mode);
      if (!mounted) return;
      if (!r.switched) {
        messenger.showSnackBar(SnackBar(content: Text(widget.mode == OtpMode.link ? l.accountLinked : l.accountSwitched)));
        router.go(widget.mode == OtpMode.link ? '/me/account' : '/today');
        return;
      }
      setState(() => _busy = false);
      if (await _confirmSwitch(r.willReplace)) {
        await account.finishSwitch();
        messenger.showSnackBar(SnackBar(content: Text(l.accountSwitched)));
        router.go('/today');
      } else {
        await account.cancelSwitch();
        if (mounted && context.canPop()) context.pop();
      }
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = accountErrorText(l, e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Dữ liệu trên máy sẽ được thay; các máy trong [will] sẽ bị đăng xuất (UX §3.7).
  Future<bool> _confirmSwitch(List<SessionInfo> will) async {
    final l = AppLocalizations.of(context);
    final devices = will.map((s) => s.deviceModel ?? s.platform ?? '').where((d) => d.isNotEmpty).join(', ');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.switchTitle(widget.email)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.switchBodyData),
            if (devices.isNotEmpty) ...[const SizedBox(height: Tokens.space2), Text(l.switchBodyDevices(devices))],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(key: const Key('switchConfirm'), onPressed: () => Navigator.pop(context, true), child: Text(l.switchConfirm)),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.verifyTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space5),
        children: [
          AppIcon(AppIcons.mail, size: 24, color: scheme.primary),
          const SizedBox(height: Tokens.space3),
          Text(l.verifyHeadline, style: theme.textTheme.headlineLarge),
          const SizedBox(height: Tokens.space2),
          Text(l.verifySentTo, style: theme.textTheme.bodySmall),
          Text(widget.email, style: theme.textTheme.titleSmall),
          const SizedBox(height: Tokens.space5),
          _card(
            context,
            child: TextField(
              key: const Key('verifyCode'),
              controller: _code,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(letterSpacing: 8, color: scheme.primary),
              decoration: InputDecoration(labelText: l.verifyCodeLabel, counterText: '', errorText: _error, border: InputBorder.none, filled: false),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _verify(),
            ),
          ),
          const SizedBox(height: Tokens.space5),
          _primary(context, key: const Key('verifyConfirm'), label: l.verifyConfirm,
              onPressed: _code.text.trim().length >= 6 ? _verify : null, busy: _busy),
          const SizedBox(height: Tokens.space3),
          TextButton(
            key: const Key('verifyResend'),
            onPressed: _wait > 0 ? null : _resend,
            child: Text(_wait > 0 ? l.verifyResendIn(_wait) : l.verifyResend),
          ),
          TextButton(key: const Key('verifyChangeEmail'), onPressed: () => context.pop(), child: Text(l.verifyChangeEmail)),
          const SizedBox(height: Tokens.space3),
          Text(l.verifyTip, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Tài khoản & thiết bị (Figma C37, UX §3.7).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final account = ref.watch(accountProvider);
    final info = ref.watch(accountInfoProvider).value ?? account?.current;
    final plan = ref.watch(cachedQuotaProvider).value?.plan;
    final children = <Widget>[];
    if (info == null || info.isAnonymous) {
      children.addAll([
        _card(
          context,
          key: const Key('accountAnonymous'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.accountAnonymousTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: Tokens.space2),
              Text(l.accountAnonymousBody, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: Tokens.space4),
        FilledButton(key: const Key('accountSignIn'), onPressed: () => context.push('/login'), child: Text(l.accountSignIn)),
      ]);
    } else {
      children.addAll([
        _card(
          context,
          key: const Key('accountCard'),
          child: Row(
            children: [
              Expanded(child: Text(info.email ?? '', style: theme.textTheme.titleMedium)),
              if (plan != null)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: Tokens.space1),
                  decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusLg)),
                  child: Text(plan == 'plus' ? l.planPlus : l.planFree, style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary)),
                ),
            ],
          ),
        ),
        const SizedBox(height: Tokens.space5),
        Text(l.accountHistory, style: theme.textTheme.titleMedium),
        const SizedBox(height: Tokens.space2),
        _Sessions(),
        const SizedBox(height: Tokens.space5),
        OutlinedButton(
          key: const Key('accountSignOut'),
          style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => _signOut(context, ref),
          child: Text(l.accountSignOut),
        ),
      ]);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.meAccountDevices)),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space5),
        children: children,
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.accountSignOutConfirm),
        content: Text(l.accountSignOutBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(key: const Key('signOutConfirm'), onPressed: () => Navigator.pop(context, true), child: Text(l.accountSignOut)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(accountProvider)?.signOut();
    if (context.mounted) context.go('/today');
  }
}

class _Sessions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fmt = Fmt.of(context);
    final sessions = ref.watch(accountSessionsProvider).value ?? const <SessionInfo>[];
    return _card(
      context,
      key: const Key('accountSessions'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in sessions)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: Tokens.space1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [s.deviceModel ?? s.platform ?? '', if (s.current) l.accountThisDevice, s.active ? l.accountSessionActive : l.accountSessionEnded]
                        .where((x) => x.isNotEmpty)
                        .join(' · '),
                    style: theme.textTheme.titleSmall?.copyWith(color: s.current ? RemindColors.of(context).travel : null),
                  ),
                  Text(
                    [
                      if (s.createdAt != null) [fmt.date(s.createdAt!.toLocal()), fmt.time(s.createdAt!)].join(' '),
                      ?s.country,
                      if (s.endReason != null)
                        switch (s.endReason) {
                          'replaced' => l.accountEndReplaced,
                          'plan_limit' => l.accountEndPlan,
                          _ => l.accountEndSignedOut,
                        },
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Bị đăng xuất vì tài khoản đăng nhập ở máy khác (UX §3.7). Thông báo đã hủy (ReminderBinding).
class RevokedScreen extends ConsumerWidget {
  const RevokedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fmt = Fmt.of(context);
    final by = ref.watch(revokedByProvider).value;
    final pending = ref.watch(pendingChangesProvider).value ?? 0;
    final email = ref.watch(accountProvider)?.current?.email;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(Tokens.screenMargin),
            children: [
              const SizedBox(height: Tokens.space8),
              Icon(Icons.devices_other_outlined, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: Tokens.space4),
              Text(l.revokedTitle, key: const Key('revokedTitle'), style: theme.textTheme.headlineLarge),
              const SizedBox(height: Tokens.space3),
              Text(
                by?.device != null && by?.at != null
                    ? l.revokedBody(by!.device!, [fmt.time(by.at!), fmt.date(by.at!.toLocal())].join(' · '))
                    : l.revokedBodyUnknown,
                style: theme.textTheme.bodyMedium,
              ),
              if (pending > 0) ...[const SizedBox(height: Tokens.space3), Text(l.revokedPending(pending), style: theme.textTheme.bodySmall)],
              const SizedBox(height: Tokens.space6),
              FilledButton(
                key: const Key('revokedSignIn'),
                onPressed: () => context.push(Uri(path: '/login', queryParameters: {'email': ?email}).toString()),
                child: Text(l.revokedSignIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
