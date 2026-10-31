import 'package:flutter/foundation.dart';

class LumaStory {
  final String username;
  final String name;
  final String? mediaPath;
  final String mediaType;
  final bool isMine;

  bool viewed;

  LumaStory({
    required this.username,
    required this.name,
    this.mediaPath,
    this.mediaType = 'none',
    this.isMine = false,
    this.viewed = false,
  });
}

class StoryStore extends ChangeNotifier {
  StoryStore._();

  static final StoryStore instance = StoryStore._();

  final List<LumaStory> _stories = [
    LumaStory(username: 'yourname', name: 'Your Story', isMine: true),
    LumaStory(username: 'maya.creates', name: 'Maya'),
    LumaStory(username: 'alex.dev', name: 'Alex'),
    LumaStory(username: 'david.learns', name: 'David'),
    LumaStory(username: 'sara.design', name: 'Sara'),
  ];

  List<LumaStory> get stories => List.unmodifiable(_stories);

  void addStory({required String mediaPath, required String mediaType}) {
    // Remove the previous "Your Story" placeholder.
    _stories.removeWhere((story) => story.isMine);

    _stories.insert(
      0,
      LumaStory(
        username: 'yourname',
        name: 'Your Story',
        mediaPath: mediaPath,
        mediaType: mediaType,
        isMine: true,
      ),
    );

    notifyListeners();
  }

  void markViewed(LumaStory story) {
    story.viewed = true;
    notifyListeners();
  }
}
