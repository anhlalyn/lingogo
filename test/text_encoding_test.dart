import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingogo/app.dart';
import 'package:lingogo/admin_page.dart';
import 'package:lingogo/data.dart';

void main() {
  test('Dart source uses valid UTF-8 without replacement characters', () {
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final text = utf8.decode(file.readAsBytesSync());
      expect(text.contains('\uFFFD'), isFalse, reason: file.path);
      for (final marker in ['\u00e1\u00ba', '\u00e1\u00bb', '\u00c4\u2018']) {
        expect(text.contains(marker), isFalse, reason: '${file.path}: $marker');
      }
    }
  });
  testWidgets('Course and admin labels preserve Vietnamese accents', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = LearningStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CourseControls(store: store),
              levelPicker('zh', 'HSK 6', (_) {}),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Khóa học / cấp độ'), findsOneWidget);
    expect(find.text('Luyện nghe · nói · viết'), findsOneWidget);
    expect(
      find.text(
        'Bài thực hành theo cấp độ; chưa phải toàn bộ giáo trình luyện thi chính thức.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cấp độ bài học'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
