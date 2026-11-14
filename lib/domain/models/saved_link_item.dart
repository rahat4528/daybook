// Saved Link Domain Model for DayBook Link Saver (Page 02)
// Captures shared URLs, Open Graph metadata, tags, and reading status.

class SavedLinkItem {
  final String id;
  final String rawUrl;
  final String canonicalUrl;
  final String title;
  final String? description;
  final String? imageUrl;
  final String domain;
  final List<String> tags;
  final bool isFavorite;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedLinkItem({
    required this.id,
    required this.rawUrl,
    required this.canonicalUrl,
    required this.title,
    this.description,
    this.imageUrl,
    required this.domain,
    this.tags = const [],
    this.isFavorite = false,
    this.isArchived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static String normalizeCanonicalUrl(String url) {
    try {
      final uri = Uri.parse(url.trim());
      // Strip common analytics tracking queries (utm_*, ref, fbclid)
      final cleanParams = Map<String, String>.from(uri.queryParameters)
        ..removeWhere((k, _) =>
            k.startsWith('utm_') ||
            k == 'ref' ||
            k == 'fbclid' ||
            k == 'gclid' ||
            k == 'si');

      final cleanPath = uri.path.replaceAll(RegExp(r'/+$'), '');
      final cleanUri = Uri(
        scheme: uri.scheme.toLowerCase(),
        host: uri.host.toLowerCase(),
        path: cleanPath,
        queryParameters: cleanParams.isEmpty ? null : cleanParams,
      );
      return cleanUri.toString();
    } catch (_) {
      return url.trim().toLowerCase();
    }
  }

  static String extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      return host.startsWith('www.') ? host.substring(4) : host;
    } catch (_) {
      return 'web';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rawUrl': rawUrl,
      'canonicalUrl': canonicalUrl,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'domain': domain,
      'tags': tags,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SavedLinkItem.fromJson(Map<String, dynamic> json) {
    return SavedLinkItem(
      id: json['id'] as String,
      rawUrl: json['rawUrl'] as String,
      canonicalUrl: json['canonicalUrl'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      domain: json['domain'] as String? ?? 'web',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  SavedLinkItem copyWith({
    String? id,
    String? rawUrl,
    String? canonicalUrl,
    String? title,
    String? description,
    String? imageUrl,
    String? domain,
    List<String>? tags,
    bool? isFavorite,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return SavedLinkItem(
      id: id ?? this.id,
      rawUrl: rawUrl ?? this.rawUrl,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      domain: domain ?? this.domain,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
