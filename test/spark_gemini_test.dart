import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingogo/content_repository.dart';
import 'package:lingogo/data.dart';
import 'package:lingogo/gemini_service.dart';
import 'package:lingogo/lesson_validation.dart';

class StubGemini implements GeminiService {
  StubGemini(this.result);
  final String result;
  bool requestedJson = false;
  @override
  Future<String> reply({
    required String instructions,
    required List<Map<String, String>> messages,
    bool json = false,
  }) async {
    requestedJson = json;
    expect(instructions, contains('Vietnamese'));
    expect(jsonDecode(messages.single['content']!)['languageCode'], 'en');
    return result;
  }
}

Map<String, dynamic> fixture() {
  final lesson = lessonContent(seedLessons().first);
  final words = lesson['vocabulary'] as List;
  while (words.length < 5) {
    words.add({
      'word': 'word${words.length}',
      'meaning': 'meaning${words.length}',
      'pronunciation': 'test',
      'example': 'Example sentence',
      'exampleTranslation': 'Example translation',
    });
  }
  return lesson;
}

Future<Map<String, dynamic>> generate(Map<String, dynamic> data) =>
    generateGeminiLesson(
      StubGemini(jsonEncode(data)),
      languageCode: 'en',
      level: 'A1',
      topic: 'Greetings',
    );

void main() {
  test(
    'Gemini draft requests structured JSON and strips privilege fields',
    () async {
      final data = fixture()..addAll({'status': 'published', 'admin': true});
      final ai = StubGemini(jsonEncode(data));
      final result = await generateGeminiLesson(
        ai,
        languageCode: 'en',
        level: 'A1',
        topic: 'Greetings',
      );
      expect(ai.requestedJson, isTrue);
      expect(result.containsKey('status'), isFalse);
      expect(result.containsKey('admin'), isFalse);
      expect((result['vocabulary'] as List).length, 5);
      expect((result['exercises'] as List).length, 4);
    },
  );
  test('Malformed Gemini JSON is rejected', () async {
    await expectLater(
      generateGeminiLesson(
        StubGemini('not json'),
        languageCode: 'en',
        level: 'A1',
        topic: 'Greetings',
      ),
      throwsA(isA<ContentFailure>()),
    );
  });
  test('Wrong language and overlong lessons are rejected', () async {
    final wrongLanguage = fixture()
      ..addAll({'languageCode': 'ja', 'level': 'JLPT N5'});
    await expectLater(generate(wrongLanguage), throwsA(isA<ContentFailure>()));
    final tooMany = fixture();
    (tooMany['vocabulary'] as List).add((tooMany['vocabulary'] as List).first);
    await expectLater(generate(tooMany), throwsA(isA<ContentFailure>()));
  });
  test('Choice answer outside options is rejected before saving', () {
    final data = fixture();
    final choices = (data['exercises'] as List).firstWhere(
      (e) => e['type'] == 'multiple_choice',
    );
    choices['answer'] = 'unlisted answer';
    expect(() => validateLessonContent(data), throwsA(isA<ContentFailure>()));
  });
}
