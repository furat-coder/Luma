import 'package:flutter/foundation.dart';

class LumaPost {
  final String username;
  final String name;
  final String caption;
  final int likes;
  final int comments;

  // Media information
  final String? mediaPath;
  final String mediaType;

  LumaPost({
    required this.username,
    required this.name,
    required this.caption,
    this.likes = 0,
    this.comments = 0,
    this.mediaPath,
    this.mediaType = 'none',
  });
}

class PostStore extends ChangeNotifier {
  PostStore._();

  static final PostStore instance = PostStore._();

  final List<LumaPost> _posts = [
    LumaPost(
      username: 'alex.dev',
      name: 'Alex Johnson',
      caption:
          'Building something new today. Small steps become big results. 🚀',
      likes: 1200,
      comments: 84,
    ),

    LumaPost(
      username: 'maya.creates',
      name: 'Maya',
      caption: 'Create something that makes people stop, think, and smile. ✨',
      likes: 856,
      comments: 41,
    ),

    LumaPost(
      username: 'david.learns',
      name: 'David',
      caption: 'Learning something new every day. Never stop growing. 📚',
      likes: 643,
      comments: 27,
    ),
  ];

  List<LumaPost> get posts => List.unmodifiable(_posts);

  // Add a new post
  void addPost(String caption, {String? mediaPath, String mediaType = 'none'}) {
    final newPost = LumaPost(
      username: 'yourname',
      name: 'Your Name',
      caption: caption,
      likes: 0,
      comments: 0,
      mediaPath: mediaPath,
      mediaType: mediaType,
    );

    _posts.insert(0, newPost);

    notifyListeners();
  }
}
