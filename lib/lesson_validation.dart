import 'course_catalog.dart';

const maxLessonWords = 5;
const maxLessonQuestions = 4;
const starterLevels = {
  'en': 'A1',
  'zh': 'HSK 1',
  'ja': 'JLPT N5',
  'ko': 'TOPIK I',
};

class ContentFailure implements Exception {
  const ContentFailure(this.message);
  final String message;
}

String checkedText(dynamic value, String label, int max) {
  if (value is! String || value.trim().isEmpty || value.trim().length > max) {
    throw ContentFailure('$label: cần nhập từ 1 đến $max ký tự.');
  }
  return value.trim();
}

String normalizedAnswer(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[.!?]'), '')
    .replaceAll(RegExp(r'\s+'), ' ');

Map<String, dynamic> validateLessonContent(Map<String, dynamic> input) {
  final language = checkedText(input['languageCode'], 'Ngôn ngữ', 2);
  if (!starterLevels.containsKey(language) ||
      !supportsLevel(
        language,
        input['level'] is String ? input['level'] as String : '',
      )) {
    throw const ContentFailure('Chọn đúng ngôn ngữ và cấp độ hợp lệ.');
  }
  final order = input['order'];
  if (order is! int || order < 0 || order > 100000) {
    throw const ContentFailure('Thứ tự cần là số nguyên từ 0 đến 100000.');
  }
  final words = input['vocabulary'];
  final questions = input['exercises'];
  if (words is! List || words.isEmpty || words.length > maxLessonWords) {
    throw const ContentFailure('Mỗi bài cần 1–5 từ vựng.');
  }
  if (questions is! List ||
      questions.isEmpty ||
      questions.length > maxLessonQuestions) {
    throw const ContentFailure('Mỗi bài cần 1–4 câu hỏi.');
  }
  final vocabulary = words.map((w) {
    if (w is! Map) throw const ContentFailure('Dữ liệu từ vựng không hợp lệ.');
    return {
      'word': checkedText(w['word'], 'Từ', 100),
      'meaning': checkedText(w['meaning'], 'Nghĩa', 150),
      'pronunciation': checkedText(w['pronunciation'], 'Phiên âm', 150),
      'example': checkedText(w['example'], 'Ví dụ', 400),
      'exampleTranslation': checkedText(
        w['exampleTranslation'],
        'Dịch ví dụ',
        400,
      ),
    };
  }).toList();
  if (vocabulary.map((w) => w['word']).toSet().length != vocabulary.length) {
    throw const ContentFailure('Từ vựng không được trùng nhau.');
  }
  final exercises = questions.map((q) {
    if (q is! Map) throw const ContentFailure('Dữ liệu câu hỏi không hợp lệ.');
    final type = q['type'];
    if (![
      'multiple_choice',
      'fill_blank',
      'reorder_words',
      'match_pairs',
    ].contains(type)) {
      throw const ContentFailure('Loại câu hỏi không hỗ trợ.');
    }
    final rawOptions = q['options'];
    if (rawOptions is! List || rawOptions.length > 12) {
      throw const ContentFailure('Tối đa 12 lựa chọn trong một câu hỏi.');
    }
    final options = rawOptions
        .map((o) => checkedText(o, 'Lựa chọn', 150))
        .toList();
    if (options.map(normalizedAnswer).toSet().length != options.length) {
      throw const ContentFailure('Các lựa chọn không được trùng nhau.');
    }
    final answer = checkedText(q['answer'], 'Đáp án', 1000);
    if (type == 'multiple_choice' &&
        (options.length < 2 ||
            options.length > 6 ||
            !options.contains(answer))) {
      throw const ContentFailure(
        'Trắc nghiệm cần 2–6 lựa chọn và đáp án khớp một lựa chọn.',
      );
    }
    if (type == 'fill_blank' && options.isNotEmpty) {
      throw const ContentFailure('Điền từ không có danh sách lựa chọn.');
    }
    if (type == 'reorder_words') {
      final tokens = answer.split(' ');
      if (options.length < 2 ||
          options.any((o) => RegExp(r'\s').hasMatch(o)) ||
          tokens.length != options.length ||
          !tokens.toSet().containsAll(options) ||
          tokens.toSet().length != options.length) {
        throw const ContentFailure(
          'Câu sắp xếp cần dùng đủ mỗi từ đúng một lần, phân cách bằng một dấu cách.',
        );
      }
    }
    if (type == 'match_pairs') {
      final pairs = answer.split('|').map((p) => p.split(':')).toList();
      if (options.length != 6 ||
          options.any((o) => RegExp(r'[:|]').hasMatch(o)) ||
          pairs.length != 3 ||
          pairs.any((p) => p.length != 2)) {
        throw const ContentFailure(
          'Ghép cặp cần đúng 3 từ và 3 nghĩa, không chứa dấu : hoặc |.',
        );
      }
      for (var i = 0; i < 3; i++) {
        if (pairs[i][0] != options[i] ||
            !options.skip(3).contains(pairs[i][1])) {
          throw const ContentFailure('Đáp án ghép cặp chưa khớp các lựa chọn.');
        }
      }
      if (pairs.map((p) => p[1]).toSet().length != 3) {
        throw const ContentFailure('Mỗi nghĩa chỉ được ghép một lần.');
      }
    }
    return {
      'type': type,
      'prompt': checkedText(q['prompt'], 'Đề bài', 500),
      'options': options,
      'answer': answer,
      'explanation': checkedText(q['explanation'], 'Giải thích', 700),
    };
  }).toList();
  return {
    'languageCode': language,
    'level': input['level'],
    'title': checkedText(input['title'], 'Tên bài', 120),
    'subtitle': checkedText(input['subtitle'], 'Mục tiêu', 300),
    'icon': checkedText(input['icon'], 'Biểu tượng', 12),
    'order': order,
    'vocabulary': vocabulary,
    'exercises': exercises,
  };
}
