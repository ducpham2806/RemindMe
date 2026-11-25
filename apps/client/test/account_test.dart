import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_client/data/providers.dart';
import 'package:remindme_client/data/remote/account.dart';
import 'package:remindme_client/data/remote/remote_sync.dart';

import 'helpers.dart';

const phone = Size(390, 844);

class FakeAccount implements AccountApi {
  FakeAccount({this.info = const AccountInfo(userId: 'anon', isAnonymous: true), this.mode = OtpMode.link, this.switchTo});
  AccountInfo? info;
  final OtpMode mode;
  /// Email đã có tài khoản: xác nhận mã thì sang user này.
  final AccountInfo? switchTo;
  final _changes = StreamController<AccountInfo?>.broadcast();
  final calls = <String>[];

  @override
  AccountInfo? get current => info;
  @override
  Stream<AccountInfo?> get changes => _changes.stream;

  void _set(AccountInfo? i) {
    info = i;
    _changes.add(i);
  }

  @override
  Future<OtpMode> sendCode(String email) async {
    calls.add('send $email');
    return mode;
  }

  @override
  Future<void> resend(String email, OtpMode mode) async => calls.add('resend');

  @override
  Future<VerifyResult> verify(String email, String code, OtpMode mode) async {
    calls.add('verify $code ${mode.name}');
    if (code != '123456') throw const AccountException(AccountError.invalidCode);
    if (mode == OtpMode.link) {
      _set(AccountInfo(userId: info!.userId, email: email, isAnonymous: false));
      return (switched: false, willReplace: const <SessionInfo>[]);
    }
    _set(switchTo);
    return (switched: true, willReplace: const [SessionInfo(id: 's1', deviceModel: 'Pixel 9', active: true, current: false)]);
  }

  @override
  Future<void> finishSwitch() async => calls.add('finish');
  @override
  Future<void> cancelSwitch() async => calls.add('cancel');
  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _set(const AccountInfo(userId: 'anon2', isAnonymous: true));
  }

  @override
  Future<void> deleteAccount() async {
    calls.add('delete');
    _set(const AccountInfo(userId: 'anon3', isAnonymous: true));
  }

  @override
  Future<List<SessionInfo>> sessions() async => [
        SessionInfo(id: 's0', platform: 'android', deviceModel: 'Pixel 8', active: true, current: true, createdAt: DateTime.utc(2026, 11, 25, 2), country: 'VN'),
      ];

  @override
  Future<({String? device, DateTime? at})> revokedBy() async => (device: 'iPhone 16', at: DateTime.utc(2026, 11, 25, 2, 41));
}

Future<void> openAccount(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-3')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('me-user')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('me-user')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ẩn danh → gắn email bằng mã: mã sai báo lỗi, mã đúng giữ dữ liệu và hiện email', (tester) async {
    final fake = FakeAccount();
    await pumpApp(tester, size: phone, overrides: [accountProvider.overrideWithValue(fake)]);
    await openAccount(tester);
    expect(find.text("You don't have an account yet"), findsOneWidget);
    await tester.tap(find.byKey(const Key('accountSignIn')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('loginSend'))).onPressed, isNull, reason: 'chưa nhập email hợp lệ');
    await tester.enterText(find.byKey(const Key('loginEmail')), 'lan@example.com');
    await tester.pump();
    await tester.tap(find.byKey(const Key('loginSend')));
    await tester.pumpAndSettle();
    expect(find.text('lan@example.com'), findsOneWidget);
    expect(find.text('Resend in 60s'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('verifyCode')), '000000');
    await tester.pump();
    await tester.tap(find.byKey(const Key('verifyConfirm')));
    await tester.pumpAndSettle();
    expect(find.text('That code is wrong or has expired.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('verifyCode')), '123456');
    await tester.pump();
    await tester.tap(find.byKey(const Key('verifyConfirm')));
    await tester.pumpAndSettle();
    expect(fake.calls, ['send lan@example.com', 'verify 000000 link', 'verify 123456 link']);
    expect(find.text('Email added. Your data stays as it is.'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('accountCard')), matching: find.text('lan@example.com')), findsOneWidget);
    expect(find.textContaining('Pixel 8 · This device · Active'), findsOneWidget);
  });

  testWidgets('email đã có tài khoản: hỏi trước khi thay dữ liệu, nêu máy sẽ bị đăng xuất; Tiếp tục thì đổi', (tester) async {
    final fake = FakeAccount(mode: OtpMode.signIn, switchTo: const AccountInfo(userId: 'u2', email: 'lan@example.com', isAnonymous: false));
    await pumpApp(tester, size: phone, overrides: [accountProvider.overrideWithValue(fake)]);
    await openAccount(tester);
    await tester.tap(find.byKey(const Key('accountSignIn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('loginEmail')), 'lan@example.com');
    await tester.pump();
    await tester.tap(find.byKey(const Key('loginSend')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('verifyCode')), '123456');
    await tester.pump();
    await tester.tap(find.byKey(const Key('verifyConfirm')));
    await tester.pumpAndSettle();
    expect(find.text('Switch to lan@example.com?'), findsOneWidget);
    expect(find.text('These devices will be signed out: Pixel 9'), findsOneWidget);
    await tester.tap(find.byKey(const Key('switchConfirm')));
    await tester.pumpAndSettle();
    expect(fake.calls.last, 'finish');
    expect(find.text('Signed in. Loading your data…'), findsOneWidget);
  });

  testWidgets('đăng xuất có xác nhận', (tester) async {
    final fake = FakeAccount(info: const AccountInfo(userId: 'u1', email: 'lan@example.com', isAnonymous: false));
    await pumpApp(tester, size: phone, overrides: [accountProvider.overrideWithValue(fake)]);
    await openAccount(tester);
    await tester.ensureVisible(find.byKey(const Key('accountSignOut')));
    await tester.tap(find.byKey(const Key('accountSignOut')));
    await tester.pumpAndSettle();
    expect(find.text('Sign out on this device?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('signOutConfirm')));
    await tester.pumpAndSettle();
    expect(fake.calls, ['signOut']);
  });

  testWidgets('phiên bị kết thúc ở máy khác → màn toàn trang, nêu máy + giờ, Đăng nhập lại điền sẵn email', (tester) async {
    final fake = FakeAccount(info: const AccountInfo(userId: 'u1', email: 'lan@example.com', isAnonymous: false));
    final status = StreamController<RemoteSyncStatus?>();
    await pumpApp(tester, size: phone, overrides: [
      accountProvider.overrideWithValue(fake),
      remoteSyncStatusProvider.overrideWith((ref) => status.stream),
    ]);
    status.add((state: RemoteSyncState.ok, lastOk: null));
    await tester.pumpAndSettle();
    status.add((state: RemoteSyncState.revoked, lastOk: null));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('revokedTitle')), findsOneWidget);
    expect(find.textContaining('Your account was just signed in on iPhone 16 at'), findsOneWidget);
    await tester.tap(find.byKey(const Key('revokedSignIn')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('loginEmail'))).controller!.text, 'lan@example.com');
    await status.close();
  });
}
