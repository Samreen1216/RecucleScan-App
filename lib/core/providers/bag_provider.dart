import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:recyclescan/core/services/hive_service.dart';

final bagProvider = StateNotifierProvider<BagNotifier, List<ScanItem>>((ref) {
  return BagNotifier();
});

class BagNotifier extends StateNotifier<List<ScanItem>> {
  BagNotifier() : super([]) {
    _loadItems();
  }

  void _loadItems() {
    state = HiveService.getBagItems().reversed.toList();
  }

  Future<void> addItem(ScanItem item) async {
    await HiveService.addToBag(item);
    _loadItems();
  }

  Future<void> removeItem(String id) async {
    await HiveService.removeFromBag(id);
    _loadItems();
  }

  Future<void> clearBag() async {
    await HiveService.clearBag();
    _loadItems();
  }

  bool isInBag(String id) {
    return state.any((item) => item.id == id);
  }
}

