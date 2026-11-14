// Link Saver Service for DayBook (Page 02)
// Ingestion, Open Graph metadata extraction, tag organization, and deduplication.

import '../models/saved_link_item.dart';
import '../../data/repositories/entries_repository.dart';

class LinkSaverService {
  final EntriesRepository? entriesRepo;
  final List<SavedLinkItem> _links = [];

  LinkSaverService({this.entriesRepo}) {
    _seedDefaultLinks();
  }

  void _seedDefaultLinks() {
    _links.addAll([
      SavedLinkItem(
        id: 'link_seed_1',
        rawUrl: 'https://flutter.dev/docs',
        canonicalUrl: 'https://flutter.dev/docs',
        title: 'Flutter Documentation — Multi-Platform UI Toolkit',
        description: 'Build fast, beautiful native apps on iOS, Android, Desktop, and Web from a single codebase.',
        domain: 'flutter.dev',
        tags: ['flutter', 'mobile', 'dev'],
        isFavorite: true,
      ),
      SavedLinkItem(
        id: 'link_seed_2',
        rawUrl: 'https://arxiv.org/abs/1706.03762',
        canonicalUrl: 'https://arxiv.org/abs/1706.03762',
        title: 'Attention Is All You Need — Transformer Architecture Paper',
        description: 'The seminal 2017 paper by Vaswani et al. introducing the self-attention transformer architecture.',
        domain: 'arxiv.org',
        tags: ['ai', 'research', 'transformers'],
      ),
    ]);
  }

  List<SavedLinkItem> get allLinks => List.unmodifiable(_links);

  List<SavedLinkItem> get unarchivedLinks =>
      _links.where((l) => !l.isArchived).toList();

  List<SavedLinkItem> get favorites =>
      _links.where((l) => l.isFavorite && !l.isArchived).toList();

  List<String> get allUniqueTags {
    final tags = <String>{};
    for (final l in _links) {
      tags.addAll(l.tags);
    }
    return tags.toList()..sort();
  }

  SavedLinkItem? findDuplicate(String url) {
    final canonical = SavedLinkItem.normalizeCanonicalUrl(url);
    try {
      return _links.firstWhere((l) => l.canonicalUrl == canonical);
    } catch (_) {
      return null;
    }
  }

  SavedLinkItem saveLink({
    required String rawUrl,
    String? title,
    String? description,
    String? imageUrl,
    List<String> tags = const [],
  }) {
    final canonical = SavedLinkItem.normalizeCanonicalUrl(rawUrl);
    final domain = SavedLinkItem.extractDomain(rawUrl);
    final id = 'link_${DateTime.now().millisecondsSinceEpoch}';

    // Auto-generate title if none provided
    final resolvedTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : 'Saved Link from $domain';

    final newLink = SavedLinkItem(
      id: id,
      rawUrl: rawUrl,
      canonicalUrl: canonical,
      title: resolvedTitle,
      description: description,
      imageUrl: imageUrl,
      domain: domain,
      tags: tags,
    );

    _links.insert(0, newLink);

    entriesRepo?.createManualEntry(
      type: 'link_saved',
      payload: {
        'id': id,
        'title': resolvedTitle,
        'url': canonical,
        'domain': domain,
      },
      source: 'link_saver',
    );

    return newLink;
  }

  void toggleFavorite(String id) {
    final index = _links.indexWhere((l) => l.id == id);
    if (index != -1) {
      _links[index] = _links[index].copyWith(isFavorite: !_links[index].isFavorite);
    }
  }

  void toggleArchive(String id) {
    final index = _links.indexWhere((l) => l.id == id);
    if (index != -1) {
      _links[index] = _links[index].copyWith(isArchived: !_links[index].isArchived);
    }
  }

  void deleteLink(String id) {
    _links.removeWhere((l) => l.id == id);
  }

  List<SavedLinkItem> search({String? query, String? tagFilter}) {
    return _links.where((l) {
      if (l.isArchived) return false;
      if (tagFilter != null && tagFilter.isNotEmpty) {
        if (!l.tags.contains(tagFilter)) return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchTitle = l.title.toLowerCase().contains(q);
        final matchDesc = l.description?.toLowerCase().contains(q) ?? false;
        final matchDomain = l.domain.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchDomain) return false;
      }
      return true;
    }).toList();
  }
}
