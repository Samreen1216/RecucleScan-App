import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:recyclescan/core/services/hive_service.dart';

final scanHistoryProvider =
    StateNotifierProvider<ScanHistoryNotifier, List<ScanItem>>((ref) {
  return ScanHistoryNotifier();
});

class ScanHistoryNotifier extends StateNotifier<List<ScanItem>> {
  ScanHistoryNotifier() : super([]) {
    _load();
  }

  void _load() {
    state = HiveService.getAllScanItems();
    // Listen for Hive changes if box is open
    if (Hive.isBoxOpen(HiveService.scanHistoryBox)) {
      HiveService.scanHistory.listenable().addListener(() {
        state = HiveService.getAllScanItems();
      });
    }
  }

  Future<void> addItem(ScanItem item) async {
    await HiveService.addScanItem(item);
    state = HiveService.getAllScanItems();
  }

  Future<void> removeItem(String id) async {
    await HiveService.deleteScanItem(id);
    state = HiveService.getAllScanItems();
  }

  Future<void> clearAll() async {
    await HiveService.clearAll();
    state = [];
  }

  List<ScanItem> get recentItems => state.take(5).toList();

  List<ScanItem> search(String query) {
    if (query.isEmpty) return state;
    final q = query.toLowerCase();
    return state
        .where((item) =>
            item.name.toLowerCase().contains(q) ||
            (item.brand?.toLowerCase().contains(q) ?? false) ||
            item.categoryId.toLowerCase().contains(q))
        .toList();
  }
}
