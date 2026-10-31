import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen>
    with TickerProviderStateMixin {
  final PageController pageController = PageController();

  final List<String> videoPaths = [
    'assets/videos/short1.mp4',
    'assets/videos/short2.mp4',
    'assets/videos/short3.mp4',
    'assets/videos/short4.mp4',
  ];

  final List<String> usernames = [
    '@alex.dev',
    '@maya.creates',
    '@david.learns',
    '@sara.creator',
  ];

  final List<String> captions = [
    'Building something amazing 🚀',
    'Create. Connect. Grow. ✨',
    'Learning something new every day 📚',
    'Keep going. Your journey matters 💜',
  ];

  final List<int> likeCounts = [12400, 8700, 6300, 9100];

  final List<int> commentCounts = [328, 214, 156, 287];

  final List<bool> liked = [false, false, false, false];

  final List<bool> saved = [false, false, false, false];

  final List<bool> following = [false, false, false, false];

  final List<VideoPlayerController?> controllers = [];

  final List<List<String>> comments = [
    ['This is amazing! 🔥', 'Luma is looking great!', 'Keep creating 🚀'],
    ['Love this video!', 'This is so cool 🔥'],
    ['Great work!', 'Keep learning 📚'],
    ['Amazing journey 💜', 'Keep going!'],
  ];

  int currentPage = 0;

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < videoPaths.length; i++) {
      controllers.add(null);
    }

    _initializeVideo(0);

    if (videoPaths.length > 1) {
      _initializeVideo(1);
    }
  }

  Future<void> _initializeVideo(int index) async {
    if (controllers[index] != null) {
      return;
    }

    final controller = VideoPlayerController.asset(videoPaths[index]);

    controllers[index] = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);

      if (index == currentPage) {
        await controller.play();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      debugPrint('Video $index failed to load: $error');
    }
  }

  Future<void> _changeVideo(int index) async {
    final previousController = controllers[currentPage];

    if (previousController != null && previousController.value.isInitialized) {
      await previousController.pause();
    }

    setState(() {
      currentPage = index;
    });

    await _initializeVideo(index);

    final currentController = controllers[index];

    if (currentController != null && currentController.value.isInitialized) {
      await currentController.play();
    }

    if (index + 1 < videoPaths.length) {
      _initializeVideo(index + 1);
    }
  }

  void _togglePlay() {
    final controller = controllers[currentPage];

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _toggleLike() {
    setState(() {
      liked[currentPage] = !liked[currentPage];

      if (liked[currentPage]) {
        likeCounts[currentPage]++;
      } else {
        likeCounts[currentPage]--;
      }
    });
  }

  void _toggleSave() {
    setState(() {
      saved[currentPage] = !saved[currentPage];
    });

    _showMessage(
      saved[currentPage] ? 'Saved to your collection 🔖' : 'Removed from saved',
    );
  }

  void _toggleFollow() {
    setState(() {
      following[currentPage] = !following[currentPage];
    });

    _showMessage(
      following[currentPage]
          ? 'Following ${usernames[currentPage]}'
          : 'Unfollowed ${usernames[currentPage]}',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareVideo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Share this Short',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _shareOption(Icons.link, 'Copy link'),
                    _shareOption(Icons.message_outlined, 'Message'),
                    _shareOption(Icons.share_outlined, 'More'),
                  ],
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shareOption(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);

        _showMessage('$label selected 🚀');
      },
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1F2937),
            ),
            child: Icon(icon, color: const Color(0xFF22D3EE)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  void _showComments() {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentComments = comments[currentPage];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Text(
                            'Comments',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${currentComments.length}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentComments.length,
                        itemBuilder: (context, index) {
                          final username = index % 2 == 0
                              ? '@creator'
                              : '@luma_user';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF7C3AED),
                                        Color(0xFF22D3EE),
                                      ],
                                    ),
                                  ),
                                  child: const CircleAvatar(
                                    backgroundColor: Color(0xFF111827),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1F2937),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          currentComments[index],
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Like',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      decoration: const BoxDecoration(color: Color(0xFF0D111C)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) {
                                _addComment(commentController, setModalState);
                              },
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                filled: true,
                                fillColor: const Color(0xFF1F2937),
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
                              onPressed: () {
                                _addComment(commentController, setModalState);
                              },
                              icon: const Icon(Icons.send, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      commentController.dispose();
    });
  }

  void _addComment(
    TextEditingController controller,
    StateSetter setModalState,
  ) {
    final text = controller.text.trim();

    if (text.isEmpty) {
      return;
    }

    setModalState(() {
      comments[currentPage].add(text);
    });

    setState(() {
      commentCounts[currentPage]++;
    });

    controller.clear();
  }

  @override
  void dispose() {
    pageController.dispose();

    for (final controller in controllers) {
      controller?.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              itemCount: videoPaths.length,
              onPageChanged: _changeVideo,
              itemBuilder: (context, index) {
                return _buildVideo(index);
              },
            ),
            Positioned(
              top: 12,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  const Text(
                    'Shorts',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  _topTab('For You', true),
                  const SizedBox(width: 8),
                  _topTab('Following', false),
                ],
              ),
            ),
            Positioned(
              top: 65,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${currentPage + 1}/${videoPaths.length}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topTab(String text, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF7C3AED) : const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Colors.white : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildVideo(int index) {
    final controller = controllers[index];

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: controller != null && controller.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF22D3EE),
                      ),
                    ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.90),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity:
                    controller != null &&
                        controller.value.isInitialized &&
                        controller.value.isPlaying
                    ? 0.0
                    : 1.0,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    controller != null &&
                            controller.value.isInitialized &&
                            controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 145,
              child: Column(
                children: [
                  _animatedAction(
                    icon: liked[index] ? Icons.favorite : Icons.favorite_border,
                    label: _formatNumber(likeCounts[index]),
                    active: liked[index],
                    onTap: _toggleLike,
                  ),
                  const SizedBox(height: 18),
                  _animatedAction(
                    icon: Icons.chat_bubble_outline,
                    label: _formatNumber(commentCounts[index]),
                    onTap: _showComments,
                  ),
                  const SizedBox(height: 18),
                  _animatedAction(
                    icon: Icons.send_outlined,
                    label: 'Share',
                    onTap: _shareVideo,
                  ),
                  const SizedBox(height: 18),
                  _animatedAction(
                    icon: saved[index] ? Icons.bookmark : Icons.bookmark_border,
                    label: 'Save',
                    active: saved[index],
                    onTap: _toggleSave,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 85,
              bottom: 38,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF22D3EE)],
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const CircleAvatar(
                          backgroundColor: Color(0xFF111827),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          usernames[index],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleFollow,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: following[index]
                                ? Colors.white12
                                : Colors.transparent,
                            border: Border.all(
                              color: following[index]
                                  ? Colors.white24
                                  : Colors.white70,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            following[index] ? 'Following' : 'Follow',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    captions[index],
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  if (controller != null && controller.value.isInitialized)
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.keyboard_arrow_up,
                    size: 16,
                    color: Colors.white54,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Swipe for more',
                    style: TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.85)
                  : Colors.black54,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }

    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }

    return number.toString();
  }
}
