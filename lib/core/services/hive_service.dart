import 'package:hive_flutter/hive_flutter.dart';
import 'package:recyclescan/core/models/scan_item.dart';

class HiveService {
  static const String scanHistoryBox = 'scan_history';

  static Future<void> openBoxes() async {
    await Hive.openBox<ScanItem>(scanHistoryBox);
  }

  static Box<ScanItem> get scanHistory => Hive.box<ScanItem>(scanHistoryBox);

  static Future<void> addScanItem(ScanItem item) async {
    await scanHistory.put(item.id, item);
  }

  static Future<void> deleteScanItem(String id) async {
    await scanHistory.delete(id);
  }

  static Future<void> clearAll() async {
    await scanHistory.clear();
  }

  static List<ScanItem> getAllScanItems() {
    final items = scanHistory.values.toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  static bool containsBarcode(String barcode) {
    return scanHistory.values.any((item) => item.barcode == barcode);
  }
}
