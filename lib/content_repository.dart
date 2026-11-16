import 'data.dart';
export 'spark_content_repository.dart';
export 'content_errors.dart';

const exerciseTypeNames = {
  ExerciseType.choice: 'multiple_choice',
  ExerciseType.blank: 'fill_blank',
  ExerciseType.reorder: 'reorder_words',
  ExerciseType.pairs: 'match_pairs',
};

class ContentEntry {
  const ContentEntry(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  String get status => data['status'] as String? ?? 'draft';
  int get revision => data['revision'] as int? ?? 0;
  String get title => data['title'] as String? ?? 'Bài chưa đặt tên';
  Lesson get lesson => decodeLesson(id, data);
}

Lesson decodeLesson(String id, Map<String, dynamic> data) {
  final vocabulary = (data['vocabulary'] as List).map((raw) {
    final w = Map<String, dynamic>.from(raw as Map);
    return Vocab(
      w['word'] as String,
      w['meaning'] as String,
      w['pronunciation'] as String,
      w['example'] as String,
      w['exampleTranslation'] as String,
    );
  }).toList();
  final exercises = (data['exercises'] as List).map((raw) {
    final e = Map<String, dynamic>.from(raw as Map);
    final type = exerciseTypeNames.entries
        .firstWhere((t) => t.value == e['type'])
        .key;
    return Exercise(
      type,
      e['prompt'] as String,
      e['answer'] as String,
      e['explanation'] as String,
      options: List<String>.from(e['options'] as List),
    );
  }).toList();
  if (vocabulary.isEmpty || exercises.isEmpty || !id.startsWith('l_')) {
    throw const FormatException('Invalid lesson content');
  }
  return Lesson(
    id,
    data['title'] as String,
    data['subtitle'] as String,
    data['icon'] as String? ?? '📖',
    vocabulary,
    exercises,
    languageCode: data['languageCode'] as String,
    level: data['level'] as String,
    order: data['order'] as int? ?? 100,
    version: data['version'] as int? ?? 1,
    published: data['status'] == 'published',
  );
}

Map<String, dynamic> lessonContent(Lesson lesson) => {
  'languageCode': lesson.languageCode,
  'level': lesson.level.isEmpty
      ? learningLanguages.firstWhere((l) => l.code == lesson.languageCode).level
      : lesson.level,
  'title': lesson.title,
  'subtitle': lesson.subtitle,
  'icon': lesson.icon,
  'order': lesson.order,
  'vocabulary': lesson.words
      .map(
        (w) => {
          'word': w.word,
          'meaning': w.meaning,
          'pronunciation': w.phonetic,
          'example': w.example,
          'exampleTranslation': w.translation,
        },
      )
      .toList(),
  'exercises': lesson.exercises
      .map(
        (e) => {
          'type': exerciseTypeNames[e.type],
          'prompt': e.prompt,
          'options': e.options,
          'answer': e.answer,
          'explanation': e.explanation,
        },
      )
      .toList(),
};

abstract class ContentRepository {
  Stream<List<Lesson>> watchPublished();
  Stream<List<ContentEntry>> watchAll();
  String newId();
  Future<void> saveDraft(String id, int revision, Map<String, dynamic> content);
  Future<void> publish(ContentEntry entry);
  Future<void> archive(ContentEntry entry);
  Future<String> generate({
    required String languageCode,
    required String level,
    required String topic,
    required String requestId,
    String provider = 'gemini',
  });
  Future<String> chat({
    required String languageCode,
    String? level,
    required String situation,
    required String message,
    required List<Map<String, String>> history,
    required String requestId,
    String provider = 'gemini',
  });
}
