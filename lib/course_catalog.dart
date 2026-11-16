const courseLevels = <String, List<String>>{
  'en': ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'],
  'zh': ['HSK 1', 'HSK 2', 'HSK 3', 'HSK 4', 'HSK 5', 'HSK 6'],
  'ja': ['JLPT N5', 'JLPT N4', 'JLPT N3', 'JLPT N2', 'JLPT N1'],
  'ko': [
    'TOPIK I',
    'TOPIK I 2',
    'TOPIK II 3',
    'TOPIK II 4',
    'TOPIK II 5',
    'TOPIK II 6',
  ],
};

bool supportsLevel(String language, String level) =>
    courseLevels[language]?.contains(level) == true;

String levelLabel(String level) => switch (level) {
  'TOPIK I' => 'TOPIK I · cấp 1',
  'TOPIK I 2' => 'TOPIK I · cấp 2',
  'TOPIK II 3' => 'TOPIK II · cấp 3',
  'TOPIK II 4' => 'TOPIK II · cấp 4',
  'TOPIK II 5' => 'TOPIK II · cấp 5',
  'TOPIK II 6' => 'TOPIK II · cấp 6',
  _ => level,
};

const speechLocales = {
  'en': 'en-US',
  'zh': 'zh-CN',
  'ja': 'ja-JP',
  'ko': 'ko-KR',
};
