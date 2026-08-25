import 'package:hive_flutter/hive_flutter.dart';
import 'package:recyclescan/core/models/scan_item.dart';

class HiveService {
  static const String scanHistoryBox = 'scan_history';

  static Future<void> openBoxes() async {
    if (!Hive.isBoxOpen(scanHistoryBox)) {
      await Hive.openBox<ScanItem>(scanHistoryBox);
    }
  }

  static Box<ScanItem> get scanHistory => Hive.box<ScanItem>(scanHistoryBox);

  static Future<void> addScanItem(ScanItem item) async {
    if (!Hive.isBoxOpen(scanHistoryBox)) {
      await openBoxes();
    }
    await scanHistory.put(item.id, item);
  }

  static Future<void> deleteScanItem(String id) async {
    if (!Hive.isBoxOpen(scanHistoryBox)) {
      await openBoxes();
    }
    await scanHistory.delete(id);
  }

  static Future<void> clearAll() async {
    if (!Hive.isBoxOpen(scanHistoryBox)) {
      await openBoxes();
    }
    await scanHistory.clear();
  }

  static List<ScanItem> getAllScanItems() {
    if (!Hive.isBoxOpen(scanHistoryBox)) return [];
    final items = scanHistory.values.toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  static bool containsBarcode(String barcode) {
    if (!Hive.isBoxOpen(scanHistoryBox)) return false;
    return scanHistory.values.any((item) => item.barcode == barcode);
  }
}
