import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingogo/course_catalog.dart';
import 'package:lingogo/course_content.dart';
import 'package:lingogo/content_repository.dart';
import 'package:lingogo/lesson_validation.dart';
import 'package:lingogo/data.dart';
import 'package:lingogo/gemini_service.dart';
import 'package:lingogo/skills_page.dart';

class WritingCoach implements GeminiService {
  String? instructions, submission;
  @override
  Future<String> reply({
    required String instructions,
    required List<Map<String, String>> messages,
    bool json = false,
  }) async {
    this.instructions = instructions;
    submission = messages.single['content'];
    return 'Câu viết tốt. Hãy chú ý cách dùng từ.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (call) async => 1,
        );
  });
  test('All 23 course levels have distinct starter practice units', () {
    final lessons = courseLessons();
    expect(courseLevels.values.expand((v) => v).length, 23);
    expect(lessons.length, 69);
    expect(lessons.map((l) => l.id).toSet().length, 69);
    for (final lesson in lessons) {
      expect(
        () => validateLessonContent(lessonContent(lesson)),
        returnsNormally,
        reason: lesson.id,
      );
    }
    for (final entry in courseLevels.entries) {
      for (final level in entry.value) {
        final units = lessons.where(
          (l) => l.languageCode == entry.key && l.level == level,
        );
        expect(units.length, 3, reason: '${entry.key} $level');
        expect(
          units.expand((l) => l.words).map((w) => w.example).toSet().length,
          3,
        );
        expect(units.every((l) => l.exercises.isNotEmpty), isTrue);
      }
    }
  });
  test(
    'Selected levels and progress persist per language and account',
    () async {
      final store = LearningStore(userId: 'a');
      await store.load();
      store.selectLanguage('zh');
      store.selectLevel('HSK 6');
      expect(store.published.length, 3);
      expect(store.published.every((l) => l.level == 'HSK 6'), isTrue);
      await store.finish(store.published.first, 100);
      store.selectLevel('HSK 1');
      expect(store.completedCount, 0);
      store.selectLevel('HSK 6');
      store.selectLanguage('ja');
      store.selectLevel('JLPT N1');
      await store.save();
      final restored = LearningStore(userId: 'a');
      await restored.load();
      expect(restored.currentLevel, 'JLPT N1');
      restored.selectLanguage('zh');
      expect(restored.currentLevel, 'HSK 6');
      expect(restored.completedCount, 1);
      restored.selectLevel('C2');
      expect(restored.currentLevel, 'HSK 6');
      final otherUser = LearningStore(userId: 'b');
      await otherUser.load();
      expect(otherUser.currentLevel, 'A1');
      expect(otherUser.scores, isEmpty);
    },
  );
  test('Listening comparison accepts punctuation and Chinese spacing', () {
    expect(practiceText('我叫小明。'), practiceText('我 叫 小明'));
    expect(practiceText('Hello!'), practiceText('hello'));
    expect(practiceText('你好'), isNot(practiceText('再见')));
  });
  testWidgets(
    'Listening plays the selected Chinese example with the correct locale',
    (tester) async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
            call,
          ) async {
            calls.add(call);
            return call.method == 'isLanguageAvailable' ? true : 1;
          });
      final store = LearningStore()..selectLanguage('zh');
      store.selectLevel('HSK 6');
      await tester.pumpWidget(MaterialApp(home: SkillsPage(store: store)));
      await tester.tap(find.text('Nghe mẫu'));
      await tester.pumpAndSettle();
      expect(
        calls.any((c) => c.method == 'setLanguage' && c.arguments == 'zh-CN'),
        isTrue,
      );
      expect(
        calls.any(
          (c) =>
              c.method == 'speak' &&
              c.arguments.toString().contains(store.words.first.example),
        ),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Unavailable speech recognition gives an actionable error', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugin.csdcorp.com/speech_to_text'),
          (call) async => false,
        );
    await tester.pumpWidget(
      MaterialApp(home: SkillsPage(store: LearningStore())),
    );
    await tester.tap(find.text('Nói'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu nói'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Chưa có quyền micro hoặc dịch vụ nhận diện'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('Chưa có quyền micro hoặc dịch vụ nhận diện'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Writing uses selected level and submits real learner text to coach',
    (tester) async {
      final store = LearningStore()..selectLanguage('zh');
      store.selectLevel('HSK 6');
      final coach = WritingCoach();
      await tester.pumpWidget(
        MaterialApp(
          home: SkillsPage(store: store, ai: coach),
        ),
      );
      await tester.tap(find.text('Viết'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '我们应该独立思考。');
      final button = find.text('Gemini góp ý');
      await Scrollable.ensureVisible(tester.element(button), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(coach.instructions, contains('HSK 6'));
      expect(coach.submission, contains('我们应该独立思考。'));
      expect(
        find.text('Câu viết tốt. Hãy chú ý cách dùng từ.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
