import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recyclescan/core/constants/recycling_data.dart';

final ecoTipProvider = Provider<String>((ref) {
  final tips = RecyclingData.ecoTips;
  final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
  return tips[dayOfYear % tips.length];
});
