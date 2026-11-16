import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingogo/admin_page.dart';
import 'package:lingogo/app.dart';
import 'package:lingogo/auth_service.dart';
import 'package:lingogo/content_repository.dart';
import 'package:lingogo/data.dart';
import 'fake_auth.dart';
import 'fake_content.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> tap(WidgetTester tester, String text) async {
    final finder = find.text(text);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 300, maxScrolls: 60);
    }
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Widget adminApp(FakeContent repository, {bool admin = true}) => AuthScope(
    auth: FakeAuth(account: Account('a', 'a@example.com', isAdmin: admin)),
    child: MaterialApp(home: AdminPage(repository: repository)),
  );

  test('Admin catalog includes all built-in courses and remote drafts', () {
    final remote = ContentEntry('l_remote_12345', {
      ...lessonContent(seedLessons().first),
      'status': 'draft',
      'source': 'manual',
    });
    final catalog = adminLessonCatalog([remote]);
    expect(catalog.length, builtInLessons().length + 1);
    expect(catalog.where((e) => e.data['source'] == 'builtin').length, 75);
    expect(
      catalog
          .where(
            (e) => e.data['languageCode'] == 'zh' && e.data['level'] == 'HSK 6',
          )
          .length,
      3,
    );
    expect(catalog.first, same(remote));
  });

  testWidgets(
    'Admin can select HSK 6 and copy a built-in lesson into a draft',
    (tester) async {
      final repository = FakeContent();
      await tester.pumpWidget(adminApp(repository));
      await tester.pumpAndSettle();
      final course = find.byKey(const ValueKey('admin-course:zh:HSK 6'));
      await Scrollable.ensureVisible(tester.element(course), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(course);
      await tester.pumpAndSettle();
      expect(find.text('3 bài phù hợp'), findsOneWidget);
      expect(find.text('Lập luận trừu tượng'), findsOneWidget);
      expect(find.text('Giới thiệu bản thân'), findsNothing);
      expect(find.text('Lưu trữ'), findsNothing);
      final copy = find.text('Xem & tạo bản sao').first;
      await Scrollable.ensureVisible(tester.element(copy), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(find.text('Tạo bản sao mới'), findsOneWidget);
      expect(repository.entries, isEmpty);
      final save = find.text('Lưu bản nháp');
      await tester.scrollUntilVisible(
        save,
        300,
        maxScrolls: 60,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(save), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repository.entries.values.single['level'], 'HSK 6');
      expect(repository.entries.values.single['status'], 'draft');
      expect(builtInLessons().length, 75);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Review schedules stay separate across languages even for identical spelling',
    () async {
      final store = LearningStore(userId: 'review-user');
      await store.review(hello, true);
      store.selectLanguage('ja');
      expect(store.due(hello), isTrue);
      await store.review(hello, false);
      store.selectLanguage('en');
      expect(store.due(hello), isFalse);
      await store.save();
      final restored = LearningStore(userId: 'review-user');
      await restored.load();
      expect(restored.due(hello), isFalse);
    },
  );

  test(
    'Completed lessons remain available to review when predecessors change',
    () async {
      final store = LearningStore();
      await store.finish(store.lessons[1], 100);
      expect(store.completed(store.lessons.first.id), isFalse);
      expect(store.unlocked(store.lessons[1]), isTrue);
    },
  );

  testWidgets(
    'Refreshing claims revokes an open editor when admin is removed',
    (tester) async {
      final repository = FakeContent();
      final auth = FakeAuth(
        account: const Account('a', 'a@example.com', isAdmin: true),
      );
      await tester.pumpWidget(
        LingoGoApp(
          auth: auth,
          content: repository,
          store: LearningStore()..onboarded = true,
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Cá nhân');
      await tap(tester, 'Quản lý bài học');
      await tap(tester, 'Tự soạn bài');
      auth.setAccount(const Account('a', 'a@example.com'));
      await tester.pumpAndSettle();
      expect(
        find.text('Bạn không có quyền quản trị nội dung.'),
        findsOneWidget,
      );
      expect(find.text('Lưu bản nháp'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Published catalog updates preserve sample progress and keep drafts invisible',
    () async {
      final repository = FakeContent();
      final store = LearningStore(userId: 'u');
      final initialCount = store.published.length;
      await store.finish(store.lessons.first, 100);
      store.connectContent(repository);
      await Future<void>.delayed(Duration.zero);
      final id = repository.newId();
      await repository.saveDraft(id, 0, {
        ...lessonContent(seedLessons().first),
        'title': 'Bài mới',
      });
      await Future<void>.delayed(Duration.zero);
      expect(store.published.length, initialCount);
      await repository.publish(ContentEntry(id, repository.entries[id]!));
      await Future<void>.delayed(Duration.zero);
      expect(store.published.length, initialCount + 1);
      expect(store.published.last.title, 'Bài mới');
      expect(store.xp, 30);
      await repository.archive(ContentEntry(id, repository.entries[id]!));
      await Future<void>.delayed(Duration.zero);
      expect(store.published.length, initialCount);
      store.dispose();
      await repository.close();
    },
  );

  testWidgets('Learners cannot open admin authoring screens', (tester) async {
    final repository = FakeContent();
    await tester.pumpWidget(adminApp(repository, admin: false));
    expect(find.text('Bạn không có quyền quản trị nội dung.'), findsOneWidget);
    expect(find.text('Tự soạn bài'), findsNothing);
  });

  testWidgets('Admin manually authors a draft and confirms publication', (
    tester,
  ) async {
    final repository = FakeContent();
    await tester.pumpWidget(adminApp(repository));
    await tester.pumpAndSettle();
    await tap(tester, 'Tự soạn bài');
    Future<void> fill(String label, String value) async {
      final finder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          300,
          maxScrolls: 60,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(finder);
      await tester.enterText(finder, value);
      await tester.pumpAndSettle();
    }

    await fill('Tên bài học', 'Lời chào mới');
    await fill('Mục tiêu bài học', 'Biết cách chào');
    await fill('Từ mới', 'Hello');
    await fill('Nghĩa tiếng Việt', 'Xin chào');
    await fill('Phiên âm', 'həˈləʊ');
    await fill('Câu ví dụ', 'Hello, Anna!');
    await fill('Dịch câu ví dụ', 'Xin chào Anna!');
    await fill('Đề bài', 'Hello nghĩa là gì?');
    await fill('Lựa chọn (mỗi dòng 1 lựa chọn)', 'Xin chào\nTạm biệt');
    await fill('Đáp án đúng', 'Xin chào');
    await fill('Giải thích đáp án', 'Hello là lời chào.');
    await tap(tester, 'Lưu bản nháp');
    expect(repository.entries.length, 1);
    expect(repository.entries.values.single['status'], 'draft');
    await tap(tester, 'Xuất bản');
    expect(repository.entries.values.single['status'], 'draft');
    await tester.tap(find.widgetWithText(TextButton, 'Xuất bản'));
    await tester.pumpAndSettle();
    expect(repository.entries.values.single['status'], 'published');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AI authoring requests a draft and never publishes it automatically',
    (tester) async {
      final repository = FakeContent();
      await tester.pumpWidget(adminApp(repository));
      await tester.pumpAndSettle();
      await tap(tester, 'AI tạo bản nháp');
      await tester.enterText(find.byType(TextFormField), 'Du lịch');
      await tap(tester, 'Tạo bản nháp bằng AI');
      expect(repository.generatedTopic, 'Du lịch');
      expect(repository.entries.values.single['status'], 'draft');
      expect(find.textContaining('Đã lưu bản nháp'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
