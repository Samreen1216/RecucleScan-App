import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadgeNotifier extends StateNotifier<int> {
  BadgeNotifier() : super(0) {
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('badges_earned') ?? 0;
  }

  Future<void> earnBadge() async {
    if (state >= 10) return; // Cap at 10 for UI purposes
    state++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('badges_earned', state);
  }
}

final badgeProvider = StateNotifierProvider<BadgeNotifier, int>((ref) {
  return BadgeNotifier();
});
