import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'msg_1',
      senderName: 'Academic Coordinator',
      text: 'Good morning everyone! Please make sure to download the Calculus assignment from the Library tab before today\'s 5:30 PM session.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isMe: false,
    ),
    ChatMessage(
      id: 'msg_2',
      senderName: 'Kavindu Perera',
      text: 'Thank you Sir! Is the formula cheat sheet included in the same folder?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
      isMe: false,
    ),
    ChatMessage(
      id: 'msg_3',
      senderName: 'You',
      text: 'Yes Kavindu, both the assignment set and the formula sheet are uploaded in the Combined Mathematics folder.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      isMe: true,
    ),
    ChatMessage(
      id: 'msg_4',
      senderName: 'Senthil Kumar',
      text: 'Will there be a live recording uploaded after the session?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      isMe: false,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderName: 'You',
          text: text,
          timestamp: DateTime.now(),
          isMe: true,
        ),
      );
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Channel Selector Pill Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
            border: Border(bottom: BorderSide(color: isDark ? AppColors.lineDark : AppColors.lineLight)),
          ),
          child: Row(
            children: [
              const Icon(Icons.tag, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Advanced Mathematics Cohort 2026',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '42 Active',
                  style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Message List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _buildMessageBubble(msg, isDark);
            },
          ),
        ),

        // Message Input Field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            border: Border(top: BorderSide(color: isDark ? AppColors.lineDark : AppColors.lineLight)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: AppColors.mutedLight),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File attachment dialog opened.')),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: isTamil ? 'செய்தியை உள்ளிடவும்...' : 'Type a message...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : AppColors.bgLight,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.accent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe
              ? AppColors.accent
              : (isDark ? AppColors.cardDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: msg.isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: msg.isMe ? null : Border.all(color: isDark ? AppColors.lineDark : AppColors.lineLight),
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!msg.isMe) ...[
              Text(
                msg.senderName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.brandBlue),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isMe ? Colors.white : (isDark ? AppColors.inkDark : AppColors.inkLight),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: msg.isMe ? Colors.white70 : AppColors.mutedLight,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

