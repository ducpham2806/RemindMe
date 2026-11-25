import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

import '../../core/l10n/formatters.dart';
import '../../core/l10n/recurrence_text.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../data/reminder_binding.dart';
import '../../l10n/app_localizations.dart';
import '../quick_add/quick_add_sheet.dart';

/// Onboarding (UX §3.1, Figma C30-C33): Chào mừng → Mục tiêu (tạo list khởi đầu) → Thử nhắc đầu tiên → Bật thông báo (priming trước hộp
/// thoại của hệ điều hành). Bước nào cũng bỏ qua được. Xong thì ghi [onboardingDonePref] và về Hôm nay.
/// C34 (cài đặt pin theo hãng Android) chưa làm: cần đọc trạng thái tối ưu pin bằng code native.
const _steps = 3;

/// Việc tạo ở bước 3, để bước 4 hiện lại.
class OnboardingFirstItem extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

final onboardingFirstItemProvider = NotifierProvider<OnboardingFirstItem, String?>(OnboardingFirstItem.new);

/// Kết thúc onboarding (kể cả "Dùng thử ngay").
Future<void> finishOnboarding(WidgetRef ref) async {
  await ref.read(localPrefsProvider).set(onboardingDonePref, '1');
  ref.read(onboardingDoneProvider.notifier).set(true);
}

TextStyle? _small(BuildContext context) =>
    Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: Theme.of(context).colorScheme.onSurfaceVariant);

/// Khung bước 2-4: AppBar có nút lùi, "BƯỚC n / 4" + thanh tiến độ, tiêu đề lớn, nút chính + "Bỏ qua" ở đáy.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.title,
    required this.step,
    required this.headline,
    required this.children,
    required this.primary,
    required this.secondary,
  });
  final String title, headline;
  final int step;
  final List<Widget> children;
  final Widget primary, secondary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space3, Tokens.screenMargin, Tokens.space3),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [primary, secondary]),
        ),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space5),
        children: [
          Text(l.onboardingStep(step, _steps + 1), style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
          const SizedBox(height: Tokens.space2),
          Row(
            children: [
              for (var i = 1; i <= _steps + 1; i++) ...[
                if (i > 1) const SizedBox(width: Tokens.space2),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step ? scheme.primary : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Tokens.space5),
          Semantics(header: true, child: Text(headline, style: theme.textTheme.headlineLarge?.copyWith(fontSize: 28, height: 38 / 28))),
          const SizedBox(height: Tokens.space4),
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: Tokens.space3), children[i]],
        ],
      ),
    );
  }
}

Widget _note(BuildContext context, String text) {
  final colors = RemindColors.of(context);
  return Container(
    padding: const EdgeInsetsDirectional.all(14),
    decoration: BoxDecoration(color: colors.travelContainer, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.travel)),
  );
}

/// C30 Chào mừng.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final langName = switch (lang) { 'vi' => l.langNameVi, _ => l.langNameEn };
    Widget benefit(AppIcons icon, String title, String body) => Padding(
          padding: const EdgeInsetsDirectional.only(bottom: Tokens.space3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text(body, style: _small(context)),
                  ],
                ),
              ),
            ],
          ),
        );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space5, Tokens.screenMargin, Tokens.space5),
          children: [
            Semantics(header: true, child: Text(l.welcomeTitle, style: theme.textTheme.headlineLarge)),
            const SizedBox(height: Tokens.space3),
            Text(l.welcomeHeadline, style: theme.textTheme.titleLarge?.copyWith(height: 1.4)),
            const SizedBox(height: Tokens.space5),
            ExcludeSemantics(
              child: Container(
                padding: const EdgeInsetsDirectional.all(14),
                decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusXl)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.all(14),
                      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.welcomeSampleTag.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary)),
                          const SizedBox(height: Tokens.space1),
                          Text(l.welcomeSampleRoute, style: theme.textTheme.titleLarge),
                          Text(l.welcomeSampleWhen, style: _small(context)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsetsDirectional.all(14),
                      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
                      child: Row(
                        children: [
                          AppIcon(AppIcons.bell, size: 22, color: scheme.primary),
                          const SizedBox(width: Tokens.space3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.welcomeSampleReminder, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                Text(l.welcomeSampleReminderHint, style: _small(context)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Tokens.space5),
            benefit(AppIcons.camera, l.welcomeCapture, l.welcomeCaptureBody),
            benefit(AppIcons.clock, l.welcomeOffline, l.welcomeOfflineBody),
            benefit(AppIcons.shield, l.welcomeControl, l.welcomeControlBody),
            const SizedBox(height: Tokens.space3),
            FilledButton(key: const Key('welcomeContinue'), onPressed: () => context.push('/onboarding/goals'), child: Text(l.welcomeContinue)),
            const SizedBox(height: Tokens.space2),
            TextButton(
              key: const Key('welcomeTryNow'),
              onPressed: () async {
                await finishOnboarding(ref);
                if (context.mounted) context.go('/today');
              },
              child: Text(l.welcomeTryNow),
            ),
            if (ref.watch(accountProvider) != null)
              TextButton(
                key: const Key('welcomeSignIn'),
                onPressed: () async {
                  await finishOnboarding(ref);
                  if (!context.mounted) return;
                  context.go('/today');
                  unawaited(context.push('/login'));
                },
                child: Text(l.welcomeSignIn),
              ),
            const SizedBox(height: Tokens.space3),
            Text(l.welcomeLanguage(langName), style: _small(context)),
          ],
        ),
      ),
    );
  }
}

