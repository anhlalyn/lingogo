import 'package:flutter/material.dart';
import 'app.dart';
import 'data.dart';

class LessonIntro extends StatelessWidget {
  const LessonIntro({super.key, required this.store, required this.lesson});
  final LearningStore store;
  final Lesson lesson;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Khám phá bài học')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Panel(
              color: const Color(0xFFEDE9FF),
              child: Column(
                children: [
                  Text(lesson.icon, style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(lesson.subtitle, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text(
                    '5 phút  ·  ${lesson.exercises.length} câu hỏi  ·  +30 XP khi đạt',
                    style: const TextStyle(color: purple),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Làm quen với từ mới',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đọc từ và ví dụ trước khi bắt đầu bài tập.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 16),
            for (final word in lesson.words)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${word.word} · ${word.meaning}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(word.phonetic, style: const TextStyle(color: muted)),
                      const SizedBox(height: 10),
                      Text(word.example),
                      Text(
                        word.translation,
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Đạt từ 70% để hoàn thành. Bạn có thể học lại nhiều lần; XP chỉ được cộng ở lần đạt đầu tiên.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 20),
            Primary(
              'Bắt đầu bài tập',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ExercisePage(store: store, lesson: lesson),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key, required this.store, required this.lesson});
  final LearningStore store;
  final Lesson lesson;
  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  int index = 0;
  String selected = '';
  bool checked = false, submitting = false;
  final input = TextEditingController();
  final scroll = ScrollController();
  final List<String> ordered = [];
  final Map<String, String> pairs = {};
  String? left;
  final List<bool> results = [];
  final List<String> answers = [];
  Exercise get exercise => widget.lesson.exercises[index];
  String normalize(String s) => s
      .trim()
      .toLowerCase()
        .replaceAll(RegExp(r'[.!?。！？]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
  String get answer => switch (exercise.type) {
    ExerciseType.choice => selected,
    ExerciseType.blank => input.text,
    ExerciseType.reorder => ordered.join(' '),
    ExerciseType.pairs =>
      exercise.options
          .take(3)
          .map((word) => '$word:${pairs[word] ?? ''}')
          .join('|'),
  };
  bool get ready => switch (exercise.type) {
    ExerciseType.choice => selected.isNotEmpty,
    ExerciseType.blank => input.text.trim().isNotEmpty,
    ExerciseType.reorder => ordered.length == exercise.options.length,
    ExerciseType.pairs => pairs.length == 3,
  };
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> next() async {
    if (!checked) {
      setState(() {
        results.add(normalize(answer) == normalize(exercise.answer));
        answers.add(answer);
        checked = true;
      });
      return;
    }
    if (index + 1 == widget.lesson.exercises.length) {
      setState(() => submitting = true);
      final score = (results.where((r) => r).length / results.length * 100)
          .round();
      final wasCompleted = widget.store.completed(widget.lesson.id);
      await widget.store.finish(widget.lesson, score);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ResultPage(
            store: widget.store,
            lesson: widget.lesson,
            score: score,
            results: results,
            answers: answers,
            earnedXp: score >= 70 && !wasCompleted ? 30 : 0,
          ),
        ),
      );
    } else {
      setState(() {
        index++;
        checked = false;
        selected = '';
        input.clear();
        ordered.clear();
        pairs.clear();
        left = null;
      });
      scroll.jumpTo(0);
    }
  }

  Future<bool> confirmExit() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tạm dừng bài học?'),
          content: const Text(
            'Câu trả lời của lượt này chưa được lưu. Bạn có thể bắt đầu lại bài sau.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Học tiếp'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thoát bài'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || submitting) return;
      final exit = await confirmExit();
      if (exit && context.mounted) Navigator.pop(context);
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text('Câu ${index + 1}/${widget.lesson.exercises.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                widget.lesson.icon,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(24),
            children: [
              LinearProgressIndicator(
                value:
                    (index + (checked ? 1 : 0)) /
                    widget.lesson.exercises.length,
                minHeight: 9,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: const Color(0xFFEAE5FA),
              ),
              const SizedBox(height: 28),
              Text(
                switch (exercise.type) {
                  ExerciseType.choice => 'CHỌN ĐÁP ÁN ĐÚNG',
                  ExerciseType.blank => 'ĐIỀN TỪ',
                  ExerciseType.reorder => 'SẮP XẾP CÂU',
                  ExerciseType.pairs => 'GHÉP CẶP',
                },
                style: const TextStyle(
                  color: purple,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                exercise.prompt,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 28),
              if (exercise.type == ExerciseType.choice)
                ...exercise.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(20),
                        backgroundColor: selected == option
                            ? const Color(0xFFEDE9FF)
                            : Colors.white,
                        side: BorderSide(
                          color: selected == option
                              ? purple
                              : const Color(0xFFE5E1F5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: checked
                          ? null
                          : () => setState(() => selected = option),
                      child: Row(
                        children: [
                          Icon(
                            selected == option
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected == option ? purple : muted,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(color: ink, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (exercise.type == ExerciseType.blank)
                TextField(
                  controller: input,
                  enabled: !checked,
                  onChanged: (_) => setState(() {}),
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Nhập từ còn thiếu',
                    hintText: 'Câu trả lời của bạn',
                  ),
                ),
              if (exercise.type == ExerciseType.reorder) ...[
                Panel(
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      ordered.isEmpty
                          ? 'Chạm các từ bên dưới theo đúng thứ tự'
                          : ordered.join(' '),
                      style: TextStyle(
                        fontSize: 20,
                        color: ordered.isEmpty ? muted : ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: exercise.options
                      .map(
                        (word) => ActionChip(
                          label: Text(word),
                          onPressed: checked || ordered.contains(word)
                              ? null
                              : () => setState(() => ordered.add(word)),
                        ),
                      )
                      .toList(),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: checked || ordered.isEmpty
                        ? null
                        : () => setState(() => ordered.removeLast()),
                    icon: const Icon(Icons.undo),
                    label: const Text('Bỏ từ cuối'),
                  ),
                ),
              ],
              if (exercise.type == ExerciseType.pairs) ...[
                const Text(
                  'Chọn một từ bên trái, sau đó chọn nghĩa bên phải.',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: exercise.options
                            .take(3)
                            .map(
                              (word) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                        horizontal: 8,
                                      ),
                                      backgroundColor: left == word
                                          ? const Color(0xFFEDE9FF)
                                          : Colors.white,
                                    ),
                                    onPressed: checked
                                        ? null
                                        : () => setState(() => left = word),
                                    child: Text(
                                      pairs.containsKey(word)
                                          ? '$word ✓'
                                          : word,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: exercise.options
                            .skip(3)
                            .map(
                              (meaning) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                        horizontal: 8,
                                      ),
                                    ),
                                    onPressed: checked || left == null
                                        ? null
                                        : () => setState(() {
                                            pairs.removeWhere(
                                              (k, v) => v == meaning,
                                            );
                                            pairs[left!] = meaning;
                                            left = null;
                                          }),
                                    child: Text(
                                      pairs.containsValue(meaning)
                                          ? '$meaning ✓'
                                          : meaning,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
                for (final entry in pairs.entries)
                  Text(
                    '${entry.key} ↔ ${entry.value}',
                    style: const TextStyle(color: purple),
                  ),
                TextButton(
                  onPressed: checked || pairs.isEmpty
                      ? null
                      : () => setState(() {
                          pairs.clear();
                          left = null;
                        }),
                  child: const Text('Ghép lại'),
                ),
              ],
              const SizedBox(height: 24),
              if (checked) ...[
                Panel(
                  color: results.last
                      ? const Color(0xFFE6F7EF)
                      : const Color(0xFFFFF1E6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        results.last
                            ? 'Chính xác! Làm tốt lắm 🎉'
                            : 'Cùng ghi nhớ cho lần sau nhé!',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: results.last
                              ? const Color(0xFF187D57)
                              : const Color(0xFF9C5522),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(exercise.explanation),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Primary(
                submitting
                    ? 'Đang lưu kết quả…'
                    : !checked
                    ? 'Kiểm tra'
                    : index + 1 == widget.lesson.exercises.length
                    ? 'Xem kết quả'
                    : 'Câu tiếp theo',
                onPressed: submitting || (!checked && !ready) ? null : next,
                icon: !checked ? Icons.check : Icons.arrow_forward,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.store,
    required this.lesson,
    required this.score,
    required this.results,
    required this.answers,
    required this.earnedXp,
  });
  final LearningStore store;
  final Lesson lesson;
  final int score, earnedXp;
  final List<bool> results;
  final List<String> answers;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kết quả bài học')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              score >= 70 ? '🎉' : '🌱',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 90),
            ),
            const SizedBox(height: 18),
            Text(
              score >= 70 ? 'Bạn làm tốt lắm!' : 'Mỗi lần học, một lần tiến bộ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              score >= 70
                  ? 'Đã hoàn thành ${lesson.title}'
                  : 'Cần đạt 70% để mở khóa bài tiếp theo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 28),
            Panel(
              color: const Color(0xFFEDE9FF),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  metric('$score%', 'Điểm số'),
                  metric(
                    '${results.where((r) => r).length}/${results.length}',
                    'Câu đúng',
                  ),
                  metric('+$earnedXp', 'XP nhận được'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (store.saveError != null) ...[
              Panel(child: Text(store.saveError!)),
              TextButton(
                onPressed: store.save,
                child: const Text('Thử lưu lại'),
              ),
            ],
            if (earnedXp == 0 && score >= 70)
              const Text(
                'Bạn đã nhận XP của bài này. Ôn lại giúp củng cố kiến thức!',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            const SizedBox(height: 24),
            const Text(
              'Xem lại câu trả lời',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < results.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            results[i]
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: results[i] ? green : Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lesson.exercises[i].prompt,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bạn trả lời: ${answers[i]}',
                        style: const TextStyle(color: muted),
                      ),
                      const SizedBox(height: 6),
                      Text(lesson.exercises[i].explanation),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Primary(
              'Về hành trình học',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ExercisePage(store: store, lesson: lesson),
                ),
              ),
              child: const Text('Luyện lại bài này'),
            ),
          ],
        ),
      ),
    ),
  );
  Widget metric(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: purple,
        ),
      ),
      Text(label, style: const TextStyle(color: muted, fontSize: 12)),
    ],
  );
}
