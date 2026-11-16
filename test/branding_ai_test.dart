import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:lingogo/app.dart';
import 'package:lingogo/bootstrap.dart';
import 'package:lingogo/branding.dart';
import 'package:lingogo/data.dart';
import 'fake_auth.dart';
import 'fake_content.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('Splash appears while loading then enters the actual app', (
    tester,
  ) async {
    final completion = Completer<Widget>();
    await tester.pumpWidget(AppBootstrap(loadApp: () => completion.future));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Mở lời chào. Mở thế giới.'), findsOneWidget);
    completion.complete(const MaterialApp(home: Text('Ready')));
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
  testWidgets('Startup failure offers retry without bypassing login', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      AppBootstrap(
        loadApp: () async {
          attempts++;
          if (attempts == 1) throw Exception('offline');
          return const MaterialApp(home: Text('Login required'));
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa kết nối được dịch vụ'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Login required'), findsOneWidget);
    expect(attempts, 2);
  });
  testWidgets(
    'Learner chooses Gemini, receives a reply and retains chat across tabs',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeContent();
      final store = LearningStore()..onboarded = true;
      await tester.pumpWidget(
        LingoGoApp(auth: FakeAuth(), store: store, content: repository),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('AI gia sư'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tutor-input')),
        'My name Anna',
      );
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(repository.chatProvider, 'gemini');
      expect(repository.chatMessage, 'My name Anna');
      expect(find.textContaining('Bạn có thể nói:'), findsOneWidget);
      await tester.tap(find.text('Trang chủ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AI gia sư'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bạn có thể nói:'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Cuộc trò chuyện mới'));
      await tester.tap(find.byTooltip('Cuộc trò chuyện mới'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu mới'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bạn có thể nói:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Unavailable backend reports failure without inventing an AI answer',
    (tester) async {
      final repository = FakeContent()
        ..failure = ServiceApiNotEnabled('demo-lingogo');
      await tester.pumpWidget(
        LingoGoApp(
          auth: FakeAuth(),
          store: LearningStore()..onboarded = true,
          content: repository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('AI gia sư'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('tutor-input')), 'Hello');
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(
        find.text('Dịch vụ AI chưa sẵn sàng. Vui lòng liên hệ quản trị viên.'),
        findsOneWidget,
      );
      expect(find.textContaining('Bạn có thể nói:'), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('tutor-input')))
            .controller!
            .text,
        'Hello',
      );
    },
  );
}
