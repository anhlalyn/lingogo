import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingogo/app.dart';
import 'package:lingogo/data.dart';
import 'package:lingogo/lesson_page.dart';
import 'fake_auth.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Signed-out learners must authenticate before accessing courses',
    (tester) async {
      await tester.pumpWidget(LingoGoApp(auth: FakeAuth(account: null)));
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng trở lại!'), findsOneWidget);
      expect(find.text('Trang chủ'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Desktop navigation and translated practice render without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = LearningStore()..onboarded = true;
      store.selectLanguage('ko');
      await tester.pumpWidget(LingoGoApp(store: store, auth: FakeAuth()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AI gia sư'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('안녕하세요! 저는 안입니다.'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('안녕하세요! 저는 안입니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('Four languages have content and retain independent progress', () async {
    final store = LearningStore();
    await store.load();
    await store.finish(store.published.first, 100);
    for (final language in learningLanguages.skip(1)) {
      store.selectLanguage(language.code);
      expect(store.published, isNotEmpty);
      expect(store.words, isNotEmpty);
      expect(store.completedCount, 0);
      expect(
        store.published.every((l) => l.languageCode == language.code),
        isTrue,
      );
      await store.finish(store.published.first, 100);
    }
    store.selectLanguage('en');
    expect(store.completedCount, 1);
    expect(store.scores['greetings'], 100);
    store.selectLanguage('ja');
    await store.save();
    final restored = LearningStore();
    await restored.load();
    expect(restored.languageCode, 'ja');
    expect(restored.completedCount, 1);
    expect(restored.xp, 120);
  });

  testWidgets(
    'Language picker updates the course and vocabulary on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = LearningStore()..onboarded = true;
      await tester.pumpWidget(LingoGoApp(store: store, auth: FakeAuth()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếng Anh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếng Nhật'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();
      expect(store.languageCode, 'ja');
      await tester.tap(find.text('Từ vựng'));
      await tester.pumpAndSettle();
      expect(find.text('こんにちは'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Passing unlocks the next lesson; repeats do not duplicate XP; progress survives reload',
    () async {
      final store = LearningStore();
      await store.load();
      expect(store.unlocked(store.lessons[1]), isFalse);
      await store.finish(store.lessons.first, 50);
      expect(store.xp, 0);
      expect(store.unlocked(store.lessons[1]), isFalse);
      await store.finish(store.lessons.first, 75);
      await store.finish(store.lessons.first, 100);
      await store.finish(store.lessons.first, 25);
      expect(store.xp, 30);
      expect(store.scores['greetings'], 100);
      expect(store.unlocked(store.lessons[1]), isTrue);
      expect(store.studyDays, hasLength(1));
      expect(store.streak, 1);
      await store.review(hello, true);
      expect(store.due(hello), isFalse);
      final restored = LearningStore();
      await restored.load();
      expect(restored.xp, 30);
      expect(restored.due(hello), isFalse);
      expect(restored.streak, 1);
    },
  );

  testWidgets('New learner can set up and navigate on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = LearningStore();
    await tester.pumpWidget(LingoGoApp(store: store, auth: FakeAuth()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Bắt đầu hành trình'));
    await tester.tap(find.text('Bắt đầu hành trình'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Minh');
    await tester.scrollUntilVisible(
      find.text('Vào học thôi!'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Vào học thôi!'));
    await tester.tap(find.text('Vào học thôi!'));
    await tester.pumpAndSettle();
    expect(find.text('Xin chào, Minh!'), findsOneWidget);
    await tester.tap(find.text('Bài học'));
    await tester.pumpAndSettle();
    expect(find.text('Mỗi bước, một khám phá'), findsOneWidget);
    await tester.tap(find.text('Từ vựng'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsNWidgets(2));
    expect(find.text('Goodbye'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All four exercise types can be answered and scored', (
    tester,
  ) async {
    final store = LearningStore();
    await store.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: ExercisePage(store: store, lesson: store.lessons.first),
      ),
    );
    Future<void> tap(String text) async {
      if (find.text(text).evaluate().isEmpty) {
        await tester.scrollUntilVisible(find.text(text), 200);
      }
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    await tap('Xin chào');
    await tap('Kiểm tra');
    await tap('Câu tiếp theo');
    await tester.enterText(find.byType(TextField), 'name');
    await tester.pump();
    await tap('Kiểm tra');
    await tap('Câu tiếp theo');
    for (final word in ['What', 'is', 'your', 'name']) {
      await tap(word);
    }
    await tap('Kiểm tra');
    await tap('Câu tiếp theo');
    for (final pair in [
      ('Hello', 'Xin chào'),
      ('Thank you', 'Cảm ơn'),
      ('Goodbye', 'Tạm biệt'),
    ]) {
      await tap(pair.$1);
      await tap(pair.$2);
    }
    await tap('Kiểm tra');
    await tap('Xem kết quả');
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('+30'), findsOneWidget);
    expect(store.completed('greetings'), isTrue);
    expect(tester.takeException(), isNull);
  });
}