/// C31 Mục tiêu: chọn nhiều; Tiếp tục tạo 1 list khởi đầu cho mỗi mục (trừ list trùng tên đã có).
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _picked = <String>{};
  bool _busy = false;

  List<(String, IconData, String, String)> _goals(AppLocalizations l) => [
        ('work', Icons.work_outline, l.goalWork, l.goalWorkHint),
        ('travel', Icons.luggage_outlined, l.goalTravel, l.goalTravelHint),
        ('health', Icons.favorite_border, l.goalHealth, l.goalHealthHint),
        ('family', Icons.people_outline, l.goalFamily, l.goalFamilyHint),
        ('study', Icons.menu_book_outlined, l.goalStudy, l.goalStudyHint),
      ];

  Future<void> _continue() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    final lists = ref.read(listsRepositoryProvider);
    final existing = {for (final s in ref.read(listsProvider).value ?? const <ListSummary>[]) s.name?.toLowerCase()};
    for (final (id, _, name, _) in _goals(l)) {
      if (_picked.contains(id) && !existing.contains(name.toLowerCase())) await lists.create(name);
    }
    if (mounted) await context.push('/onboarding/first');
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _StepPage(
      title: l.goalsTitle,
      step: 2,
      headline: l.goalsHeadline,
      primary: FilledButton(key: const Key('goalsContinue'), onPressed: _busy ? null : _continue, child: Text(l.welcomeContinue)),
      secondary: TextButton(key: const Key('goalsSkip'), onPressed: () => context.push('/onboarding/first'), child: Text(l.onboardingSkip)),
      children: [
        Text(l.goalsHint, style: theme.textTheme.bodySmall),
        for (final (id, icon, name, hint) in _goals(l))
          Semantics(
            selected: _picked.contains(id),
            button: true,
            child: Material(
              color: _picked.contains(id) ? scheme.primaryContainer : scheme.surface,
              borderRadius: BorderRadius.circular(Tokens.radiusMd),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: Key('goal-$id'),
                onTap: () => setState(() => _picked.contains(id) ? _picked.remove(id) : _picked.add(id)),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(14),
                  child: Row(
                    children: [
                      Icon(icon, size: 21, color: _picked.contains(id) ? scheme.primary : scheme.onSurfaceVariant),
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
                      _picked.contains(id)
                          ? AppIcon(AppIcons.tick, size: 18, color: scheme.primary)
                          : Icon(Icons.radio_button_unchecked, size: 20, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ),
        _note(context, l.goalsNote),
      ],
    );
  }
}

/// C32 Thử nhắc đầu tiên: câu mẫu theo ngôn ngữ, phân tích trực tiếp bằng gói NLU, tạo việc với mốc nhắc mặc định.
class FirstReminderScreen extends ConsumerStatefulWidget {
  const FirstReminderScreen({super.key});

  @override
  ConsumerState<FirstReminderScreen> createState() => _FirstReminderScreenState();
}

class _FirstReminderScreenState extends ConsumerState<FirstReminderScreen> {
  TextEditingController? _text;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _text ??= TextEditingController(text: AppLocalizations.of(context).firstExample);
  }

  @override
  void dispose() {
    _text?.dispose();
    super.dispose();
  }

  NluResult? _parse(NluEngine? engine) {
    final raw = _text!.text.trim();
    if (raw.isEmpty) return null;
    if (engine == null) return NluResult(title: raw);
    final r = engine.parseAll(raw, NluContext(now: ref.read(nowProvider)(), region: ref.read(deviceRegionProvider)));
    return r.isEmpty ? NluResult(title: raw) : r.first;
  }

  Future<void> _create(NluResult r) async {
    setState(() => _busy = true);
    final id = await saveParsedItem(ref,
        title: r.title.isEmpty ? _text!.text.trim() : r.title,
        when: r.when,
        recurrence: r.recurrence,
        tags: r.tags,
        priority: r.priority,
        reminder: ref.read(defaultReminderProvider).value ?? 0);
    ref.read(onboardingFirstItemProvider.notifier).set(id);
    if (mounted) await context.push('/onboarding/notify');
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fmt = Fmt.of(context);
    final engine = ref.watch(nluEngineProvider(nluPackKey(Localizations.localeOf(context).languageCode))).value;
    final r = _parse(engine);
    final today = CivilDate.of(ref.watch(nowProvider)());
    final when = r?.when;
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsetsDirectional.only(top: Tokens.space2),
          child: Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
              Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );
    return _StepPage(
      title: l.firstTitle,
      step: 3,
      headline: l.firstHeadline,
      primary: FilledButton(
        key: const Key('firstCreate'),
        onPressed: _busy || r == null ? null : () => _create(r),
        child: Text(l.firstCreate),
      ),
      secondary: TextButton(key: const Key('firstSkip'), onPressed: () => context.push('/onboarding/notify'), child: Text(l.onboardingSkip)),
      children: [
        Text(l.firstHint, style: theme.textTheme.bodySmall),
        Container(
          padding: const EdgeInsetsDirectional.all(Tokens.space4),
          decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusXl)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.firstFieldLabel, style: theme.textTheme.bodySmall),
              TextField(
                key: const Key('firstText'),
                controller: _text,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
                decoration: const InputDecoration(border: InputBorder.none, filled: false, isCollapsed: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                onChanged: (_) => setState(() {}),
              ),
              Text(l.firstFieldHint, style: _small(context)),
            ],
          ),
        ),
        if (r != null)
          Container(
            key: const Key('firstPreview'),
            padding: const EdgeInsetsDirectional.all(Tokens.space4),
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusXl)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.firstUnderstood, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.primary)),
                row(l.firstWhen, when == null ? l.firstNoTime : fmt.civil(when, today: today)),
                row(l.firstRepeat, r.recurrence == null ? l.recurNone : describeRecurrence(context, r.recurrence!.toPayload())),
                row(l.firstList, l.listsInbox),
              ],
            ),
          ),
        _note(context, l.firstNotifNote),
      ],
    );
  }
}

