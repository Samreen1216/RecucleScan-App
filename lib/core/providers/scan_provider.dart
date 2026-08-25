import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recyclescan/core/models/scan_item.dart';

final currentScanProvider =
    StateNotifierProvider<CurrentScanNotifier, AsyncValue<ScanItem?>>((ref) {
  return CurrentScanNotifier();
});

class CurrentScanNotifier extends StateNotifier<AsyncValue<ScanItem?>> {
  CurrentScanNotifier() : super(const AsyncValue.data(null));

  void setItem(ScanItem item) {
    state = AsyncValue.data(item);
  }

  void setLoading() {
    state = const AsyncValue.loading();
  }

  void setError(String message) {
    state = AsyncValue.error(message, StackTrace.current);
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}
