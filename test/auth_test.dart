import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingogo/app.dart';
import 'package:lingogo/auth_service.dart';
import 'package:lingogo/data.dart';
import 'fake_auth.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> tap(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> credentials(
    WidgetTester tester, {
    String password = 'secret123',
  }) async {
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'minh@example.com',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), password);
  }

  testWidgets(
    'Sign in validates fields, prevents duplicate requests and opens onboarding',
    (tester) async {
      final auth = FakeAuth(account: null);
      await tester.pumpWidget(LingoGoApp(auth: auth));
      await tap(tester, 'Đăng nhập');
      expect(auth.signInCalls, 0);
      expect(find.text('Vui lòng nhập email hợp lệ.'), findsOneWidget);
      await credentials(tester);
      auth.pending = Completer<void>();
      await tester.ensureVisible(find.text('Đăng nhập'));
      await tester.tap(find.text('Đăng nhập'));
      await tester.pump();
      expect(auth.signInCalls, 1);
      expect(find.text('Đang xử lý…'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      auth.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Một ngôn ngữ mới.\nMột thế giới mới.'), findsOneWidget);
    },
  );

  testWidgets(
    'Registration requires matching passwords and creates an account',
    (tester) async {
      final auth = FakeAuth(account: null);
      await tester.pumpWidget(LingoGoApp(auth: auth));
      await tap(tester, 'Chưa có tài khoản? Đăng ký');
      await credentials(tester);
      await tester.enterText(
        find.byKey(const Key('auth-confirm')),
        'different',
      );
      await tap(tester, 'Tạo tài khoản');
      expect(auth.registerCalls, 0);
      expect(find.text('Mật khẩu nhập lại chưa khớp.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('auth-confirm')),
        'secret123',
      );
      await tap(tester, 'Tạo tài khoản');
      expect(auth.registerCalls, 1);
      expect(find.text('Một ngôn ngữ mới.\nMột thế giới mới.'), findsOneWidget);
    },
  );

  testWidgets('Forgot password sends an email and allows return to sign in', (
    tester,
  ) async {
    final auth = FakeAuth(account: null);
    await tester.pumpWidget(LingoGoApp(auth: auth));
    await tap(tester, 'Quên mật khẩu?');
    expect(find.byKey(const Key('auth-password')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'minh@example.com',
    );
    await tap(tester, 'Gửi liên kết đặt lại');
    expect(auth.resetEmail, 'minh@example.com');
    expect(auth.account, isNull);
    expect(find.textContaining('Nếu email có tài khoản'), findsOneWidget);
    await tap(tester, 'Quay lại đăng nhập');
    expect(find.text('Chào mừng trở lại!'), findsOneWidget);
  });

  testWidgets(
    'Failed authentication keeps courses inaccessible and shows a useful error',
    (tester) async {
      final auth = FakeAuth(account: null)
        ..failure = FirebaseAuthException(code: 'invalid-credential');
      await tester.pumpWidget(LingoGoApp(auth: auth));
      await credentials(tester);
      await tap(tester, 'Đăng nhập');
      expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
      expect(find.text('Trang chủ'), findsNothing);
    },
  );

  test(
    'Local progress is separated by UID and legacy offline data is not assigned to another user',
    () async {
      final legacy = LearningStore();
      await legacy.finish(legacy.lessons.first, 100);
      final a = LearningStore(userId: 'a');
      await a.load();
      expect(a.xp, 0);
      a.displayName = 'An';
      await a.finish(a.lessons.first, 100);
      final b = LearningStore(userId: 'b');
      await b.load();
      expect(b.xp, 0);
      expect(b.displayName, 'Bạn mới');
      final restored = LearningStore(userId: 'a');
      await restored.load();
      expect(restored.xp, 30);
      expect(restored.displayName, 'An');
    },
  );

  testWidgets(
    'Sign out clears the navigation stack; switching accounts loads only that user',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'lingogo.v2.user.a': jsonEncode({'name': 'An', 'onboarded': true}),
        'lingogo.v2.user.b': jsonEncode({'name': 'Bình', 'onboarded': true}),
      });
      final auth = FakeAuth(account: const Account('a', 'a@example.com'));
      await tester.pumpWidget(LingoGoApp(auth: auth));
      await tester.pumpAndSettle();
      expect(find.text('Xin chào, An!'), findsOneWidget);
      await tap(tester, 'Tiếp tục học');
      expect(find.text('Khám phá bài học'), findsOneWidget);
      auth.setAccount(null);
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng trở lại!'), findsOneWidget);
      expect(find.text('Khám phá bài học'), findsNothing);
      auth.setAccount(const Account('b', 'b@example.com'));
      await tester.pumpAndSettle();
      expect(find.text('Xin chào, Bình!'), findsOneWidget);
      expect(find.text('Xin chào, An!'), findsNothing);
      await tap(tester, 'Cá nhân');
      await tester.scrollUntilVisible(find.text('Đăng xuất'), 220);
      await tap(tester, 'Đăng xuất');
      await tap(tester, 'Ở lại');
      expect(auth.account?.uid, 'b');
      await tap(tester, 'Đăng xuất');
      await tester.tap(find.widgetWithText(TextButton, 'Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng trở lại!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
