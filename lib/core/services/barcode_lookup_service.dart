import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/models/recycling_category.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:uuid/uuid.dart';

class BarcodeLookupService {
  static const _uuid = Uuid();

  /// Look up a barcode and return a ScanItem if found, null otherwise
  static ScanItem? lookupBarcode(String barcode) {
    final products = RecyclingData.productDatabase;
    final match = products.where((p) => p['barcode'] == barcode).firstOrNull;
    if (match == null) return null;

    return ScanItem(
      id: _uuid.v4(),
      name: match['name'] as String,
      barcode: barcode,
      categoryId: match['categoryId'] as String,
      timestamp: DateTime.now(),
      brand: match['brand'] as String?,
      notes: match['notes'] as String?,
      imageEmoji: match['imageEmoji'] as String?,
    );
  }

  /// Create a manual scan item from category selection
  static ScanItem createManualItem({
    required String barcode,
    required String categoryId,
    String name = 'Unknown Item',
  }) {
    return ScanItem(
      id: _uuid.v4(),
      name: name,
      barcode: barcode,
      categoryId: categoryId,
      timestamp: DateTime.now(),
      imageEmoji: RecyclingData.categoriesMap[categoryId]?.recycleSymbol,
    );
  }

  static RecyclingCategory? getCategoryForItem(ScanItem item) {
    return RecyclingData.categoriesMap[item.categoryId];
  }
}
