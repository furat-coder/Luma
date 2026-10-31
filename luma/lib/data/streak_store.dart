import 'package:flutter/foundation.dart';

class StreakStore extends ChangeNotifier {
  StreakStore._();

  static final StreakStore instance = StreakStore._();

  final Map<String, int> _streaks = {
    'Alex Johnson': 3,
    'Maya': 7,
    'David': 12,
    'Sara': 5,
  };

  int getStreak(String name) {
    return _streaks[name] ?? 0;
  }

  void increaseStreak(String name) {
    _streaks[name] = getStreak(name) + 1;
    notifyListeners();
  }

  void setStreak(String name, int days) {
    _streaks[name] = days;
    notifyListeners();
  }
}
