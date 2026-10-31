import 'package:flutter/material.dart';

import '../data/streak_store.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final List<(String, String, IconData)> users = [
    ('Alex Johnson', 'Hey! How are you?', Icons.person),
    ('Maya', 'Check out my new video!', Icons.face),
    ('David', 'That was awesome 🔥', Icons.person_outline),
    ('Sara', 'See you tomorrow!', Icons.face),
  ];

  @override
  void initState() {
    super.initState();

    StreakStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    StreakStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New message coming soon ✨'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,

        separatorBuilder: (_, _) => const SizedBox(height: 8),

        itemBuilder: (context, index) {
          final user = users[index];
          final name = user.$1;
          final message = user.$2;
          final avatar = user.$3;

          final streak = StreakStore.instance.getStreak(name);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),

            tileColor: const Color(0xFF111827),

            leading: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF22D3EE)],
                ),
              ),
              padding: const EdgeInsets.all(2),

              child: CircleAvatar(
                backgroundColor: const Color(0xFF111827),
                child: Icon(avatar, color: Colors.white),
              ),
            ),

            title: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                _StreakBadge(streak: streak),
              ],
            ),

            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),

              child: Text(
                message,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),

            trailing: const Icon(Icons.chevron_right, color: Color(0xFF22D3EE)),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(name: name, avatar: avatar),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;

  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) {
      return const SizedBox.shrink();
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.75, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,

      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,

          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

            decoration: BoxDecoration(
              color: const Color(0xFF2A1720),
              borderRadius: BorderRadius.circular(20),

              border: Border.all(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
              ),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 13)),

                const SizedBox(width: 3),

                Text(
                  '$streak',
                  style: const TextStyle(
                    color: Color(0xFFFFA06B),
                    fontSize: 11,
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
