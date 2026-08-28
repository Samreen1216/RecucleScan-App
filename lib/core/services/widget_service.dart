import 'dart:math';
import 'package:home_widget/home_widget.dart';
import 'package:recyclescan/core/models/scan_item.dart';

class WidgetService {
  static const String androidWidgetName = 'RecycleScanWidgetProvider';
  static const String iOSWidgetName = 'RecycleScanWidget';

  static final List<String> _ecoTips = [
    "Rinse containers before recycling.",
    "Flatten cardboard boxes before recycling.",
    "Keep plastic bags out of your recycling bin.",
    "Compost your food scraps if possible."
  ];

  static Future<void> initialize() async {
    try {
      // Required for HomeWidget initialization if we need group ID for iOS, but okay for Android.
      await HomeWidget.setAppGroupId('group.com.example.recyclescan');
    } catch (_) {}
  }

  static Future<void> updateWidgetData({
    required List<ScanItem> allItems,
  }) async {
    try {
      final now = DateTime.now();
      
      // Calculate total
      final totalItems = allItems.length;
      final recycledItems = allItems.where((i) => i.categoryId.toLowerCase() != 'general').length;
      final int recyclablePercentage = totalItems > 0 ? ((recycledItems / totalItems) * 100).round() : 0;

      // Calculate this week
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final itemsThisWeek = allItems.where((item) => item.timestamp.isAfter(startOfWeek)).length;

      // Last 3 recent scans
      final recentItems = allItems.take(3).toList();
      
      final random = Random();
      
      // Pick dynamic content
      String ecoTip = _ecoTips[random.nextInt(_ecoTips.length)];
      
      // Quiz dummy data for widget
      String quizQuestion = "What is the most recycled material in the world?";
      String quizOptionA = "A) Plastic";
      String quizOptionB = "B) Aluminum";
      String quizOptionC = "C) Paper";
      String quizOptionD = "D) Steel";

      // Save primitive data for Native Android XML Layout
      await Future.wait([
        HomeWidget.saveWidgetData<int>('total_items', totalItems),
        HomeWidget.saveWidgetData<int>('items_recycled', recycledItems),
        HomeWidget.saveWidgetData<int>('items_this_week', itemsThisWeek),
        HomeWidget.saveWidgetData<int>('recyclable_percentage', recyclablePercentage),
        HomeWidget.saveWidgetData<String>('eco_tip', ecoTip),
        HomeWidget.saveWidgetData<String>('quiz_question', quizQuestion),
        HomeWidget.saveWidgetData<String>('quiz_option_a', quizOptionA),
        HomeWidget.saveWidgetData<String>('quiz_option_b', quizOptionB),
        HomeWidget.saveWidgetData<String>('quiz_option_c', quizOptionC),
        HomeWidget.saveWidgetData<String>('quiz_option_d', quizOptionD),
      ]);

      // Save recent items
      final recentSaves = <Future<void>>[];
      for (int i = 0; i < 3; i++) {
        if (i < recentItems.length) {
          final item = recentItems[i];
          bool isRecyclable = item.categoryId.toLowerCase() != 'general';
          recentSaves.add(HomeWidget.saveWidgetData<String>('recent_${i}_name', item.name));
          recentSaves.add(HomeWidget.saveWidgetData<String>('recent_${i}_category', item.categoryId.toUpperCase()));
          recentSaves.add(HomeWidget.saveWidgetData<String>('recent_${i}_status', isRecyclable ? "✓ Recyclable" : "✗ Not Recyclable"));
        } else {
          recentSaves.add(HomeWidget.saveWidgetData<String>('recent_${i}_name', "-"));
          recentSaves.add(HomeWidget.saveWidgetData<String>('recent_${i}_category', "-"));
          recentSaves.add(HomeWidget.saveWidgetData<String>('recent_${i}_status', "-"));
        }
      }
      await Future.wait(recentSaves);

      // Update all widget sizes in parallel
      await Future.wait([
        HomeWidget.updateWidget(
          name: '${androidWidgetName}Compact',
          iOSName: iOSWidgetName,
        ),
        HomeWidget.updateWidget(
          name: '${androidWidgetName}Wide',
          iOSName: iOSWidgetName,
        ),
        HomeWidget.updateWidget(
          name: '${androidWidgetName}Large',
          iOSName: iOSWidgetName,
        ),
      ]);
    } catch (_) {}
  }
}
