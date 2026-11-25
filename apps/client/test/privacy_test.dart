import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_client/data/remote/account.dart';
import 'package:remindme_client/features/me/privacy_screens.dart';

import 'account_test.dart' show FakeAccount;
import 'helpers.dart';

const _tall = Size(390, 1200);

Future<void> _openPrivacy(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-3')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('me-shield')));
  await tester.tap(find.byKey(const Key('me-shield')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('xuất dữ liệu: ZIP có remindme-export.json (có việc vừa tạo) và calendar.ics, lưu qua hộp thoại hệ điều hành', (tester) async {
    final saved = <(String, Uint8List)>[];
    await pumpApp(tester, size: _tall, locale: const Locale('vi'), seed: (r) => r.create(title: 'Khám răng', startDate: '2026-12-03'), overrides: [
      exportSaverProvider.overrideWithValue((name, bytes) async {
        saved.add((name, bytes));
        return true;
      }),
    ]);
    await _openPrivacy(tester);
    await tester.tap(find.byKey(const Key('privacyExport')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('Bản xuất đã sẵn sàng.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exportSave')));
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu tệp'), findsOneWidget);
    final (name, bytes) = saved.single;
    expect(name, 'remindme-export.zip');
    final zip = ZipDecoder().decodeBytes(bytes);
    final json = jsonDecode(utf8.decode(zip.findFile('remindme-export.json')!.content as List<int>)) as Map<String, Object?>;
    expect((json['items']! as List).map((i) => (i as Map)['title']), ['Khám răng']);
    expect(utf8.decode(zip.findFile('calendar.ics')!.content as List<int>), contains('SUMMARY:Khám răng'));
  });

  testWidgets('xóa tài khoản: phải gõ đúng từ xác nhận; gửi xong về màn "Đã nhận yêu cầu xóa"', (tester) async {
    final fake = FakeAccount(info: const AccountInfo(userId: 'u1', email: 'lan@example.com', isAnonymous: false));
    await pumpApp(tester, size: _tall, locale: const Locale('vi'), overrides: [accountProvider.overrideWithValue(fake)]);
    await _openPrivacy(tester);
    await tester.tap(find.byKey(const Key('privacyDelete')));
    await tester.pumpAndSettle();
    expect(find.text('lan@example.com'), findsOneWidget);
    FilledButton send() => tester.widget<FilledButton>(find.byKey(const Key('deleteSend')));
    expect(send().onPressed, isNull);
    await tester.enterText(find.byKey(const Key('deleteConfirm')), 'xoa');
    await tester.pump();
    expect(send().onPressed, isNull, reason: 'phải đúng chữ, kể cả dấu');
    await tester.enterText(find.byKey(const Key('deleteConfirm')), 'xóa');
    await tester.pump();
    expect(send().onPressed, isNotNull, reason: 'không phân biệt hoa thường');
    await tester.tap(find.byKey(const Key('deleteSend')));
    await tester.pumpAndSettle();
    expect(fake.calls, contains('delete'));
    expect(find.byKey(const Key('deletedHeadline')), findsOneWidget);
    await tester.tap(find.byKey(const Key('deletedHome')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nav-0')), findsOneWidget);
  });

  testWidgets('bản không có server: Xóa tài khoản mờ', (tester) async {
    await pumpApp(tester, size: _tall, locale: const Locale('en'));
    await _openPrivacy(tester);
    expect(find.text('Available after you sync with an account.'), findsOneWidget);
  });
}
