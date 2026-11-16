import 'course_catalog.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'data.dart';
import 'content_repository.dart';
import 'lesson_validation.dart';

bool canManage(BuildContext context) =>
    AuthScope.of(context).account?.isAdmin == true;
Widget deniedPage() => Scaffold(
  appBar: AppBar(title: const Text('Quản trị')),
  body: const Center(child: Text('Bạn không có quyền quản trị nội dung.')),
);
String statusLabel(String status) => switch (status) {
  'published' => 'Đã xuất bản',
  'archived' => 'Đã lưu trữ',
  _ => 'Bản nháp',
};

List<ContentEntry> adminLessonCatalog(List<ContentEntry> remote) => [
  ...remote,
  for (final lesson in builtInLessons())
    ContentEntry(lesson.id, {
      ...lessonContent(lesson),
      'source': 'builtin',
      'status': 'published',
      'revision': 0,
    }),
];

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.repository});
  final ContentRepository repository;
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Stream<List<ContentEntry>> entries = widget.repository.watchAll();
  String filter = 'all', query = '';
  String language = 'all', level = 'all';
  String? error;
  bool busy = false;
  Future<void> action(ContentEntry entry, bool publish) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(publish ? 'Xuất bản bài học?' : 'Lưu trữ bài học?'),
        content: Text(
          publish
              ? 'Hãy kiểm tra từ vựng, đáp án và giải thích. Sau khi xuất bản, nội dung này được giữ nguyên; muốn chỉnh sửa, bạn cần tạo bản sao mới.'
              : 'Bài sẽ không còn xuất hiện trong lộ trình của người học. Dữ liệu và kết quả cũ vẫn được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(publish ? 'Xuất bản' : 'Lưu trữ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (publish) {
        await widget.repository.publish(entry);
      } else {
        await widget.repository.archive(entry);
      }
    } catch (e) {
      if (mounted) setState(() => error = contentErrorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void edit([ContentEntry? entry, bool copy = false]) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          LessonEditor(repository: widget.repository, entry: entry, copy: copy),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (!canManage(context)) return deniedPage();
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý bài học')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Từ ý tưởng đến bài học',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'Tất cả khóa học và bài có sẵn đều xuất hiện ở đây, cùng các bài bạn tạo. Có thể xem và tạo bản sao bài có sẵn để chỉnh sửa.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : () => edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tự soạn bài'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => GenerateLessonPage(
                                repository: widget.repository,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AI tạo bản nháp'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextField(
                onChanged: (s) => setState(() => query = s.toLowerCase()),
                decoration: const InputDecoration(
                  labelText: 'Tìm bài học',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey('admin-language:$language'),
                initialValue: language,
                decoration: const InputDecoration(labelText: 'Lọc ngôn ngữ'),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('Tất cả ngôn ngữ'),
                  ),
                  ...learningLanguages.map(
                    (l) => DropdownMenuItem(
                      value: l.code,
                      child: Text('${l.flag} ${l.name}'),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  language = value!;
                  level = 'all';
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('admin-level:$language:$level'),
                initialValue: level,
                decoration: const InputDecoration(labelText: 'Lọc cấp độ'),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('Tất cả cấp độ'),
                  ),
                  ...(language == 'all'
                          ? courseLevels.values.expand((l) => l)
                          : courseLevels[language]!)
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(levelLabel(l)),
                        ),
                      ),
                ],
                onChanged: (value) => setState(() => level = value!),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: ['all', 'draft', 'published', 'archived']
                    .map(
                      (s) => ChoiceChip(
                        label: Text(s == 'all' ? 'Tất cả' : statusLabel(s)),
                        selected: filter == s,
                        onSelected: (_) => setState(() => filter = s),
                      ),
                    )
                    .toList(),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              StreamBuilder<List<ContentEntry>>(
                stream: entries,
                builder: (context, snapshot) {
                  final catalog = adminLessonCatalog(snapshot.data ?? []);
                  final list = catalog
                      .where(
                        (e) =>
                            (filter == 'all' || e.status == filter) &&
                            (language == 'all' ||
                                e.data['languageCode'] == language) &&
                            (level == 'all' || e.data['level'] == level) &&
                            e.title.toLowerCase().contains(query),
                      )
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${catalog.length} bài học · ${courseLevels.values.expand((l) => l).length} cấp độ',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final lang in learningLanguages)
                            for (final course in courseLevels[lang.code]!)
                              ActionChip(
                                key: ValueKey(
                                  'admin-course:${lang.code}:$course',
                                ),
                                label: Text(
                                  '${lang.flag} ${levelLabel(course)} · ${catalog.where((e) => e.data['languageCode'] == lang.code && e.data['level'] == course).length} bài',
                                ),
                                onPressed: () => setState(() {
                                  language = lang.code;
                                  level = course;
                                }),
                              ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('${list.length} bài phù hợp'),
                      if (snapshot.hasError)
                        Panel(
                          child: Column(
                            children: [
                              const Text(
                                'Chưa tải được nội dung. Kiểm tra kết nối hoặc quyền quản trị.',
                              ),
                              TextButton(
                                onPressed: () => setState(
                                  () => entries = widget.repository.watchAll(),
                                ),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const LinearProgressIndicator(),
                      if (list.isEmpty)
                        const Panel(
                          child: Text(
                            'Chưa có bài phù hợp. Bắt đầu bằng “Tự soạn bài” hoặc “AI tạo bản nháp”.',
                          ),
                        ),
                      Column(
                        children: list
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Panel(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${entry.data['languageCode']} · ${levelLabel(entry.data['level'] as String)} · ${statusLabel(entry.status)} · ${entry.data['source'] == 'builtin'
                                            ? 'Có sẵn trong app'
                                            : entry.data['source'] == 'ai'
                                            ? 'AI tạo'
                                            : 'Tự soạn'}',
                                        style: const TextStyle(color: muted),
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          OutlinedButton(
                                            onPressed: busy
                                                ? null
                                                : () => edit(
                                                    entry,
                                                    entry.status != 'draft',
                                                  ),
                                            child: Text(
                                              entry.status == 'draft'
                                                  ? 'Xem & sửa nháp'
                                                  : 'Xem & tạo bản sao',
                                            ),
                                          ),
                                          if (entry.status == 'draft')
                                            FilledButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => action(entry, true),
                                              child: const Text('Xuất bản'),
                                            ),
                                          if (entry.status != 'archived' &&
                                              entry.data['source'] != 'builtin')
                                            TextButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => action(entry, false),
                                              child: const Text('Lưu trữ'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GenerateLessonPage extends StatefulWidget {
  const GenerateLessonPage({super.key, required this.repository});
  final ContentRepository repository;
  @override
  State<GenerateLessonPage> createState() => _GenerateLessonPageState();
}

class _GenerateLessonPageState extends State<GenerateLessonPage> {
  final form = GlobalKey<FormState>();
  final topic = TextEditingController();
  String code = 'en';
  String level = 'A1';
  String provider = 'gemini';
  bool busy = false;
  String? error, result;
  late String requestId = widget.repository.newId();
  @override
  void dispose() {
    topic.dispose();
    super.dispose();
  }

  Future<void> generate() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final id = await widget.repository.generate(
        languageCode: code,
        level: level,
        topic: topic.text.trim(),
        requestId: requestId,
        provider: provider,
      );
      if (mounted) setState(() => result = id);
    } catch (e) {
      if (mounted) setState(() => error = contentErrorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!canManage(context)) return deniedPage();
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('AI tạo bài nháp')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Panel(
                  color: Color(0xFFEDE9FF),
                  child: Text(
                    'Gemini tạo 5 từ vựng và 4 câu hỏi để bạn kiểm tra, sửa và duyệt. Bản Spark sử dụng hạn mức miễn phí của Google; hết hạn mức sẽ báo để thử lại sau.',
                  ),
                ),
                const SizedBox(height: 22),
                if (result == null)
                  Form(
                    key: form,
                    child: Column(
                      children: [
                        const Chip(label: Text('Gemini')),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: code,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Ngôn ngữ & cấp độ',
                          ),
                          items: learningLanguages
                              .map(
                                (l) => DropdownMenuItem(
                                  value: l.code,
                                  child: Text(
                                    '${l.flag} ${l.name} · ${l.level}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: busy
                              ? null
                              : (value) => setState(() {
                                  code = value!;
                                  level = courseLevels[code]!.first;
                                  requestId = widget.repository.newId();
                                }),
                        ),
                        levelPicker(
                          code,
                          level,
                          busy
                              ? null
                              : (v) => setState(() {
                                  level = v;
                                  requestId = widget.repository.newId();
                                }),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: topic,
                          enabled: !busy,
                          maxLength: 120,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Chủ đề',
                            hintText: 'Ví dụ: Gọi món tại nhà hàng',
                          ),
                          onChanged: (_) {
                            requestId = widget.repository.newId();
                          },
                          validator: (s) => s == null || s.trim().isEmpty
                              ? 'Nhập chủ đề bài học.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Primary(
                          busy ? 'Đang tạo bài nháp…' : 'Tạo bản nháp bằng AI',
                          onPressed: busy ? null : generate,
                          icon: Icons.auto_awesome,
                        ),
                      ],
                    ),
                  )
                else ...[
                  const Panel(
                    color: Color(0xFFE6F7EF),
                    child: Text(
                      'Đã lưu bản nháp. Quay về danh sách, mở bài để kiểm tra từ vựng, đáp án và giải thích trước khi xuất bản.',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Primary(
                    'Về danh sách bài học',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
                if (busy)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'AI có thể sai. Hãy kiểm tra ngữ pháp, nghĩa, phiên âm và đáp án. Nếu chờ quá lâu, kiểm tra danh sách nháp trước khi gửi yêu cầu mới.',
                  style: TextStyle(color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WordFields {
  WordFields([Map? data])
    : word = TextEditingController(text: data?['word'] as String? ?? ''),
      meaning = TextEditingController(text: data?['meaning'] as String? ?? ''),
      pronunciation = TextEditingController(
        text: data?['pronunciation'] as String? ?? '',
      ),
      example = TextEditingController(text: data?['example'] as String? ?? ''),
      translation = TextEditingController(
        text: data?['exampleTranslation'] as String? ?? '',
      );
  final TextEditingController word,
      meaning,
      pronunciation,
      example,
      translation;
  Map<String, dynamic> toJson() => {
    'word': word.text.trim(),
    'meaning': meaning.text.trim(),
    'pronunciation': pronunciation.text.trim(),
    'example': example.text.trim(),
    'exampleTranslation': translation.text.trim(),
  };
  void dispose() {
    for (final c in [word, meaning, pronunciation, example, translation]) {
      c.dispose();
    }
  }
}

class QuestionFields {
  QuestionFields([Map? data])
    : type = data?['type'] as String? ?? 'multiple_choice',
      prompt = TextEditingController(text: data?['prompt'] as String? ?? ''),
      answer = TextEditingController(text: data?['answer'] as String? ?? ''),
      explanation = TextEditingController(
        text: data?['explanation'] as String? ?? '',
      ),
      options = TextEditingController(
        text: (data?['options'] as List? ?? []).join('\n'),
      ) {
    if (type == 'match_pairs') {
      final entries = answer.text.split('|');
      for (var i = 0; i < 3 && i < entries.length; i++) {
        final pair = entries[i].split(':');
        if (pair.length == 2) {
          left[i].text = pair[0];
          right[i].text = pair[1];
        }
      }
    }
  }
  String type;
  final TextEditingController prompt, answer, explanation, options;
  final left = List.generate(3, (_) => TextEditingController());
  final right = List.generate(3, (_) => TextEditingController());
  Map<String, dynamic> toJson() => {
    'type': type,
    'prompt': prompt.text.trim(),
    'explanation': explanation.text.trim(),
    'options': type == 'fill_blank'
        ? <String>[]
        : type == 'match_pairs'
        ? [
            ...left.map((c) => c.text.trim()),
            ...right.map((c) => c.text.trim()).toList().reversed,
          ]
        : options.text
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
    'answer': type == 'match_pairs'
        ? List.generate(
            3,
            (i) => '${left[i].text.trim()}:${right[i].text.trim()}',
          ).join('|')
        : answer.text.trim(),
  };
  void dispose() {
    for (final c in [prompt, answer, explanation, options, ...left, ...right]) {
      c.dispose();
    }
  }
}

class LessonEditor extends StatefulWidget {
  const LessonEditor({
    super.key,
    required this.repository,
    this.entry,
    this.copy = false,
  });
  final ContentRepository repository;
  final ContentEntry? entry;
  final bool copy;
  @override
  State<LessonEditor> createState() => _LessonEditorState();
}

class _LessonEditorState extends State<LessonEditor> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      subtitle = TextEditingController(),
      order = TextEditingController(text: '100');
  final words = <WordFields>[];
  final questions = <QuestionFields>[];
  final retired = <Object>[];
  late String id;
  String code = 'en';
  String level = 'A1';
  bool busy = false, dirty = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final data = widget.entry?.data;
    id = widget.entry == null || widget.copy
        ? widget.repository.newId()
        : widget.entry!.id;
    title.text = data?['title'] as String? ?? '';
    if (widget.copy) title.text = '${title.text} (bản sao)';
    subtitle.text = data?['subtitle'] as String? ?? '';
    order.text = '${data?['order'] ?? 100}';
    code = data?['languageCode'] as String? ?? 'en';
    level = data?['level'] as String? ?? courseLevels[code]!.first;
    words.addAll(
      (data?['vocabulary'] as List? ?? [{}]).map((w) => WordFields(w as Map)),
    );
    questions.addAll(
      (data?['exercises'] as List? ?? [{}]).map(
        (q) => QuestionFields(q as Map),
      ),
    );
  }

  @override
  void dispose() {
    title.dispose();
    subtitle.dispose();
    order.dispose();
    for (final w in [...words, ...retired.whereType<WordFields>()]) {
      w.dispose();
    }
    for (final q in [...questions, ...retired.whereType<QuestionFields>()]) {
      q.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> get content => {
    'title': title.text.trim(),
    'subtitle': subtitle.text.trim(),
    'languageCode': code,
    'level': level,
    'icon': widget.entry?.data['icon'] ?? '📖',
    'order': int.tryParse(order.text) ?? -1,
    'vocabulary': words.map((w) => w.toJson()).toList(),
    'exercises': questions.map((q) => q.toJson()).toList(),
  };
  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.saveDraft(
        id,
        widget.copy ? 0 : widget.entry?.revision ?? 0,
        content,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = contentErrorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    int max = 400,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      enabled: !busy,
      maxLines: lines,
      maxLength: max,
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (s) =>
          s == null || s.trim().isEmpty ? 'Vui lòng nhập $label.' : null,
    ),
  );
  Future<void> preview() async {
    if (!form.currentState!.validate()) return;
    Map<String, dynamic> validated;
    try {
      validated = validateLessonContent(content);
    } catch (e) {
      setState(() => error = contentErrorMessage(e));
      return;
    }
    final lesson = decodeLesson(id, {...validated, 'status': 'draft'});
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(lesson.title),
        content: SizedBox(
          width: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lesson.subtitle),
              const SizedBox(height: 16),
              for (final w in lesson.words)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${w.word} · ${w.meaning}\n${w.phonetic}\n${w.example}\n${w.translation}',
                  ),
                ),
              const Divider(),
              for (final e in lesson.exercises)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '${e.prompt}\n${e.options.join(' · ')}\nĐáp án: ${e.answer}\n${e.explanation}',
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!canManage(context)) return deniedPage();
    return PopScope(
      canPop: !busy && !dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || busy) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bỏ thay đổi chưa lưu?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Soạn tiếp'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Bỏ thay đổi'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.copy ? 'Tạo bản sao mới' : 'Soạn bài học'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: form,
              onChanged: () {
                if (!dirty) setState(() => dirty = true);
              },
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Lưu bản nháp trước. Bạn có thể xem lại rồi xuất bản từ danh sách.',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: code,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Ngôn ngữ & cấp độ',
                    ),
                    items: learningLanguages
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.code,
                            child: Text('${l.flag} ${l.name} · ${l.level}'),
                          ),
                        )
                        .toList(),
                    onChanged: busy
                        ? null
                        : (s) => setState(() {
                            code = s!;
                            level = courseLevels[code]!.first;
                            dirty = true;
                          }),
                  ),
                  const SizedBox(height: 16),
                  levelPicker(
                    code,
                    level,
                    busy
                        ? null
                        : (v) => setState(() {
                            level = v;
                            dirty = true;
                          }),
                  ),
                  field(title, 'Tên bài học', max: 120),
                  field(subtitle, 'Mục tiêu bài học', max: 300),
                  TextFormField(
                    controller: order,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Thứ tự trong khóa (0–100000)',
                    ),
                    validator: (s) {
                      final value = int.tryParse(s ?? '');
                      return value == null || value < 0 || value > 100000
                          ? 'Nhập số từ 0 đến 100000.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Từ vựng',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  for (final w in words)
                    Padding(
                      key: ObjectKey(w),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Panel(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Từ ${words.indexOf(w) + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Bỏ từ',
                                  onPressed: busy || words.length == 1
                                      ? null
                                      : () => setState(() {
                                          words.remove(w);
                                          retired.add(w);
                                          dirty = true;
                                        }),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                              ],
                            ),
                            field(w.word, 'Từ mới', max: 100),
                            field(w.meaning, 'Nghĩa tiếng Việt', max: 150),
                            field(w.pronunciation, 'Phiên âm', max: 150),
                            field(w.example, 'Câu ví dụ', lines: 2),
                            field(w.translation, 'Dịch câu ví dụ', lines: 2),
                          ],
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: busy || words.length >= maxLessonWords
                        ? null
                        : () => setState(() {
                            words.add(WordFields());
                            dirty = true;
                          }),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm từ vựng'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bài tập',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  for (final q in questions)
                    Padding(
                      key: ObjectKey(q),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Panel(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Câu ${questions.indexOf(q) + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Bỏ câu hỏi',
                                  onPressed: busy || questions.length == 1
                                      ? null
                                      : () => setState(() {
                                          questions.remove(q);
                                          retired.add(q);
                                          dirty = true;
                                        }),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                              ],
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: q.type,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Dạng bài tập',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'multiple_choice',
                                  child: Text('Trắc nghiệm'),
                                ),
                                DropdownMenuItem(
                                  value: 'fill_blank',
                                  child: Text('Điền từ'),
                                ),
                                DropdownMenuItem(
                                  value: 'reorder_words',
                                  child: Text('Sắp xếp câu'),
                                ),
                                DropdownMenuItem(
                                  value: 'match_pairs',
                                  child: Text('Ghép 3 cặp'),
                                ),
                              ],
                              onChanged: busy
                                  ? null
                                  : (s) => setState(() {
                                      q.type = s!;
                                      dirty = true;
                                    }),
                            ),
                            const SizedBox(height: 16),
                            field(q.prompt, 'Đề bài', lines: 2, max: 500),
                            if (q.type == 'match_pairs') ...[
                              for (var i = 0; i < 3; i++) ...[
                                field(
                                  q.left[i],
                                  'Từ bên trái ${i + 1}',
                                  max: 150,
                                ),
                                field(
                                  q.right[i],
                                  'Nghĩa tương ứng ${i + 1}',
                                  max: 150,
                                ),
                              ],
                            ] else ...[
                              if (q.type != 'fill_blank')
                                field(
                                  q.options,
                                  q.type == 'reorder_words'
                                      ? 'Các từ rời (mỗi dòng 1 từ, không trùng)'
                                      : 'Lựa chọn (mỗi dòng 1 lựa chọn)',
                                  lines: 4,
                                  max: 1000,
                                ),
                              field(
                                q.answer,
                                q.type == 'reorder_words'
                                    ? 'Câu đúng (dùng đủ từ, cách nhau 1 dấu cách)'
                                    : 'Đáp án đúng',
                                lines: 2,
                                max: 1000,
                              ),
                            ],
                            field(
                              q.explanation,
                              'Giải thích đáp án',
                              lines: 2,
                              max: 700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: busy || questions.length >= maxLessonQuestions
                        ? null
                        : () => setState(() {
                            questions.add(QuestionFields());
                            dirty = true;
                          }),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm câu hỏi'),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 22),
                  OutlinedButton(
                    onPressed: busy ? null : preview,
                    child: const Text('Xem trước nội dung'),
                  ),
                  const SizedBox(height: 12),
                  Primary(
                    busy ? 'Đang lưu…' : 'Lưu bản nháp',
                    onPressed: busy ? null : save,
                    icon: Icons.save_outlined,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget levelPicker(
  String code,
  String level,
  ValueChanged<String>? onChanged,
) => DropdownButtonFormField<String>(
  key: ValueKey('$code:$level'),
  initialValue: level,
  isExpanded: true,
  decoration: const InputDecoration(labelText: 'Cấp độ bài học'),
  items: courseLevels[code]!
      .map((l) => DropdownMenuItem(value: l, child: Text(levelLabel(l))))
      .toList(),
  onChanged: onChanged == null ? null : (v) => onChanged(v!),
);
