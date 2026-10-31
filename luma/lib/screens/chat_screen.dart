import 'package:flutter/material.dart';

import '../data/streak_store.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  final IconData avatar;

  const ChatScreen({super.key, required this.name, required this.avatar});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> messages = [
    {'text': 'Hey! How are you?', 'isMe': false},
    {'text': 'I am doing great! 🚀', 'isMe': true},
    {'text': 'Nice! What are you building?', 'isMe': false},
  ];

  @override
  void initState() {
    super.initState();

    StreakStore.instance.addListener(_refreshStreak);
  }

  @override
  void dispose() {
    StreakStore.instance.removeListener(_refreshStreak);
    _messageController.dispose();

    super.dispose();
  }

  void _refreshStreak() {
    if (mounted) {
      setState(() {});
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      messages.add({'text': text, 'isMe': true});
    });

    _messageController.clear();

    // Increase the current conversation streak.
    StreakStore.instance.increaseStreak(widget.name);

    // Small feedback.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message sent 🔥'),
        duration: Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = StreakStore.instance.getStreak(widget.name);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,

        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF30205C),

              child: Icon(widget.avatar, color: const Color(0xFF22D3EE)),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                widget.name,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(width: 8),

            _ChatStreakBadge(streak: streak),

            const SizedBox(width: 8),
          ],
        ),
      ),

      body: Column(
        children: [
          // ==========================================
          // STREAK BANNER
          // ==========================================

          _StreakBanner(name: widget.name, streak: streak),

          // ==========================================
          // MESSAGES
          // ==========================================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),

              itemCount: messages.length,

              itemBuilder: (context, index) {
                final message = messages[index];

                return _messageBubble(
                  text: message['text'],
                  isMe: message['isMe'],
                );
              },
            ),
          ),

          // ==========================================
          // MESSAGE INPUT
          // ==========================================
          _messageInput(),
        ],
      ),
    );
  }

  Widget _messageBubble({required String text, required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),

        margin: const EdgeInsets.only(bottom: 12),

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                )
              : null,

          color: isMe ? null : const Color(0xFF111827),

          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),

            bottomLeft: Radius.circular(isMe ? 18 : 4),

            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),

        child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4)),
      ),
    );
  }

  Widget _messageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),

        decoration: const BoxDecoration(color: Color(0xFF0D111C)),

        child: Row(
          children: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Media sharing coming soon 📷')),
                );
              },

              icon: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF22D3EE),
              ),
            ),

            Expanded(
              child: TextField(
                controller: _messageController,

                textInputAction: TextInputAction.send,

                onSubmitted: (_) {
                  _sendMessage();
                },

                decoration: InputDecoration(
                  hintText: 'Message ${widget.name}...',

                  filled: true,

                  fillColor: const Color(0xFF111827),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),

                    borderSide: BorderSide.none,
                  ),

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,

                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF22D3EE)],
                ),
              ),

              child: IconButton(
                onPressed: _sendMessage,

                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// CHAT STREAK BADGE
// ==================================================

class _ChatStreakBadge extends StatelessWidget {
  final int streak;

  const _ChatStreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),

      duration: const Duration(milliseconds: 800),

      curve: Curves.elasticOut,

      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,

          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              gradient: const LinearGradient(
                colors: [Color(0xFF3A1820), Color(0xFF25151D)],
              ),

              border: Border.all(color: const Color(0xFFFF6B35)),

              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.18),

                  blurRadius: 10,
                ),
              ],
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),

                const SizedBox(width: 4),

                Text(
                  '$streak',
                  style: const TextStyle(
                    color: Color(0xFFFFB088),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================================================
// STREAK BANNER
// ==================================================

class _StreakBanner extends StatelessWidget {
  final String name;
  final int streak;

  const _StreakBanner({required this.name, required this.streak});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),

      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),

        gradient: const LinearGradient(
          colors: [Color(0xFF261521), Color(0xFF15121D)],
        ),

        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.25),
        ),
      ),

      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),

            duration: const Duration(milliseconds: 900),

            curve: Curves.elasticOut,

            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,

                child: const Text('🔥', style: TextStyle(fontSize: 27)),
              );
            },
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  '$streak day streak',

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB088),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Keep chatting with $name!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.local_fire_department,
            color: Color(0xFFFF6B35),
            size: 20,
          ),
        ],
      ),
    );
  }
}
