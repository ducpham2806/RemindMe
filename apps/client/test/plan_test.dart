import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_data/remindme_data.dart';

import 'helpers.dart';

Future<void> _openPlan(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-3')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('me-plus')));
  await tester.tap(find.byKey(const Key('me-plus')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Gói & mức sử dụng: số lấy từ cache quota_status (giới hạn của server, không hard-code)', (tester) async {
    final c = await pumpApp(tester, size: const Size(390, 1400), locale: const Locale('vi'), region: 'VN');
    final db = c.read(appDatabaseProvider);
    await tester.runAsync(() => db.into(db.syncState).insert(SyncStateCompanion.insert(
          key: 'quota_status',
          value: jsonEncode({
            'fetched_at': '2026-12-01T03:00:00Z',
            'status': {
              'plan': 'free',
              // Số khác hẳn seed thật để chắc chắn UI đọc từ server.
              'limits': {'max_reminders_per_day': 12, 'max_recurring_series': 7, 'max_active_appointments': 9, 'max_active_trips': 2,
                'smart_imports_per_month': 4, 'max_lists': 6, 'max_active_devices': 1},
              'usage': {'max_reminders_per_day': 3, 'max_recurring_series': 6, 'max_active_trips': 0, 'smart_imports_per_month': 4, 'max_lists': 1},
              'features': {'feature_enhanced_voice': 1, 'feature_alt_calendars': 1},
            },
          }),
        )));
    await _openPlan(tester);
    expect(find.text('RemindMe Free'), findsOneWidget);
    Finder row(String k, String text) => find.descendant(of: find.byKey(Key('planUsage-$k')), matching: find.text(text));
    expect(row('max_reminders_per_day', '3 / 12 đã dùng'), findsOneWidget);
    expect(row('max_recurring_series', '6 / 7 đã dùng'), findsOneWidget);
    expect(row('max_active_appointments', '0 / 9 đã dùng'), findsOneWidget);
    expect(row('smart_imports_per_month', '4 / 4 đã dùng'), findsOneWidget);
    expect(find.text('Thiết bị: 1 / 1 đang hoạt động'), findsOneWidget);
    expect(find.text('Giọng nói và âm lịch có sẵn trong gói này.'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('planUpgrade')));
    expect(tester.widget<FilledButton>(find.byKey(const Key('planUpgrade'))).onPressed, isNull, reason: 'chưa có mua trong app');
  });

  testWidgets('chưa đồng bộ lần nào: trạng thái trống', (tester) async {
    await pumpApp(tester, size: const Size(390, 844), locale: const Locale('en'));
    await _openPlan(tester);
    expect(find.text('No usage yet'), findsOneWidget);
  });
}
