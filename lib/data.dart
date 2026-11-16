import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'languages.dart';
import 'course_catalog.dart';
import 'course_content.dart';
import 'content_repository.dart';

class LearningLanguage {
  const LearningLanguage(this.code, this.name, this.flag, this.level);
  final String code, name, flag, level;
}

const learningLanguages = [
  LearningLanguage('en', 'Tiếng Anh', '🇬🇧', 'A1'),
  LearningLanguage('zh', 'Tiếng Trung', '🇨🇳', 'HSK 1'),
  LearningLanguage('ja', 'Tiếng Nhật', '🇯🇵', 'JLPT N5'),
  LearningLanguage('ko', 'Tiếng Hàn', '🇰🇷', 'TOPIK I'),
];

enum ExerciseType { choice, blank, reorder, pairs }

class Exercise {
  const Exercise(
    this.type,
    this.prompt,
    this.answer,
    this.explanation, {
    this.options = const [],
  });
  final ExerciseType type;
  final String prompt, answer, explanation;
  final List<String> options;
}

class Lesson {
  Lesson(
    this.id,
    this.title,
    this.subtitle,
    this.icon,
    this.words,
    this.exercises, {
    this.published = true,
    this.languageCode = 'en',
    this.level = '',
    this.order = 0,
    this.version = 1,
  });
  final String id, title, subtitle, icon;
  final List<Vocab> words;
  final List<Exercise> exercises;
  bool published;
  final String languageCode;
  final String level;
  final int order, version;
}

class Vocab {
  const Vocab(
    this.word,
    this.meaning,
    this.phonetic,
    this.example,
    this.translation,
  );
  final String word, meaning, phonetic, example, translation;
}

const hello = Vocab(
  'Hello',
  'Xin chào',
  '/həˈləʊ/',
  'Hello! My name is Anna.',
  'Xin chào! Tên tôi là Anna.',
);
const thanks = Vocab(
  'Thank you',
  'Cảm ơn',
  '/ˈθæŋk juː/',
  'Thank you for your help.',
  'Cảm ơn bạn đã giúp đỡ.',
);
const goodbye = Vocab(
  'Goodbye',
  'Tạm biệt',
  '/ˌɡʊdˈbaɪ/',
  'Goodbye! See you tomorrow.',
  'Tạm biệt! Hẹn gặp bạn ngày mai.',
);
const name = Vocab(
  'Name',
  'Tên',
  '/neɪm/',
  'What is your name?',
  'Tên bạn là gì?',
);
const mother = Vocab(
  'Mother',
  'Mẹ',
  '/ˈmʌðə(r)/',
  'My mother is a teacher.',
  'Mẹ tôi là giáo viên.',
);
const father = Vocab(
  'Father',
  'Bố',
  '/ˈfɑːðə(r)/',
  'My father likes music.',
  'Bố tôi thích âm nhạc.',
);
const sister = Vocab(
  'Sister',
  'Chị / em gái',
  '/ˈsɪstə(r)/',
  'I have one sister.',
  'Tôi có một chị gái.',
);
const water = Vocab(
  'Water',
  'Nước',
  '/ˈwɔːtə(r)/',
  'I would like some water.',
  'Tôi muốn một ít nước.',
);
const bread = Vocab(
  'Bread',
  'Bánh mì',
  '/bred/',
  'I eat bread for breakfast.',
  'Tôi ăn bánh mì vào bữa sáng.',
);
const apple = Vocab(
  'Apple',
  'Quả táo',
  '/ˈæpl/',
  'This apple is sweet.',
  'Quả táo này ngọt.',
);

