import '../models/chat_and_memory.dart';
import '../../core/enums/core_enums.dart';

class MemoryVaultService {
  final List<PersonalMemory> _memories = [];

  List<PersonalMemory> get memories => List.unmodifiable(_memories);

  void loadMemories(List<PersonalMemory> items) {
    _memories.clear();
    _memories.addAll(items);
  }

  PersonalMemory addMemory({
    required String key,
    required String value,
    MemoryKind kind = MemoryKind.fact,
    bool isPinned = false,
  }) {
    final newMemory = PersonalMemory(
      id: 'mem_${DateTime.now().microsecondsSinceEpoch}',
      key: key.trim(),
      value: value.trim(),
      kind: kind,
      isPinned: isPinned,
      createdAt: DateTime.now(),
    );
    _memories.add(newMemory);
    return newMemory;
  }

  bool togglePin(String memoryId) {
    final index = _memories.indexWhere((m) => m.id == memoryId);
    if (index == -1) return false;
    final current = _memories[index];
    _memories[index] = current.copyWith(isPinned: !current.isPinned);
    return true;
  }

  bool deleteMemory(String memoryId) {
    final before = _memories.length;
    _memories.removeWhere((m) => m.id == memoryId);
    return _memories.length < before;
  }

  /// Searches and ranks memories: pinned items first, then matches in key or value,
  /// sorted by creation date descending.
  List<PersonalMemory> searchMemories([String? query]) {
    final list = (query == null || query.trim().isEmpty)
        ? List<PersonalMemory>.from(_memories)
        : _memories.where((m) {
            final q = query.toLowerCase();
            return m.key.toLowerCase().contains(q) ||
                m.value.toLowerCase().contains(q);
          }).toList();

    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  /// Extracts potential memory key-value pairs from conversational text.
  List<Map<String, String>> extractMemoryCandidates(String text) {
    final candidates = <Map<String, String>>[];
    final lower = text.toLowerCase();

    final wakePatterns = [
      RegExp(r'(?:i\s+(?:wake\s*up|sleep|get\s*up)\s+at\s+)(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)'),
      RegExp(r'(?:আমি\s+(?:ঘুম\s*থেকে\s*উঠি|ঘুমাই)\s+)(\d{1,2}(?::\d{2})?\s*টায়)'),
    ];

    for (final pattern in wakePatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null && match.groupCount >= 1) {
        candidates.add({
          'key': 'daily_schedule',
          'value': match.group(0) ?? text,
        });
      }
    }

    if (lower.contains('prefer') || lower.contains('like') || lower.contains('পছন্দ')) {
      candidates.add({
        'key': 'user_preference',
        'value': text.trim(),
      });
    }

    return candidates;
  }
}

