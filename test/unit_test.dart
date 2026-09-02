import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:recyclescan/core/constants/quiz_data.dart';
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

  group('SVG Icons tests & generation', () {
    test('Generate and verify custom SVG icon set in assets/icons', () {
      final dir = Directory('assets/icons');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final icons = <String, String>{
        'eco_leaf.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/></svg>',
        'lightbulb.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-1 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"/><path d="M9 18h6"/><path d="M10 22h4"/></svg>',
        'quiz_badge.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="4"/><path d="M9 9h6"/><path d="M9 13h6"/><path d="M9 17h4"/><path d="m15 15 2 2 4-4"/></svg>',
        'scan_viewfinder.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7V5a2 2 0 0 1 2-2h2"/><path d="M17 3h2a2 2 0 0 1 2 2v2"/><path d="M21 17v2a2 2 0 0 1-2 2h-2"/><path d="M7 21H5a2 2 0 0 1-2-2v-2"/><line x1="7" x2="17" y1="12" y2="12"/><line x1="12" x2="12" y1="7" y2="17"/></svg>',
        'qr_code.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="5" height="5" x="3" y="3" rx="1"/><rect width="5" height="5" x="16" y="3" rx="1"/><rect width="5" height="5" x="3" y="16" rx="1"/><path d="M21 16h-3a2 2 0 0 0-2 2v3"/><path d="M21 21v.01"/><path d="M12 7v3a2 2 0 0 1-2 2H7"/><path d="M3 12h.01"/><path d="M12 3h.01"/><path d="M12 16v.01"/><path d="M16 12h1"/><path d="M21 12v.01"/><path d="M12 21v-1"/></svg>',
        'ai_sparkle.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 3-1.9 5.8a2 2 0 0 1-1.3 1.3L3 12l5.8 1.9a2 2 0 0 1 1.3 1.3L12 21l1.9-5.8a2 2 0 0 1 1.3-1.3L21 12l-5.8-1.9a2 2 0 0 1-1.3-1.3Z"/><path d="M5 3v4"/><path d="M3 5h4"/><path d="M19 17v4"/><path d="M17 19h4"/></svg>',
        'recycle_arrows.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 19H4.815a1.83 1.83 0 0 1-1.57-.881 1.785 1.785 0 0 1-.004-1.784L7.196 9.5"/><path d="M11 19h8.2a1.8 1.8 0 0 0 1.554-.897 1.8 1.8 0 0 0 0-1.784L17 10"/><path d="m15.5 4-4.8 8.3a1.8 1.8 0 0 0 0 1.784 1.8 1.8 0 0 0 1.554.897L19 15"/><polyline points="11 22 7 19 11 16"/><polyline points="15 7 17 10 20 8"/><polyline points="14 7 15.5 4 19 5"/></svg>',
        'shopping_bag.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"/><path d="M3 6h18"/><path d="M16 10a4 4 0 0 1-8 0"/></svg>',
        'history_clock.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l4 2"/></svg>',
        'trophy_badge.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.45.99-.99 1.01A5 5 0 0 1 4.5 13H4"/><path d="M14 14.66V17c0 .55.45.99.99 1.01A5 5 0 0 0 19.5 13H20"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/></svg>',
        'search_off.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" x2="16.65" y1="21" y2="16.65"/><line x1="8" x2="14" y1="11" y2="11"/></svg>',
        'verified_check.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/><path d="m9 12 2 2 4-4"/></svg>',
        'guide_book.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1-2.5-2.5Z"/><path d="M6 6h10"/><path d="M6 10h10"/><path d="M6 14h6"/></svg>',
        'settings_gear.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>',
      };

      for (final entry in icons.entries) {
        final file = File('assets/icons/${entry.key}');
        file.writeAsStringSync(entry.value);
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync().contains('<svg'), isTrue);
      }

      // Generate app_svgs.dart
      const appSvgsContent = '''class AppSvgs {
  AppSvgs._();

  static const String ecoLeaf = 'assets/icons/eco_leaf.svg';
  static const String lightbulb = 'assets/icons/lightbulb.svg';
  static const String quizBadge = 'assets/icons/quiz_badge.svg';
  static const String scanViewfinder = 'assets/icons/scan_viewfinder.svg';
  static const String qrCode = 'assets/icons/qr_code.svg';
  static const String aiSparkle = 'assets/icons/ai_sparkle.svg';
  static const String recycleArrows = 'assets/icons/recycle_arrows.svg';
  static const String shoppingBag = 'assets/icons/shopping_bag.svg';
  static const String historyClock = 'assets/icons/history_clock.svg';
  static const String trophyBadge = 'assets/icons/trophy_badge.svg';
  static const String searchOff = 'assets/icons/search_off.svg';
  static const String verifiedCheck = 'assets/icons/verified_check.svg';
  static const String guideBook = 'assets/icons/guide_book.svg';
  static const String settingsGear = 'assets/icons/settings_gear.svg';
}
''';
      File('lib/core/constants/app_svgs.dart').writeAsStringSync(appSvgsContent);
      expect(File('lib/core/constants/app_svgs.dart').existsSync(), isTrue);

      // Generate app_svg_icon.dart
      const appSvgIconContent = '''import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvgIcon extends StatelessWidget {
  final String assetPath;
  final double? size;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const AppSvgIcon(
    this.assetPath, {
    super.key,
    this.size,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final double? iconWidth = width ?? size;
    final double? iconHeight = height ?? size;

    return SvgPicture.asset(
      assetPath,
      width: iconWidth,
      height: iconHeight,
      fit: fit,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
''';
      File('lib/shared/widgets/app_svg_icon.dart').writeAsStringSync(appSvgIconContent);
      expect(File('lib/shared/widgets/app_svg_icon.dart').existsSync(), isTrue);
    });
  });
}
