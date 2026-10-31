import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/post_store.dart';
import '../data/story_store.dart';
import 'story_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = 'For You';

  final List<String> filters = ['For You', 'Trending', 'Following', 'Learning'];

  @override
  void initState() {
    super.initState();

    PostStore.instance.addListener(_refreshPosts);
    StoryStore.instance.addListener(_refreshStories);
  }

  @override
  void dispose() {
    PostStore.instance.removeListener(_refreshPosts);
    StoryStore.instance.removeListener(_refreshStories);

    super.dispose();
  }

  void _refreshPosts() {
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshStories() {
    if (mounted) {
      setState(() {});
    }
  }

  // ======================================================
  // ADD STORY
  // ======================================================

  Future<void> _addStory() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add to your story',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 18),

                // PHOTO
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF30205C),
                    child: Icon(Icons.image_outlined),
                  ),
                  title: const Text('Photo'),
                  subtitle: const Text('Share a photo to your story'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickStoryImage();
                  },
                ),

                // VIDEO
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF30205C),
                    child: Icon(Icons.videocam_outlined),
                  ),
                  title: const Text('Video'),
                  subtitle: const Text('Share a video to your story'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickStoryVideo();
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ======================================================
  // PICK STORY IMAGE
  // ======================================================

  Future<void> _pickStoryImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);

    // FIXED:
    // file.path is nullable, so check it before using it.
    if (file == null || file.path == null) {
      return;
    }

    StoryStore.instance.addStory(mediaPath: file.path!, mediaType: 'image');

    _showMessage('Your story has been added ✨');
  }

  // ======================================================
  // PICK STORY VIDEO
  // ======================================================

  Future<void> _pickStoryVideo() async {
    final file = await FilePicker.pickFile(type: FileType.video);

    // FIXED:
    // file.path is nullable, so check it before using it.
    if (file == null || file.path == null) {
      return;
    }

    StoryStore.instance.addStory(mediaPath: file.path!, mediaType: 'video');

    _showMessage('Your video story has been added 🎬');
  }

  // ======================================================
  // OPEN STORY
  // ======================================================

  void _openStory(int index) {
    final stories = StoryStore.instance.stories;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            StoryViewerScreen(stories: stories, initialIndex: index),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  // ======================================================
  // SHOW MESSAGE
  // ======================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ======================================================
  // BUILD STORIES
  // ======================================================

  Widget _buildStories(List<LumaStory> stories) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length,
        separatorBuilder: (context, _) {
          return const SizedBox(width: 14);
        },
        itemBuilder: (context, index) {
          final story = stories[index];

          return _StoryBubble(
            story: story,
            onTap: () {
              _openStory(index);
            },
            onAdd: story.isMine ? _addStory : null,
          );
        },
      ),
    );
  }

  // ======================================================
  // MAIN UI
  // ======================================================

  @override
  Widget build(BuildContext context) {
    final posts = PostStore.instance.posts;
    final stories = StoryStore.instance.stories;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Luma',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showMessage('Notifications coming soon 🔔');
            },
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),

      // ==================================================
      // HOME CONTENT
      // ==================================================
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            // ==================================================
            // WELCOME CARD
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to Luma',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            'Create. Connect. Grow.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // STORIES
            // ==================================================
            _buildStories(stories),

            const SizedBox(height: 18),

            // ==================================================
            // FILTERS
            // ==================================================
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];

                  final selected = selectedFilter == filter;

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                      selectedColor: const Color(0xFF5B21B6),
                      backgroundColor: const Color(0xFF15151B),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide.none,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // POSTS
            // ==================================================
            if (posts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No posts yet.\nCreate something on Luma!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                ),
              ),

            ...posts.map(
              (post) => _PostCard(post: post, onMessage: _showMessage),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// STORY BUBBLE
// ======================================================

class _StoryBubble extends StatelessWidget {
  final LumaStory story;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  const _StoryBubble({required this.story, required this.onTap, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: story.viewed
                        ? const LinearGradient(
                            colors: [Colors.white24, Colors.white12],
                          )
                        : const LinearGradient(
                            colors: [
                              Color(0xFF8B5CF6),
                              Color(0xFF22D3EE),
                              Color(0xFFEC4899),
                            ],
                          ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF070A12),
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 29,
                      backgroundColor: Color(0xFF1F2937),
                      child: Icon(
                        Icons.person,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // ADD BUTTON
                if (story.isMine)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 7),

            Text(
              story.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// POST CARD
// ======================================================

class _PostCard extends StatefulWidget {
  final LumaPost post;
  final void Function(String) onMessage;

  const _PostCard({required this.post, required this.onMessage});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool liked = false;
  bool saved = false;
  bool following = false;

  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();

    if (widget.post.mediaType == 'video' && widget.post.mediaPath != null) {
      _initializeVideo();
    }
  }

  // ======================================================
  // INITIALIZE VIDEO
  // ======================================================

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.file(File(widget.post.mediaPath!));

    try {
      await controller.initialize();

      controller.setLooping(true);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
      });
    } catch (_) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();

    super.dispose();
  }

  // ======================================================
  // LIKE
  // ======================================================

  void _toggleLike() {
    setState(() {
      liked = !liked;
    });
  }

  // ======================================================
  // SAVE
  // ======================================================

  void _toggleSave() {
    setState(() {
      saved = !saved;
    });

    widget.onMessage(saved ? 'Post saved 🔖' : 'Post removed from saved');
  }

  // ======================================================
  // FOLLOW
  // ======================================================

  void _toggleFollow() {
    setState(() {
      following = !following;
    });
  }

  // ======================================================
  // SHARE
  // ======================================================

  void _sharePost() {
    widget.onMessage('Share feature coming soon 🚀');
  }

  // ======================================================
  // COMMENTS
  // ======================================================

  void _showComments() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: 350,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Be the first to comment on this post.',
                  style: TextStyle(color: Colors.white60),
                ),

                const Spacer(),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          filled: true,
                          fillColor: const Color(0xFF1F2937),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);

                        widget.onMessage('Comment added 💬');
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ======================================================
  // BUILD POST
  // ======================================================

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    final totalLikes = post.likes + (liked ? 1 : 0);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // USER HEADER
          // ==================================================

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
                    ),
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        '@${post.username}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                TextButton(
                  onPressed: _toggleFollow,
                  child: Text(following ? 'Following' : 'Follow'),
                ),

                IconButton(
                  onPressed: () {
                    widget.onMessage('More options coming soon');
                  },
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
          ),

          // ==================================================
          // IMAGE
          // ==================================================
          if (post.mediaType == 'image' && post.mediaPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Image.file(
                File(post.mediaPath!),
                width: double.infinity,
                height: 380,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _mediaError();
                },
              ),
            ),

          // ==================================================
          // VIDEO
          // ==================================================
          if (post.mediaType == 'video' && post.mediaPath != null)
            _buildVideo(),

          // ==================================================
          // ACTIONS
          // ==================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: _toggleLike,
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.redAccent : Colors.white,
                  ),
                ),

                Text(
                  _formatNumber(totalLikes),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(width: 8),

                IconButton(
                  onPressed: _showComments,
                  icon: const Icon(Icons.chat_bubble_outline),
                ),

                Text(
                  _formatNumber(post.comments),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(width: 8),

                IconButton(
                  onPressed: _sharePost,
                  icon: const Icon(Icons.send_outlined),
                ),

                const Spacer(),

                IconButton(
                  onPressed: _toggleSave,
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                ),
              ],
            ),
          ),

          // ==================================================
          // CAPTION
          // ==================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.4,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '${post.username} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  TextSpan(text: post.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // VIDEO
  // ======================================================

  Widget _buildVideo() {
    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: 380,
        color: const Color(0xFF0D111C),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }

        setState(() {});
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            height: 380,
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),

          if (!controller.value.isPlaying)
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, size: 38),
            ),
        ],
      ),
    );
  }

  // ======================================================
  // MEDIA ERROR
  // ======================================================

  Widget _mediaError() {
    return Container(
      width: double.infinity,
      height: 380,
      color: const Color(0xFF111827),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, size: 45, color: Colors.white54),

            SizedBox(height: 10),

            Text(
              'Unable to display media',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // NUMBER FORMAT
  // ======================================================

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
