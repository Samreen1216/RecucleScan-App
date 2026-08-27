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

  static final List<String> _didYouKnow = [
    "Glass can be recycled repeatedly.",
    "Aluminum can be recycled again and again.",
    "Recycling one aluminum can saves enough energy to run a TV for 3 hours."
  ];

  static Future<void> initialize() async {
    // Required for HomeWidget initialization if we need group ID for iOS, but okay for Android.
    await HomeWidget.setAppGroupId('group.com.example.recyclescan');
  }

  static Future<void> updateWidgetData({
    required List<ScanItem> allItems,
  }) async {
    final now = DateTime.now();
    
    // Calculate total
    final totalItems = allItems.length;

    // Calculate this week
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final itemsThisWeek = allItems.where((item) => item.timestamp.isAfter(startOfWeek)).length;

    // Last 3 recent scans
    final recentItems = allItems.take(3).toList();
    
    final random = Random();
    
    // Pick dynamic content
    String contentTitle = "";
    String contentText = "";
    
    final int stateChoice = random.nextInt(4);
    switch (stateChoice) {
      case 0:
        contentTitle = "ECO TIP";
        contentText = _ecoTips[random.nextInt(_ecoTips.length)];
        break;
      case 1:
        contentTitle = "DID YOU KNOW?";
        contentText = _didYouKnow[random.nextInt(_didYouKnow.length)];
        break;
      case 2:
        contentTitle = "NICE WORK!";
        contentText = "You've sorted $totalItems items.";
        break;
      case 3:
      default:
        contentTitle = "IMPACT";
        contentText = "You're making a difference!";
        break;
    }

    // Save primitive data for Native Android XML Layout
    await HomeWidget.saveWidgetData<int>('total_items', totalItems);
    await HomeWidget.saveWidgetData<int>('items_this_week', itemsThisWeek);
    
    await HomeWidget.saveWidgetData<String>('content_title', contentTitle);
    await HomeWidget.saveWidgetData<String>('content_text', contentText);

    // Save recent items as distinct strings
    for (int i = 0; i < 3; i++) {
      if (i < recentItems.length) {
        final item = recentItems[i];
        final formattedName = "${item.name} — ${item.categoryId.toUpperCase()}";
        await HomeWidget.saveWidgetData<String>('recent_item_$i', formattedName);
      } else {
        await HomeWidget.saveWidgetData<String>('recent_item_$i', "");
      }
    }

    // Update all widget sizes
    await HomeWidget.updateWidget(
      name: '${androidWidgetName}Compact',
      iOSName: iOSWidgetName,
    );
    await HomeWidget.updateWidget(
      name: '${androidWidgetName}Wide',
      iOSName: iOSWidgetName,
    );
    await HomeWidget.updateWidget(
      name: '${androidWidgetName}Large',
      iOSName: iOSWidgetName,
    );
  }
}
