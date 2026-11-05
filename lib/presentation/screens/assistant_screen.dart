import 'package:flutter/material.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/app_typography.dart';
import '../../domain/models/chat_and_memory.dart';
import '../../domain/services/ai_assistant_service.dart';
import '../../domain/services/assistant_tool_engine.dart';
import 'memory_screen.dart';

class AssistantScreen extends StatefulWidget {
  final AIAssistantService assistantService;
  final AssistantToolEngine toolEngine;
  final bool isBangla;
  final Function(String dayKey)? onNavigateToDayPage;

  const AssistantScreen({
    super.key,
    required this.assistantService,
    required this.toolEngine,
    this.isBangla = false,
    this.onNavigateToDayPage,
  });

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _quickPills = [
    'When did I last study networking?',
    'Add task: Complete Flutter assignment p1',
    'Start 25m focus with rain sound',
    'Set alarm at 06:30 for Wake Quest',
    'Remember that: Focus blocks work best at morning',
  ];

  @override
  void initState() {
    super.initState();
    widget.assistantService.generateDailyProactiveSuggestions();

    // Initial greeting
    _messages.add(ChatMessage(
      id: 'msg_greet',
      sender: MessageSender.assistant,
      content: widget.isBangla
          ? 'স্বাগতম! আমি আপনার **DayBook Assistant**। কোনো প্রশ্ন থাকলে লিখুন অথবা অতীতে কী হয়েছিল তা জানতে **"Ask Your Past"** ব্যবহার করুন।'
          : 'Welcome to **DayBook Assistant**. How can I help you today? Ask questions, create tasks, or query your past journal entries with **"Ask Your Past"**.',
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? presetText]) async {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    final userMsg = ChatMessage(
      id: 'msg_u_${DateTime.now().microsecondsSinceEpoch}',
      sender: MessageSender.user,
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    // Process through Assistant Service
    final reply = await widget.assistantService.processUserMessage(text, isBangla: widget.isBangla);

    if (mounted) {
      setState(() {
        _messages.add(reply);
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _confirmToolCall(String recordId) async {
    final record = await widget.toolEngine.confirmAndExecute(recordId);
    setState(() {
      _messages.add(ChatMessage(
        id: 'msg_conf_${DateTime.now().microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: "Action confirmed & executed: **${record.resultMessage ?? record.toolName}**",
        toolRecordId: record.id,
        undoDescription: record.undoDescription,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _rejectToolCall(String recordId) {
    final record = widget.toolEngine.rejectToolCall(recordId);
    setState(() {
      _messages.add(ChatMessage(
        id: 'msg_rej_${DateTime.now().microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: "Action rejected: ${record.resultMessage}",
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  Future<void> _undoAction(String recordId) async {
    final success = await widget.toolEngine.undoToolCall(recordId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBangla ? 'অ্যাকশন সফলভাবে আনডু করা হয়েছে' : 'Action successfully reversed (Undo)',
            style: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.accentLime,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = widget.assistantService.activeSuggestions;
    final pendingCalls = widget.toolEngine.pendingConfirmations;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.assistantService.isAiEnabled ? AppColors.accentLime : AppColors.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 16,
                color: widget.assistantService.isAiEnabled ? AppColors.bg : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isBangla ? 'অ্যাসিস্ট্যান্ট' : 'DayBook Assistant',
                  style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
                ),
                Text(
                  widget.assistantService.isAiEnabled
                      ? (widget.isBangla ? 'সক্রিয় • অফলাইন প্রস্তুত' : 'Active • 100% Offline Ready')
                      : (widget.isBangla ? 'নিষ্ক্রিয় (ম্যানুয়াল)' : 'Turned Off (Manual Mode)'),
                  style: AppTypography.caption.copyWith(
                    color: widget.assistantService.isAiEnabled ? AppColors.accentLime : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Nav to Memory Screen
          IconButton(
            icon: const Icon(Icons.psychology_outlined, color: AppColors.accentLime),
            tooltip: widget.isBangla ? 'স্মৃতি ভল্ট' : 'Memory Vault',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => MemoryScreen(
                    assistantService: widget.assistantService,
                    isBangla: widget.isBangla,
                  ),
                ),
              );
            },
          ),
          // AI Master Switch
          Switch(
            value: widget.assistantService.isAiEnabled,
            activeColor: AppColors.accentLime,
            activeTrackColor: AppColors.surface2,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.surface2,
            onChanged: (val) {
              setState(() {
                widget.assistantService.toggleAiMasterSwitch(val);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // AI Disabled Warning Banner
          if (!widget.assistantService.isAiEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface2,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isBangla
                          ? 'এআই বন্ধ রয়েছে। অ্যাপের সব ফিচার অফলাইনে সরাসরি ব্যবহারযোগ্য।'
                          : 'AI is off. All manual tools, planning, and alarms remain fully functional.',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

          // Proactive Suggestions Bar (Max 3 per day)
          if (suggestions.isNotEmpty && widget.assistantService.isAiEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.accentLime),
                      const SizedBox(width: 6),
                      Text(
                        widget.isBangla ? 'পরামর্শ (সর্বোচ্চ ৩টি/দিন)' : 'PROACTIVE SUGGESTIONS (MAX 3/DAY)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentLime,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: suggestions.map((sug) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sug.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _handleSendMessage(sug.message),
                                child: Text(
                                  widget.isBangla ? 'শুরু করুন' : 'Run',
                                  style: const TextStyle(
                                    color: AppColors.accentLime,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    widget.assistantService.dismissSuggestion(sug.id);
                                  });
                                },
                                child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

          // Pending Tool Confirmation Cards
          if (pendingCalls.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.surface2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: pendingCalls.map((call) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      border: Border.all(color: AppColors.accentLime, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, size: 16, color: AppColors.accentLime),
                            const SizedBox(width: 6),
                            Text(
                              widget.isBangla ? 'অনুমোদন প্রয়োজন (টুল কল)' : 'CONFIRMATION REQUIRED',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.accentLime,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Tool: ${call.toolName} • Arguments: ${call.arguments}",
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.errorRed,
                                side: const BorderSide(color: AppColors.errorRed),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => _rejectToolCall(call.id),
                              child: Text(widget.isBangla ? 'প্রত্যাখ্যান' : 'Reject'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentLime,
                                foregroundColor: AppColors.bg,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => _confirmToolCall(call.id),
                              child: Text(
                                widget.isBangla ? 'অনুমোদন করুন' : 'Confirm',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // Quick Pills Carousel
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPills.length,
              itemBuilder: (ctx, i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: AppColors.surface2,
                    side: const BorderSide(color: AppColors.border),
                    label: Text(
                      _quickPills[i],
                      style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                    ),
                    onPressed: () => _handleSendMessage(_quickPills[i]),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Message Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final isUser = msg.isUser;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.surface2 : AppColors.surface1,
                      border: Border.all(
                        color: isUser ? AppColors.border : AppColors.border,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rich Text with Lime Bold formatting
                        _buildRichText(msg.content),

                        // Tap-through Day Page Button if Ask Your Past matched a date
                        if (msg.targetDayKey != null) ...[
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              if (widget.onNavigateToDayPage != null) {
                                widget.onNavigateToDayPage!(msg.targetDayKey!);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Jump to Day Page: ${msg.targetDayKey}")),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.accentLime),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: AppColors.accentLime),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.isBangla ? "দিনটি দেখুন: ${msg.targetDayKey}" : "View Day Page: ${msg.targetDayKey}",
                                    style: const TextStyle(
                                      color: AppColors.accentLime,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.accentLime),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Undo Action Chip
                        if (msg.undoDescription != null && msg.toolRecordId != null) ...[
                          const SizedBox(height: 8),
                          ActionChip(
                            avatar: const Icon(Icons.undo, size: 14, color: AppColors.bg),
                            backgroundColor: AppColors.accentLime,
                            label: Text(
                              widget.isBangla ? 'আনডু (Undo)' : 'Undo Action',
                              style: const TextStyle(
                                color: AppColors.bg,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            onPressed: () => _undoAction(msg.toolRecordId!),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentLime),
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surface1,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: widget.isBangla ? 'প্রশ্ন বা কাজের নির্দেশ লিখুন...' : 'Ask question, create task, or query past...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surface2,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.accentLime),
                      ),
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.accentLime,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: AppColors.bg, size: 20),
                    onPressed: _handleSendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Part 1 Rich text rule: Any **bold** word renders as Lime Bold
  Widget _buildRichText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.accentLime,
          fontWeight: FontWeight.bold,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
