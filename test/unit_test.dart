import 'package:flutter_test/flutter_test.dart';
import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:recyclescan/core/services/barcode_lookup_service.dart';

void main() {
  group('RecyclingData tests', () {
    test('Categories list is non-empty and well-formed', () {
      final categories = RecyclingData.categories;
      expect(categories.isNotEmpty, isTrue);
      expect(categories.length, equals(7));

      for (final cat in categories) {
        expect(cat.id.isNotEmpty, isTrue);
        expect(cat.name.isNotEmpty, isTrue);
        expect(cat.whatGoesIn.isNotEmpty, isTrue);
        expect(cat.whatStaysOut.isNotEmpty, isTrue);
        expect(cat.preparationTips.isNotEmpty, isTrue);
        expect(cat.funFact.isNotEmpty, isTrue);
      }
    });

    test('Categories map matches categories list', () {
      final map = RecyclingData.categoriesMap;
      expect(map.length, equals(RecyclingData.categories.length));
      for (final cat in RecyclingData.categories) {
        expect(map.containsKey(cat.id), isTrue);
        expect(map[cat.id], equals(cat));
      }
    });

    test('All products in productDatabase have valid category IDs', () {
      final map = RecyclingData.categoriesMap;
      for (final product in RecyclingData.productDatabase) {
        final categoryId = product['categoryId'] as String;
        expect(map.containsKey(categoryId), isTrue,
            reason: 'Category $categoryId in product ${product['name']} does not exist');
      }
    });
  });

  group('BarcodeLookupService tests', () {
    test('Look up existing barcode returns valid ScanItem', () {
      const barcode = '5000112637939'; // Coca-Cola 500ml
      final item = BarcodeLookupService.lookupBarcode(barcode);

      expect(item, isNotNull);
      expect(item!.barcode, equals(barcode));
      expect(item.name, equals('Coca-Cola 500ml Bottle'));
      expect(item.categoryId, equals('plastic'));
      expect(item.brand, equals('Coca-Cola'));
    });

    test('Look up unknown barcode returns null', () {
      final item = BarcodeLookupService.lookupBarcode('9999999999999');
      expect(item, isNull);
    });

    test('createManualItem creates item with correct fields', () {
      final item = BarcodeLookupService.createManualItem(
        barcode: '1234567890',
        categoryId: 'glass',
        name: 'Custom Glass Bottle',
      );

      expect(item.id.isNotEmpty, isTrue);
      expect(item.name, equals('Custom Glass Bottle'));
      expect(item.barcode, equals('1234567890'));
      expect(item.categoryId, equals('glass'));
      expect(item.imageEmoji, equals('🍾'));
    });

    test('getCategoryForItem returns correct category', () {
      final item = ScanItem(
        id: 'test-id',
        name: 'Test Paper Box',
        barcode: '1111111111',
        categoryId: 'paper',
        timestamp: DateTime.now(),
      );

      final cat = BarcodeLookupService.getCategoryForItem(item);
      expect(cat, isNotNull);
      expect(cat!.name, equals('Paper'));
    });
  });
}
