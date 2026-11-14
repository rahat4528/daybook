// Link Saver Screen for DayBook (Page 02)
// Searchable reading list, tags, favorites, duplicate detection, and native share ingestion.

import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/app_typography.dart';
import '../../domain/models/saved_link_item.dart';
import '../../domain/services/link_saver_service.dart';

class LinksScreen extends StatefulWidget {
  final LinkSaverService linkService;
  final bool isBangla;

  const LinksScreen({
    super.key,
    required this.linkService,
    this.isBangla = false,
  });

  @override
  State<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends State<LinksScreen> {
  String _searchQuery = '';
  String? _selectedTag;
  bool _showFavoritesOnly = false;

  void _openSaveLinkDialog({String? initialUrl}) {
    final urlCtrl = TextEditingController(text: initialUrl ?? '');
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final tagsCtrl = TextEditingController(text: 'research');
    String? duplicateWarning;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isBangla ? 'লিঙ্ক সংরক্ষণ করুন (শেয়ার শিট)' : 'SAVE LINK TO DAYBOOK',
                    style: const TextStyle(
                      color: AppColors.accentLime,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Icon(Icons.share, color: AppColors.accentLime, size: 18),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Web URL (Shared Intent)',
                  hintText: 'https://...',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: const OutlineInputBorder(),
                  errorText: duplicateWarning,
                ),
                onChanged: (val) {
                  final dup = widget.linkService.findDuplicate(val);
                  setModalState(() {
                    if (dup != null) {
                      duplicateWarning = 'Already saved: "${dup.title}"';
                    } else {
                      duplicateWarning = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Article / Video Title (Optional)',
                  hintText: 'Auto-extracted from Open Graph',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes / Summary',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  hintText: 'ai, mobile, tech',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentLime,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                  ),
                  onPressed: () {
                    final raw = urlCtrl.text.trim();
                    if (raw.isEmpty) return;

                    final tagList = tagsCtrl.text
                        .split(',')
                        .map((t) => t.trim().toLowerCase())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    widget.linkService.saveLink(
                      rawUrl: raw,
                      title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      tags: tagList,
                    );

                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: Text(
                    widget.isBangla ? 'সংরক্ষণ সম্পন্ন করুন' : 'SAVE TO READING LIST',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var links = widget.linkService.search(
      query: _searchQuery,
      tagFilter: _selectedTag,
    );

    if (_showFavoritesOnly) {
      links = links.where((l) => l.isFavorite).toList();
    }

    final tags = widget.linkService.allUniqueTags;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          widget.isBangla ? 'লিঙ্ক সেভার ও বুকমার্ক' : 'LINK SAVER',
          style: AppTypography.screenTitle,
        ),
        backgroundColor: AppColors.surface1,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.star : Icons.star_border,
              color: _showFavoritesOnly ? AppColors.accentLime : AppColors.textSecondary,
            ),
            tooltip: 'Filter Favorites',
            onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            color: AppColors.surface1,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: widget.isBangla ? 'সংরক্ষিত লিঙ্ক খুঁজুন...' : 'Search saved links or domains...',
                prefixIcon: const Icon(Icons.search, color: AppColors.accentLime),
                filled: true,
                fillColor: AppColors.surface2,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Tag Carousel Filter
          if (tags.isNotEmpty)
            Container(
              height: 44,
              color: AppColors.surface1,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 6),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedTag == null,
                      selectedColor: AppColors.accentLime,
                      backgroundColor: AppColors.surface2,
                      labelStyle: TextStyle(
                        color: _selectedTag == null ? Colors.black : AppColors.textPrimary,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedTag = null),
                    ),
                  ),
                  ...tags.map((tag) {
                    final isSel = _selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6, bottom: 6),
                      child: ChoiceChip(
                        label: Text('#$tag'),
                        selected: isSel,
                        selectedColor: AppColors.accentLime,
                        backgroundColor: AppColors.surface2,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.black : AppColors.textPrimary,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _selectedTag = isSel ? null : tag),
                      ),
                    );
                  }),
                ],
              ),
            ),

          // Saved Links Stream
          Expanded(
            child: links.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark_border, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          widget.isBangla ? 'কোন লিঙ্ক পাওয়া যায়নি' : 'No saved links match criteria.',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: links.length,
                    itemBuilder: (ctx, idx) {
                      final link = links[idx];
                      return _buildLinkCard(link);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentLime,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_link),
        label: Text(
          widget.isBangla ? 'লিঙ্ক যোগ করুন' : 'Capture Link',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _openSaveLinkDialog(),
      ),
    );
  }

  Widget _buildLinkCard(SavedLinkItem link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  link.domain,
                  style: const TextStyle(
                    color: AppColors.accentLime,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      link.isFavorite ? Icons.star : Icons.star_border,
                      color: link.isFavorite ? AppColors.accentLime : AppColors.textSecondary,
                    ),
                    onPressed: () {
                      widget.linkService.toggleFavorite(link.id);
                      setState(() {});
                    },
                  ),
                  IconButton(
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.archive_outlined, color: AppColors.textSecondary),
                    tooltip: 'Archive',
                    onPressed: () {
                      widget.linkService.toggleArchive(link.id);
                      setState(() {});
                    },
                  ),
                  IconButton(
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
                    onPressed: () {
                      widget.linkService.deleteLink(link.id);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            link.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          if (link.description != null) ...[
            const SizedBox(height: 6),
            Text(
              link.description!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                children: link.tags
                    .map((t) => Text('#$t', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)))
                    .toList(),
              ),
              Text(
                '${link.createdAt.day}/${link.createdAt.month}/${link.createdAt.year}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
