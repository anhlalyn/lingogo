import 'dart:async';
import 'package:lingogo/content_repository.dart';
import 'package:lingogo/data.dart';

class FakeContent extends ContentRepository {
  final entries = <String, Map<String, dynamic>>{};
  final _changes = StreamController<void>.broadcast();
  int sequence = 0;
  String? generatedTopic;
  String? generatedProvider;
  Object? failure;
  void emit() => _changes.add(null);
  @override
  String newId() => 'l_test_0000_${sequence++}';
  @override
  Stream<List<ContentEntry>> watchAll() => Stream.multi((controller) {
    void send() => controller.add(
      entries.entries
          .map((e) => ContentEntry(e.key, Map<String, dynamic>.from(e.value)))
          .toList(),
    );
    send();
    final subscription = _changes.stream.listen((_) => send());
    controller.onCancel = subscription.cancel;
  });
  @override
  Stream<List<Lesson>> watchPublished() => watchAll().map(
    (list) => list
        .where((e) => e.status == 'published')
        .map((e) => e.lesson)
        .toList(),
  );
  @override
  Future<void> saveDraft(
    String id,
    int revision,
    Map<String, dynamic> content,
  ) async {
    if (failure != null) throw failure!;
    entries[id] = {
      ...content,
      'status': 'draft',
      'revision': revision + 1,
      'version': 1,
      'source': 'manual',
    };
    emit();
  }

  @override
  Future<void> publish(ContentEntry entry) async {
    entries[entry.id]!['status'] = 'published';
    entries[entry.id]!['revision'] = entry.revision + 1;
    emit();
  }

  @override
  Future<void> archive(ContentEntry entry) async {
    entries[entry.id]!['status'] = 'archived';
    emit();
  }

  @override
  Future<String> generate({
    required String languageCode,
    required String level,
    required String topic,
    required String requestId,
    String provider = 'gemini',
  }) async {
    generatedTopic = topic;
    generatedProvider = provider;
    final id = newId();
    entries[id] = {
      ...lessonContent(seedLessons().first),
      'languageCode': languageCode,
      'level': level,
      'title': 'Bài AI tạo',
      'source': 'ai',
      'status': 'draft',
      'revision': 1,
    };
    emit();
    return id;
  }

  Future<void> close() => _changes.close();
  String? chatProvider, chatMessage;
  @override
  Future<String> chat({
    required String languageCode,
    String? level,
    required String situation,
    required String message,
    required List<Map<String, String>> history,
    required String requestId,
    String provider = 'gemini',
  }) async {
    if (failure != null) throw failure!;
    chatProvider = provider;
    chatMessage = message;
    return 'Hello! Bạn có thể nói: My name is Anna.';
  }
}
