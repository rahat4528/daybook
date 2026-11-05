import 'package:flutter/material.dart';
import '../../core/enums/core_enums.dart';
import '../../domain/models/chat_and_memory.dart';
import '../../domain/services/memory_vault_service.dart';

class MemoryScreen extends StatefulWidget {
  final MemoryVaultService vaultService;
  final VoidCallback onDataChanged;

  const MemoryScreen({
    super.key,
    required this.vaultService,
    required this.onDataChanged,
  });

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  void _showAddMemoryDialog() {
    final keyController = TextEditingController();
    final valController = TextEditingController();
    MemoryKind kind = MemoryKind.fact;
    bool isPinned = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add to Memory Vault'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(
                      labelText: 'Memory Label / Key',
                      hintText: 'e.g., Preferred Work Routine',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Value / Notes',
                      hintText: 'e.g., Focus blocks work best between 9am-12pm',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Kind: '),
                      DropdownButton<MemoryKind>(
                        value: kind,
                        items: MemoryKind.values.map((k) {
                          return DropdownMenuItem(value: k, child: Text(k.label));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => kind = val);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isPinned,
                        onChanged: (val) {
                          if (val != null) setDialogState(() => isPinned = val);
                        },
                      ),
                      const Text('Pin to Assistant Context'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (keyController.text.trim().isNotEmpty && valController.text.trim().isNotEmpty) {
                      widget.vaultService.addMemory(
                        key: keyController.text.trim(),
                        value: valController.text.trim(),
                        kind: kind,
                        isPinned: isPinned,
                      );
                      widget.onDataChanged();
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Save Memory'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final memories = widget.vaultService.searchMemories(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Memory Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMemoryDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search memories, facts, preferences...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: memories.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.psychology_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No memories recorded yet.'),
                        Text('Daybook remembers your habits and preferences locally.',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: memories.length,
                    itemBuilder: (ctx, i) {
                      final mem = memories[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: mem.isPinned ? const Color(0xFFF59E0B) : Colors.transparent,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              mem.kind == MemoryKind.preference
                                  ? Icons.favorite_border
                                  : (mem.kind == MemoryKind.episodicSummary
                                      ? Icons.history_edu
                                      : Icons.lightbulb_outline),
                              color: mem.isPinned ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        mem.key,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          mem.kind.label,
                                          style: const TextStyle(fontSize: 9, color: Color(0xFF6366F1)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    mem.value,
                                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black80),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                mem.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                color: mem.isPinned ? const Color(0xFFF59E0B) : Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => widget.vaultService.togglePin(mem.id));
                                widget.onDataChanged();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                              onPressed: () {
                                setState(() => widget.vaultService.deleteMemory(mem.id));
                                widget.onDataChanged();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemoryDialog,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
