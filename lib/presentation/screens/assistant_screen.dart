import 'package:flutter/material.dart';
import '../../domain/models/chat_and_memory.dart';
import '../../domain/services/task_service.dart';

class AssistantScreen extends StatefulWidget {
  final List<ChatMessage> messages;
  final TaskService taskService;
  final Function(ChatMessage) onSendMessage;

  const AssistantScreen({
    super.key,
    required this.messages,
    required this.taskService,
    required this.onSendMessage,
  });

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isListening = false;

  final List<String> _quickPrompts = [
    'আজকের পরিকল্পনা কি? (What is today\'s plan?)',
    'Add task: Prepare project submission tomorrow at 5pm',
    'সকালের অ্যালার্ম সেট করো (Set morning alarm for 6:30 AM)',
    'Show my top priority focus tasks',
    'আজকে সারাদিন কেমন গেলো? (Evening review)',
  ];

  void _handleSend([String? presetText]) {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty) return;

    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      sender: MessageSender.user,
      content: text,
      timestamp: DateTime.now(),
    );
    widget.onSendMessage(userMsg);
    _textController.clear();

    // Deterministic Assistant Response & Tool Calling simulation
    Future.delayed(const Duration(milliseconds: 600), () {
      final reply = _generateAssistantReply(text);
      widget.onSendMessage(reply);
      _scrollToBottom();
    });

    _scrollToBottom();
  }

  ChatMessage _generateAssistantReply(String input) {
    final lower = input.toLowerCase();
    final now = DateTime.now();

    // 1. Task Creation Tool
    if (lower.contains('add task') || lower.contains('টাস্ক যোগ') || lower.contains('create task')) {
      final title = input
          .replaceAll(RegExp(r'(?i)add task:?|create task:?|টাস্ক যোগ করো:?'), '')
          .trim();
      final taskTitle = title.isEmpty ? 'Follow up on important action' : title;

      widget.taskService.addTask(
        title: taskTitle,
        estimatedMinutes: 30,
        dueAt: now.add(const Duration(hours: 4)),
      );

      return ChatMessage(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: 'I have added "$taskTitle" to your daily task list.',
        timestamp: DateTime.now(),
        toolInvocation: AssistantToolInvocation(
          toolName: 'create_task',
          parameters: {'title': taskTitle, 'estimatedMinutes': 30},
          resultSummary: 'Task added successfully to local database',
          isExecuted: true,
        ),
      );
    }

    // 2. Schedule / Plan Day Tool
    if (lower.contains('plan') || lower.contains('পরিকল্পনা') || lower.contains('schedule')) {
      final todayTasks = widget.taskService.getTodayTasks();
      return ChatMessage(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: 'You have ${todayTasks.length} active tasks for today. I have arranged them by urgency so you can knock out top priorities first!',
        timestamp: DateTime.now(),
        toolInvocation: const AssistantToolInvocation(
          toolName: 'plan_day',
          parameters: {'strategy': 'eisenhower_gap_fitting'},
          resultSummary: 'Daily schedule generated and synchronized',
          isExecuted: true,
        ),
      );
    }

    // 3. Alarm Tool
    if (lower.contains('alarm') || lower.contains('অ্যালার্ম') || lower.contains('wake')) {
      return ChatMessage(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        content: 'Alarm registered! Don\'t forget, your Math and QR challenges will be active to guarantee you wake up on time.',
        timestamp: DateTime.now(),
        toolInvocation: const AssistantToolInvocation(
          toolName: 'set_alarm',
          parameters: {'time': '06:30 AM', 'challenge': 'math'},
          resultSummary: 'Scheduled in Android AlarmManager & Local Notifications',
          isExecuted: true,
        ),
      );
    }

    // Bilingual General Response
    final isBangla = RegExp(r'[\u0980-\u09FF]').hasMatch(input);
    final responseText = isBangla
        ? 'আমি আপনাকে সাহায্য করার জন্য প্রস্তুত। আপনি বলতে পারেন: "টাস্ক যোগ করো", "আজকের পরিকল্পনা", অথবা "অ্যালার্ম সেট করো"।'
        : 'I am your Daybook companion. You can ask me to plan your day, schedule alarms with wake-up challenges, or organize your Eisenhower priorities.';

    return ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      sender: MessageSender.assistant,
      content: responseText,
      timestamp: DateTime.now(),
    );
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

  void _simulateVoicePushToTalk() {
    setState(() => _isListening = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.mic, color: Colors.white),
            SizedBox(width: 8),
            Text('Listening in Bangla / English... Speak now!'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isListening = false);
        _handleSend('আজকের সবচেয়ে গুরুত্বপূর্ণ ৩টি কাজ কি কি?');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF6366F1),
              child: Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daybook Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Bilingual (বাংলা / ENG) • Offline Ready', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick Prompts Carousel
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickPrompts.length,
              itemBuilder: (ctx, i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    label: Text(_quickPrompts[i], style: const TextStyle(fontSize: 11)),
                    onPressed: () => _handleSend(_quickPrompts[i]),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Chat messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: widget.messages.length,
              itemBuilder: (ctx, i) {
                final msg = widget.messages[i];
                final isUser = msg.isUser;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF6366F1)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
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
                        Text(
                          msg.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: isUser
                                ? Colors.white
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                        // Tool execution pill
                        if (msg.toolInvocation != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt, size: 12, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  'Tool: ${msg.toolInvocation!.toolName} ✓',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Input bar with mic button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : const Color(0xFF6366F1),
                  ),
                  onPressed: _simulateVoicePushToTalk,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type or speak in বাংলা or English...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF6366F1)),
                  onPressed: () => _handleSend(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