/// C33 Bật thông báo: giải thích trước khi hệ điều hành hỏi quyền (reminder-engine.md §2). "Để sau" thì không hỏi nữa (đã ghi là đã hỏi).
class NotifyPermissionScreen extends ConsumerWidget {
  const NotifyPermissionScreen({super.key});

  Future<void> _finish(BuildContext context, WidgetRef ref, {required bool ask}) async {
    final os = ref.read(notificationSchedulerProvider);
    await markNotificationPermissionAsked(ref.read(appDatabaseProvider));
    if (ask) await os.requestPermission();
    ref.invalidate(notificationHealthProvider);
    await finishOnboarding(ref);
    if (context.mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final fmt = Fmt.of(context);
    final id = ref.watch(onboardingFirstItemProvider);
    final item = id == null ? null : ref.watch(itemProvider(id)).value;
    Widget bullet(AppIcons icon, String text) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: Tokens.space3),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, color: scheme.onSurfaceVariant))),
          ],
        );
    return _StepPage(
      title: l.notifyTitle,
      step: 4,
      headline: l.notifyHeadline,
      primary: FilledButton(key: const Key('notifyAllow'), onPressed: () => _finish(context, ref, ask: true), child: Text(l.notifyAllow)),
      secondary: TextButton(key: const Key('notifyLater'), onPressed: () => _finish(context, ref, ask: false), child: Text(l.notifyLater)),
      children: [
        if (item != null)
          Container(
            key: const Key('notifyCard'),
            padding: const EdgeInsetsDirectional.all(Tokens.space4),
            decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusXl)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIcon(AppIcons.tick, size: 18, color: colors.travel),
                    const SizedBox(width: Tokens.space2),
                    Text(l.notifyCreated, style: theme.textTheme.labelLarge?.copyWith(color: colors.travel)),
                  ],
                ),
                const SizedBox(height: Tokens.space3),
                Text(item.title, style: theme.textTheme.titleLarge),
                if (fmt.when(item, today: ref.watch(todayWindowProvider)) case final w?) ...[
                  const SizedBox(height: Tokens.space1),
                  Text(w, style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary)),
                ],
              ],
            ),
          ),
        bullet(AppIcons.bell, l.notifyWhy1),
        bullet(AppIcons.clock, l.notifyWhy2),
        bullet(AppIcons.shield, l.notifyWhy3),
        const SizedBox(height: Tokens.space2),
        Text(l.notifyNote, style: _small(context)),
      ],
    );
  }
}
