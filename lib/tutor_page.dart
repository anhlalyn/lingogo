import 'package:flutter/material.dart';
import 'app.dart';
import 'data.dart';
import 'content_repository.dart';

class TutorPage extends StatefulWidget {
  const TutorPage({super.key, required this.store});
  final LearningStore store;
  @override
  State<TutorPage> createState() => _TutorPageState();
}

class _TutorPageState extends State<TutorPage>
    with AutomaticKeepAliveClientMixin {
  final input = TextEditingController();
  final scroll = ScrollController();
  final messages = <Map<String, String>>[];
  String provider = 'gemini', situation = 'introduction';
  String? error, requestId;
  bool busy = false;
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final repository = AuthScope.contentOf(context);
    final message = input.text.trim();
    if (busy || message.isEmpty || repository == null) return;
    if (message.length > 1200) {
      setState(() => error = 'Tin nhắn tối đa 1200 ký tự.');
      return;
    }
    requestId ??= repository.newId();
    final history = messages
        .skip(messages.length > 8 ? messages.length - 8 : 0)
        .map((m) => Map<String, String>.from(m))
        .toList();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final reply = await repository.chat(
        languageCode: widget.store.languageCode,
        level: widget.store.currentLevel,
        situation: situation,
        message: message,
        history: history,
        requestId: requestId!,
        provider: provider,
      );
      if (!mounted) return;
      setState(() {
        messages.addAll([
          {'role': 'user', 'content': message},
          {'role': 'assistant', 'content': reply},
        ]);
        input.clear();
        requestId = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) {
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) setState(() => error = contentErrorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> clear() async {
    if (messages.isEmpty) {
      setState(() {
        requestId = null;
        error = null;
        input.clear();
      });
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bắt đầu cuộc trò chuyện mới?'),
        content: const Text('Lịch sử trên màn hình này sẽ được xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bắt đầu mới'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        messages.clear();
        requestId = null;
        error = null;
        input.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final available = AuthScope.contentOf(context) != null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Gia sư ngôn ngữ AI',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Cuộc trò chuyện mới',
                onPressed: busy ? null : clear,
                icon: const Icon(Icons.add_comment_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
            children: [
              const SizedBox(height: 8),
              Text(
                '${widget.store.language.name} · ${widget.store.currentLevel} · Luyện tập theo nhịp của bạn',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Chip(label: Text('Gemini')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: situation,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tình huống luyện tập',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'introduction',
                    child: Text('Giới thiệu bản thân'),
                  ),
                  DropdownMenuItem(value: 'travel', child: Text('Du lịch')),
                  DropdownMenuItem(value: 'work', child: Text('Công việc')),
                ],
                onChanged: busy || messages.isNotEmpty
                    ? null
                    : (s) => setState(() {
                        situation = s!;
                        requestId = null;
                      }),
              ),
              const SizedBox(height: 16),
              if (messages.isEmpty)
                Panel(
                  color: const Color(0xFFEDE9FF),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chào bạn! Mình cùng luyện tập nhé ✨',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hãy viết một câu. Gia sư sẽ giúp bạn sửa câu và giải thích bằng tiếng Việt.',
                      ),
                      const SizedBox(height: 12),
                      for (final word in widget.store.words.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            word.example,
                            style: const TextStyle(color: purple),
                          ),
                        ),
                    ],
                  ),
                ),
              for (final message in messages)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Align(
                    alignment: message['role'] == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Panel(
                      color: message['role'] == 'user'
                          ? const Color(0xFFEDE9FF)
                          : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['role'] == 'user' ? 'Bạn' : 'Gemini',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: purple,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(message['content']!),
                        ],
                      ),
                    ),
                  ),
                ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Gia sư đang trả lời…',
                          style: TextStyle(color: muted),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!available)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Gia sư hiện chưa khả dụng. Vui lòng thử lại sau.',
                  ),
                ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: const TextStyle(color: Color(0xFFB3261E)),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('tutor-input'),
                      controller: input,
                      enabled: !busy && available,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 1200,
                      decoration: const InputDecoration(
                        hintText: 'Viết câu bạn muốn luyện tập…',
                        counterText: '',
                      ),
                      onChanged: (_) {
                        requestId = null;
                      },
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: busy || !available ? null : send,
                    tooltip: 'Gửi tin nhắn',
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'AI có thể sai · Dùng hạn mức miễn phí của Gemini · Hết hạn mức hãy thử lại sau',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
