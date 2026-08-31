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

      // Calculate category counts
      final countPlastic = allItems.where((i) => i.categoryId.toLowerCase() == 'plastic').length;
      final countPaper   = allItems.where((i) => i.categoryId.toLowerCase() == 'paper').length;
      final countGlass   = allItems.where((i) => i.categoryId.toLowerCase() == 'glass').length;
      final countMetal   = allItems.where((i) => i.categoryId.toLowerCase() == 'metal').length;
      final countGeneral = allItems.where((i) => i.categoryId.toLowerCase() == 'general').length;

      // Last 5 recent scans
      final recentItems = allItems.take(5).toList();
      
      final random = Random();
      String ecoTip = _ecoTips[random.nextInt(_ecoTips.length)];

      // Save primitive data for Native Android XML Layout
      await Future.wait([
        HomeWidget.saveWidgetData<int>('total_items', totalItems),
        HomeWidget.saveWidgetData<int>('items_recycled', recycledItems),
        HomeWidget.saveWidgetData<int>('items_this_week', itemsThisWeek),
        HomeWidget.saveWidgetData<int>('recyclable_percentage', recyclablePercentage),
        HomeWidget.saveWidgetData<int>('count_plastic', countPlastic),
        HomeWidget.saveWidgetData<int>('count_paper', countPaper),
        HomeWidget.saveWidgetData<int>('count_glass', countGlass),
        HomeWidget.saveWidgetData<int>('count_metal', countMetal),
        HomeWidget.saveWidgetData<int>('count_general', countGeneral),
        HomeWidget.saveWidgetData<String>('eco_tip', ecoTip),
      ]);

      // Save up to 5 recent items with formatted date
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final recentSaves = <Future<void>>[];
      for (int i = 0; i < 5; i++) {
        if (i < recentItems.length) {
          final item = recentItems[i];
          final dt = item.timestamp;
          final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
          final ampm = dt.hour >= 12 ? 'PM' : 'AM';
          final minute = dt.minute.toString().padLeft(2, '0');
          final formattedDate = '${dt.day} ${months[dt.month - 1]}, $hour:$minute $ampm';
          
          recentSaves.add(HomeWidget.saveWidgetData<String>('recent_${i}_name', item.name));
          recentSaves.add(HomeWidget.saveWidgetData<String>('recent_${i}_category', item.categoryId.toUpperCase()));
          recentSaves.add(HomeWidget.saveWidgetData<String>('recent_${i}_time', formattedDate));
        } else {
          recentSaves.add(HomeWidget.saveWidgetData<String>('recent_${i}_name', "-"));
          recentSaves.add(HomeWidget.saveWidgetData<String>('recent_${i}_category', "-"));
          recentSaves.add(HomeWidget.saveWidgetData<String>('recent_${i}_time', "-"));
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