List<Lesson> seedLessons() => [
  Lesson(
    'greetings',
    'Xin chào, thế giới!',
    'Chào hỏi & giới thiệu bản thân',
    '👋',
    [hello, thanks, goodbye, name],
    const [
      Exercise(
        ExerciseType.choice,
        '“Hello” có nghĩa là gì?',
        'Xin chào',
        'Hello là cách chào hỏi thông dụng trong tiếng Anh.',
        options: ['Tạm biệt', 'Xin chào', 'Cảm ơn', 'Xin lỗi'],
      ),
      Exercise(
        ExerciseType.blank,
        'Điền từ còn thiếu: My ___ is Anna.',
        'name',
        'My name is Anna = Tên tôi là Anna.',
      ),
      Exercise(
        ExerciseType.reorder,
        'Sắp xếp câu: Tên bạn là gì?',
        'What is your name',
        'Câu hỏi tên: What is your name?',
        options: ['name', 'your', 'What', 'is'],
      ),
      Exercise(
        ExerciseType.pairs,
        'Chọn cặp từ và nghĩa tương ứng.',
        'Hello:Xin chào|Thank you:Cảm ơn|Goodbye:Tạm biệt',
        'Hello = Xin chào; Thank you = Cảm ơn; Goodbye = Tạm biệt.',
        options: [
          'Hello',
          'Thank you',
          'Goodbye',
          'Cảm ơn',
          'Tạm biệt',
          'Xin chào',
        ],
      ),
    ],
  ),
  Lesson(
    'family',
    'Gia đình của tôi',
    'Nói về những người thân yêu',
    '🏡',
    [mother, father, sister],
    const [
      Exercise(
        ExerciseType.choice,
        '“Mother” nghĩa là gì?',
        'Mẹ',
        'Mother là mẹ, father là bố.',
        options: ['Bố', 'Mẹ', 'Chị gái', 'Anh trai'],
      ),
      Exercise(
        ExerciseType.blank,
        'Điền từ chỉ “bố”: My ___ likes music.',
        'father',
        'My father likes music = Bố tôi thích âm nhạc.',
      ),
      Exercise(
        ExerciseType.reorder,
        'Sắp xếp câu: Tôi có một chị gái.',
        'I have one sister',
        'I have one sister = Tôi có một chị gái.',
        options: ['sister', 'one', 'have', 'I'],
      ),
      Exercise(
        ExerciseType.choice,
        '“My mother is a teacher.” nghĩa là gì?',
        'Mẹ tôi là giáo viên',
        'A teacher = một giáo viên.',
        options: [
          'Mẹ tôi là giáo viên',
          'Bố tôi thích âm nhạc',
          'Tôi là học sinh',
          'Tôi có một chị gái',
        ],
      ),
    ],
  ),
  Lesson(
    'food',
    'Một chút ngon lành',
    'Đồ ăn & thức uống hằng ngày',
    '🍎',
    [water, bread, apple],
    const [
      Exercise(
        ExerciseType.choice,
        'Bạn muốn uống nước. Chọn từ đúng.',
        'Water',
        'Water nghĩa là nước.',
        options: ['Bread', 'Apple', 'Water', 'Mother'],
      ),
      Exercise(
        ExerciseType.blank,
        'Điền từ chỉ “bánh mì”: I eat ___ for breakfast.',
        'bread',
        'Bread = bánh mì; breakfast = bữa sáng.',
      ),
      Exercise(
        ExerciseType.reorder,
        'Sắp xếp câu: Quả táo này ngọt.',
        'This apple is sweet',
        'This apple is sweet = Quả táo này ngọt.',
        options: ['sweet', 'is', 'This', 'apple'],
      ),
      Exercise(
        ExerciseType.choice,
        '“I would like some water.” nghĩa là gì?',
        'Tôi muốn một ít nước',
        'I would like… là cách nói lịch sự khi muốn điều gì.',
        options: [
          'Tôi thích táo',
          'Tôi muốn một ít nước',
          'Tôi ăn bánh mì',
          'Tôi đang nấu ăn',
        ],
      ),
    ],
  ),
];

List<Lesson> builtInLessons() => [
  ...seedLessons(),
  ...otherLanguageLessons(),
  ...courseLessons(),
];

class LearningStore extends ChangeNotifier {
  LearningStore({this.userId});
  final String? userId;
  String get storageKey =>
      userId == null ? 'lingogo.v1' : 'lingogo.v2.user.$userId';
  final lessons = builtInLessons();
  String languageCode = 'en';
  final selectedLevels = <String, String>{};
  String get currentLevel => selectedLevels[languageCode] ?? language.level;
  void selectLevel(String level) {
    if (!supportsLevel(languageCode, level)) return;
    selectedLevels[languageCode] = level;
    save();
  }

  LearningLanguage get language =>
      learningLanguages.firstWhere((l) => l.code == languageCode);
  void selectLanguage(String code) {
    if (!learningLanguages.any((l) => l.code == code)) return;
    languageCode = code;
    save();
  }

