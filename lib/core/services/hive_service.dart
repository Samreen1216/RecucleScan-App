import 'dart:io';
import 'package:path_provider/path_provider.dart';
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
    
    ScanItem itemToSave = item;
    if (item.localImagePath != null) {
      final file = File(item.localImagePath!);
      if (await file.exists()) {
        final docs = await getApplicationDocumentsDirectory();
        final ext = item.localImagePath!.split('.').last;
        final newPath = '${docs.path}/${item.id}.$ext';
        if (item.localImagePath != newPath) {
          await file.copy(newPath);
          itemToSave = item.copyWith(localImagePath: newPath);
        }
      }
    }
    
    await scanHistory.put(itemToSave.id, itemToSave);
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
