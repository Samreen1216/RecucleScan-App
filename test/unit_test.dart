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
    test('normalizeBarcode cleans whitespace and non-alphanumerics', () {
      expect(BarcodeLookupService.normalizeBarcode(' 5000112637939 \n'), equals('5000112637939'));
      expect(BarcodeLookupService.normalizeBarcode('0-49000-02892-8'), equals('049000028928'));
      expect(BarcodeLookupService.normalizeBarcode(' 123 456 789 '), equals('123456789'));
    });

    test('getBarcodeVariants produces appropriate digit variations', () {
      final variants = BarcodeLookupService.getBarcodeVariants('0049000028928');
      expect(variants.contains('0049000028928'), isTrue);
      expect(variants.contains('49000028928'), isTrue);
      expect(variants.contains('049000028928'), isTrue);
    });

    test('Look up existing barcode returns valid ScanItem', () {
      const barcode = '5000112637939'; // Coca-Cola 500ml
      final item = BarcodeLookupService.lookupBarcode(barcode);

      expect(item, isNotNull);
      expect(item!.barcode, equals(barcode));
      expect(item.name, equals('Coca-Cola 500ml Bottle'));
      expect(item.categoryId, equals('plastic'));
      expect(item.brand, equals('Coca-Cola'));
    });

    test('Look up barcode with stripped leading zeros matches database', () {
      // Database has '0049000028928' (Sprite 20oz Bottle)
      final item1 = BarcodeLookupService.lookupBarcode('49000028928');
      expect(item1, isNotNull);
      expect(item1!.name, equals('Sprite 20oz Bottle'));

      final item2 = BarcodeLookupService.lookupBarcode('049000028928');
      expect(item2, isNotNull);
      expect(item2!.name, equals('Sprite 20oz Bottle'));

      final item3 = BarcodeLookupService.lookupBarcode('  0049000028928  ');
      expect(item3, isNotNull);
      expect(item3!.name, equals('Sprite 20oz Bottle'));
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

    test('Look up items across expanded product database categories', () {
      // Plastic
      final coke = BarcodeLookupService.lookupBarcode('5000112637939');
      expect(coke, isNotNull);
      expect(coke!.categoryId, equals('plastic'));

      // Metal
      final heinekenCan = BarcodeLookupService.lookupBarcode('5411188051558');
      expect(heinekenCan, isNotNull);
      expect(heinekenCan!.categoryId, equals('metal'));

      // Glass
      final nutella = BarcodeLookupService.lookupBarcode('3017620422003');
      expect(nutella, isNotNull);
      expect(nutella!.categoryId, equals('glass'));

      // Paper
      final kelloggs = BarcodeLookupService.lookupBarcode('5000112476431');
      expect(kelloggs, isNotNull);
      expect(kelloggs!.categoryId, equals('paper'));

      // E-Waste
      final appleCharger = BarcodeLookupService.lookupBarcode('0194252764756');
      expect(appleCharger, isNotNull);
      expect(appleCharger!.categoryId, equals('ewaste'));

      // Organic
      final apples = BarcodeLookupService.lookupBarcode('5000080020027');
      expect(apples, isNotNull);
      expect(apples!.categoryId, equals('organic'));

      // General
      final oreo = BarcodeLookupService.lookupBarcode('7622300489434');
      expect(oreo, isNotNull);
      expect(oreo!.categoryId, equals('general'));
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

  group('QuizData tests', () {
    test('QuizData questions pool is rich, valid, and non-empty', () {
      expect(QuizData.questions.length, greaterThanOrEqualTo(20));
      for (final q in QuizData.questions) {
        expect(q.question.isNotEmpty, isTrue);
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.correctIndex, greaterThanOrEqualTo(0));
        expect(q.correctIndex, lessThan(q.options.length));
        expect(q.explanation.isNotEmpty, isTrue);
      }
    });

    test('getRandomQuestions returns unique fresh questions', () {
      final session1 = QuizData.getRandomQuestions(count: 5);
      expect(session1.length, equals(5));

      final uniqueQuestions = session1.map((q) => q.question).toSet();
      expect(uniqueQuestions.length, equals(5));
    });
  });
}
