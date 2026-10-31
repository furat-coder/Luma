import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/story_store.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<LumaStory> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int currentIndex;

  VideoPlayerController? videoController;
  Timer? storyTimer;

  double progress = 0;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.initialIndex;

    _loadStory();
  }

  @override
  void dispose() {
    storyTimer?.cancel();
    videoController?.dispose();

    super.dispose();
  }

  Future<void> _loadStory() async {
    storyTimer?.cancel();

    await videoController?.dispose();
    videoController = null;

    progress = 0;

    final story = widget.stories[currentIndex];

    StoryStore.instance.markViewed(story);

    if (story.mediaType == 'video' &&
        story.mediaPath != null &&
        File(story.mediaPath!).existsSync()) {
      final controller = VideoPlayerController.file(File(story.mediaPath!));

      videoController = controller;

      await controller.initialize();

      if (!mounted) return;

      controller
        ..setLooping(false)
        ..play();

      controller.addListener(() {
        if (!mounted || !controller.value.isInitialized) return;

        final duration = controller.value.duration.inMilliseconds;
        final position = controller.value.position.inMilliseconds;

        if (duration > 0) {
          setState(() {
            progress = (position / duration).clamp(0.0, 1.0);
          });
        }

        if (controller.value.position >= controller.value.duration &&
            !controller.value.isPlaying) {
          _nextStory();
        }
      });

      setState(() {});
    } else {
      setState(() {});

      storyTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!mounted) return;

        setState(() {
          progress += 0.1 / 50;
        });

        if (progress >= 1) {
          timer.cancel();
          _nextStory();
        }
      });
    }
  }

  void _nextStory() {
    if (currentIndex < widget.stories.length - 1) {
      setState(() {
        currentIndex++;
      });

      _loadStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });

      _loadStory();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;

          if (details.localPosition.dx < width / 2) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildStoryContent(story),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Row(
                      children: List.generate(widget.stories.length, (index) {
                        final value = index < currentIndex
                            ? 1.0
                            : index == currentIndex
                            ? progress
                            : 0.0;

                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF7C3AED),
                          child: Text(
                            story.name.isNotEmpty
                                ? story.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Text(
                          story.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                        const Spacer(),

                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(LumaStory story) {
    if (story.mediaType == 'image' &&
        story.mediaPath != null &&
        File(story.mediaPath!).existsSync()) {
      return Image.file(File(story.mediaPath!), fit: BoxFit.cover);
    }

    if (story.mediaType == 'video' &&
        videoController != null &&
        videoController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: videoController!.value.aspectRatio,
          child: VideoPlayer(videoController!),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF06B6D4)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            story.name == 'Your Story'
                ? 'Share your moment ✨'
                : '${story.name} is sharing a moment with you.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