  final Map<String, int> scores = {};
  final Map<String, DateTime> reviews = {};
  final List<String> studyDays = [];
  String displayName = 'Bạn mới';
  bool onboarded = false, reminders = true;
  int dailyGoal = 10;
  String? saveError;
  SharedPreferences? _prefs;
  bool _disposed = false;
  StreamSubscription<List<Lesson>>? _contentSubscription;
  String? contentError;
  bool contentLoading = false;
  void connectContent(ContentRepository repository) {
    _contentSubscription?.cancel();
    contentLoading = true;
    contentError = null;
    _contentSubscription = repository.watchPublished().listen(
      (remote) {
        if (_disposed) return;
        lessons.removeWhere((lesson) => lesson.id.startsWith('l_'));
        final sorted = [...remote]
          ..sort((a, b) {
            final order = a.order.compareTo(b.order);
            return order == 0 ? a.id.compareTo(b.id) : order;
          });
        lessons.addAll(sorted);
        contentLoading = false;
        contentError = null;
        notifyListeners();
      },
      onError: (Object error) {
        if (_disposed) return;
        lessons.removeWhere((lesson) => lesson.id.startsWith('l_'));
        contentLoading = false;
        contentError = 'Chưa tải được bài mới. Bạn vẫn có thể học các bài mẫu.';
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _contentSubscription?.cancel();
    super.dispose();
  }

  List<Lesson> get published => lessons
      .where(
        (l) =>
            l.published &&
            l.languageCode == languageCode &&
            ((l.level.isEmpty ? language.level : l.level) == currentLevel),
      )
      .toList();
  List<Vocab> get words => published.expand((l) => l.words).toList();
  bool completed(String id) => (scores[id] ?? 0) >= 70;
  int get completedCount => published.where((l) => completed(l.id)).length;
  int get xp => scores.values.where((s) => s >= 70).length * 30;
  bool unlocked(Lesson lesson) {
    if (completed(lesson.id)) return true;
    final i = published.indexOf(lesson);
    return i == 0 || (i > 0 && completed(published[i - 1].id));
  }

  Lesson? get nextLesson {
    for (final l in published) {
      if (!completed(l.id)) return l;
    }
    return published.isEmpty ? null : published.last;
  }

  String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  int get streak {
    var day = DateTime.now();
    if (!studyDays.contains(dateKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var result = 0;
    while (studyDays.contains(dateKey(day))) {
      result++;
      day = day.subtract(const Duration(days: 1));
    }
    return result;
  }

  bool due(Vocab word) =>
      !reviews.containsKey('$languageCode:${word.word}') ||
      !reviews['$languageCode:${word.word}']!.isAfter(DateTime.now());

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(storageKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      displayName = data['name'] as String? ?? 'Bạn mới';
      final code = data['language'] as String? ?? 'en';
      languageCode = learningLanguages.any((l) => l.code == code) ? code : 'en';
      (data['levels'] as Map? ?? {}).forEach((code, level) {
        if (code is String && level is String && supportsLevel(code, level)) {
          selectedLevels[code] = level;
        }
      });
      onboarded = data['onboarded'] == true;
      reminders = data['reminders'] != false;
      dailyGoal = data['goal'] as int? ?? 10;
      scores.addAll(Map<String, int>.from(data['scores'] as Map? ?? {}));
      studyDays.addAll(List<String>.from(data['days'] as List? ?? []));
      (data['reviews'] as Map? ?? {}).forEach((k, v) {
        var key = k as String;
        if (!RegExp(r'^(en|zh|ja|ko):').hasMatch(key)) {
          final matching = lessons.where(
            (l) => l.words.any((w) => w.word == key),
          );
          key = '${matching.isEmpty ? 'en' : matching.first.languageCode}:$key';
        }
        reviews[key] = DateTime.parse(v as String);
      });
    } catch (_) {
      saveError =
          'Không đọc được dữ liệu trên thiết bị. Bạn vẫn có thể học trong phiên này.';
    }
  }

  Future<void> save() async {
    if (!_disposed) notifyListeners();
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final saved = await _prefs!.setString(
        storageKey,
        jsonEncode({
          'name': displayName,
          'language': languageCode,
          'levels': selectedLevels,
          'onboarded': onboarded,
          'goal': dailyGoal,
          'reminders': reminders,
          'scores': scores,
          'days': studyDays,
          'reviews': reviews.map((k, v) => MapEntry(k, v.toIso8601String())),
        }),
      );
      saveError = saved ? null : 'Chưa lưu được tiến độ. Hãy thử lại.';
    } catch (_) {
      saveError = 'Chưa lưu được tiến độ trên thiết bị. Hãy thử lại.';
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> finish(Lesson lesson, int score) async {
    if (score > (scores[lesson.id] ?? -1)) scores[lesson.id] = score;
    final today = dateKey(DateTime.now());
    if (!studyDays.contains(today)) studyDays.add(today);
    await save();
  }

  Future<void> review(Vocab word, bool remembered) async {
    reviews['$languageCode:${word.word}'] = DateTime.now().add(
      Duration(days: remembered ? 3 : 0),
    );
    await save();
  }
}
