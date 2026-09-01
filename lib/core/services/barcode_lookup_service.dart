import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/models/recycling_category.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:uuid/uuid.dart';

class BarcodeLookupService {
  static const _uuid = Uuid();

  /// Normalizes a barcode string by trimming, removing whitespace, dashes, and non-alphanumeric chars.
  static String normalizeBarcode(String raw) {
    return raw.trim().replaceAll(RegExp(r'[\s\-_]'), '');
  }

  /// Generates common representation variants of a barcode (raw, stripped zeros, EAN/UPC zero-padded).
  static Set<String> getBarcodeVariants(String raw) {
    final clean = normalizeBarcode(raw);
    if (clean.isEmpty) return {};

    final variants = <String>{clean};

    // Stripped leading zeros
    final stripped = clean.replaceFirst(RegExp(r'^0+'), '');
    if (stripped.isNotEmpty) {
      variants.add(stripped);
    }

    // Only if digits, produce standard UPC/EAN padded lengths
    if (RegExp(r'^\d+$').hasMatch(clean)) {
      if (stripped.length <= 8) {
        variants.add(stripped.padLeft(8, '0'));
      }
      if (stripped.length <= 12) {
        variants.add(stripped.padLeft(12, '0'));
      }
      if (stripped.length <= 13) {
        variants.add(stripped.padLeft(13, '0'));
      }
      if (stripped.length <= 14) {
        variants.add(stripped.padLeft(14, '0'));
      }
    }

    return variants;
  }

  /// Look up a barcode and return a ScanItem if found, null otherwise.
  /// Generic normalization ensures UPC-A, EAN-13, EAN-8, GTIN, leading-zero, and whitespace variations match reliably.
  static ScanItem? lookupBarcode(String barcode) {
    final cleanBarcode = normalizeBarcode(barcode);
    if (cleanBarcode.isEmpty) return null;

    final products = RecyclingData.productDatabase;
    final queryVariants = getBarcodeVariants(cleanBarcode);
    final strippedQuery = cleanBarcode.replaceFirst(RegExp(r'^0+'), '');

    // Pass 1: Exact match with any query variant
    for (final p in products) {
      final dbBarcode = (p['barcode'] as String?)?.trim() ?? '';
      if (dbBarcode.isEmpty) continue;

      if (queryVariants.contains(dbBarcode)) {
        return _buildItem(p, cleanBarcode);
      }
    }

    // Pass 2: Normalized stripped zero match
    if (strippedQuery.isNotEmpty) {
      for (final p in products) {
        final dbBarcode = (p['barcode'] as String?)?.trim() ?? '';
        final strippedDb = dbBarcode.replaceFirst(RegExp(r'^0+'), '');
        if (strippedDb.isNotEmpty && strippedDb == strippedQuery) {
          return _buildItem(p, cleanBarcode);
        }
      }
    }

    // Pass 3: Check database variants against query variants
    for (final p in products) {
      final dbBarcode = (p['barcode'] as String?)?.trim() ?? '';
      if (dbBarcode.isEmpty) continue;
      final dbVariants = getBarcodeVariants(dbBarcode);
      if (dbVariants.any((v) => queryVariants.contains(v))) {
        return _buildItem(p, cleanBarcode);
      }
    }

    return null;
  }

  static ScanItem _buildItem(Map<String, dynamic> match, String matchedBarcode) {
    return ScanItem(
      id: _uuid.v4(),
      name: match['name'] as String,
      barcode: matchedBarcode,
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
      barcode: normalizeBarcode(barcode),
      categoryId: categoryId,
      timestamp: DateTime.now(),
      imageEmoji: RecyclingData.categoriesMap[categoryId]?.recycleSymbol,
    );
  }

  static RecyclingCategory? getCategoryForItem(ScanItem item) {
    return RecyclingData.categoriesMap[item.categoryId];
  }
}
