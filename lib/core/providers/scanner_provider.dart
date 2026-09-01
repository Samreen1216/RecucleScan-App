import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:recyclescan/core/services/barcode_lookup_service.dart';
import 'package:uuid/uuid.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:recyclescan/core/services/secure_storage_service.dart';

enum ScannerMode { aiVision, barcode }

class ScannerState {
  final ScannerMode mode;
  final bool isAnalyzing;
  final String? error;
  final ScanItem? result;

  const ScannerState({
    required this.mode,
    required this.isAnalyzing,
    this.error,
    this.result,
  });

  ScannerState copyWith({
    ScannerMode? mode,
    bool? isAnalyzing,
    String? error,
    ScanItem? result,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return ScannerState(
      mode: mode ?? this.mode,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: clearError ? null : (error ?? this.error),
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

class ScannerNotifier extends StateNotifier<ScannerState> {
  ScannerNotifier()
      : super(const ScannerState(mode: ScannerMode.aiVision, isAnalyzing: false));

  void setMode(ScannerMode mode) => state = state.copyWith(mode: mode);

  void reset() {
    state = const ScannerState(mode: ScannerMode.aiVision, isAnalyzing: false);
  }

  // ─────────────────────────────────────────────────────────
  // 1.  AI Vision (camera image) — Gemini first, MLKit fallback
  // ─────────────────────────────────────────────────────────
  Future<void> analyzeImage({required Uint8List bytes, required String imagePath}) async {
    if (state.isAnalyzing) return;
    state = state.copyWith(isAnalyzing: true, clearError: true, clearResult: true);

    // Try Gemini if we have a key
    final apiKey = await _loadApiKey();
    if (apiKey.isNotEmpty) {
      final success = await _tryGemini(bytes: bytes, apiKey: apiKey, imagePath: imagePath);
      if (success) return;
    }

    // Seamlessly fall back to on-device MLKit
    await _runMLKit(imagePath);
  }

  Future<String> _loadApiKey() async {
    return await SecureStorageService.getApiKey();
  }

  /// Returns true if Gemini succeeded and state was updated.
  Future<bool> _tryGemini({required Uint8List bytes, required String apiKey, required String imagePath}) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final prompt = TextPart('''
You are an expert recycling and computer vision assistant for RecycleScan.
Carefully inspect the image to identify the PRIMARY FOREGROUND SUBJECT that the user is aiming at (for example: painting, artwork, laptop, smartphone, chair, plastic bottle, aluminum can, apple, cardboard box, glass jar, battery, clothing, etc).
IMPORTANT: Ignore background walls, floors, or incidental room furniture if there is a specific focal object (e.g. if the user is pointing at a painting, wall art, canvas, or poster, identify the painting/artwork, NOT the chair or table in the room).

Return ONLY valid JSON matching this exact structure:
{
  "itemName": "Precise name of the object (e.g. Painting / Artwork, Laptop, Plastic Bottle, Aluminum Can)",
  "category": "ONE of: plastic | paper | glass | metal | general | ewaste | organic",
  "binName": "e.g. Paper & Cardboard Recycling Bin",
  "isRecyclable": true,
  "preparationSummary": "Clear 1-sentence disposal/recycling guidance"
}
Rules:
- Paintings/prints/drawings/paper → paper (or general if canvas/frame)
- Electronics/computers/phones/batteries/cables → ewaste
- Food/fruits/vegetables/plants/organic → organic
- Plastic bottles/tubs/containers → plastic
- Glass bottles/jars → glass
- Paper/cardboard/books/magazines → paper
- Metal cans/tins/foil/cutlery → metal
- Furniture/clothing/mixed-materials → general
''');
      final response = await model
          .generateContent([Content.multi([prompt, DataPart('image/jpeg', bytes)])]);
      final text = response.text?.trim() ?? '';
      final match = RegExp(r'\{[\s\S]*?\}').firstMatch(text);
      if (match == null) return false;
      final data = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      final categoryId = _normalizeCategory(data['category']?.toString() ?? '');
      state = state.copyWith(
        isAnalyzing: false,
        result: ScanItem(
          id: const Uuid().v4(),
          barcode: 'AI_VISION',
          name: data['itemName']?.toString().isNotEmpty == true
              ? data['itemName'].toString()
              : 'Scanned Item',
          brand: 'Gemini AI',
          categoryId: categoryId,
          timestamp: DateTime.now(),
          notes: data['preparationSummary']?.toString() ?? '',
          localImagePath: imagePath,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[Gemini] $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // 2.  MLKit on-device image labeling (OFFLINE, always works)
  // ─────────────────────────────────────────────────────────
  Future<void> _runMLKit(String imagePath) async {
    try {
      final options = ImageLabelerOptions(confidenceThreshold: 0.35);
      final labeler = ImageLabeler(options: options);
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await labeler.processImage(inputImage);
      await labeler.close();

      if (labels.isEmpty) {
        _emitSmartGeneric(imagePath);
        return;
      }

      // Sort labels by confidence descending
      final sortedLabels = List<ImageLabel>.from(labels)
        ..sort((a, b) => b.confidence.compareTo(a.confidence));

      final allText = sortedLabels.map((l) => l.label.toLowerCase()).join(' ');
      debugPrint('[MLKit] labels: $allText');

      final recognized = _classifyMLKitLabels(sortedLabels, allText);

      state = state.copyWith(
        isAnalyzing: false,
        result: ScanItem(
          id: const Uuid().v4(),
          barcode: 'MLKIT_VISION',
          name: recognized.name,
          brand: 'On-Device AI',
          categoryId: recognized.categoryId,
          timestamp: DateTime.now(),
          notes: recognized.notes,
          localImagePath: imagePath,
        ),
      );
    } catch (e) {
      debugPrint('[MLKit] error: $e');
      _emitSmartGeneric(imagePath);
    }
  }

  void _emitSmartGeneric(String? imagePath) {
    state = state.copyWith(
      isAnalyzing: false,
      result: ScanItem(
        id: const Uuid().v4(),
        barcode: 'VISION_GENERIC',
        name: 'Unrecognised Item',
        brand: 'AI Vision',
        categoryId: 'general',
        timestamp: DateTime.now(),
        notes: 'Could not identify the object with high confidence. When in doubt, place in general waste or check local council guidelines.',
        localImagePath: imagePath,
      ),
    );
  }

  _RecognitionResult _classifyMLKitLabels(List<ImageLabel> sortedLabels, String allText) {
    // 1. ART & PAINTINGS (High priority so paintings are not confused with background furniture)
    if (_anyOf(allText, [
      'painting', 'art', 'visual arts', 'modern art', 'artwork', 'picture frame',
      'drawing', 'sketch', 'canvas', 'acrylic paint', 'watercolor', 'portrait',
      'mural', 'illustration', 'poster', 'printmaking', 'paint'
    ])) {
      return const _RecognitionResult(
        name: 'Painting / Artwork',
        categoryId: 'paper',
        notes: 'Unframed paper art or prints can be recycled with paper. Framed art or canvas with wood/metal/glass frames should be donated or placed in general waste.',
      );
    }

    // 2. ELECTRONICS & E-WASTE
    if (_anyOf(allText, [
      'laptop', 'computer', 'personal computer', 'keyboard', 'computer keyboard',
      'computer mouse', 'mouse', 'smartphone', 'mobile phone', 'phone', 'cellphone',
      'tablet', 'ipad', 'television', 'tv', 'monitor', 'display', 'screen',
      'headphone', 'earphone', 'speaker', 'audio equipment', 'camera', 'digital camera',
      'printer', 'scanner', 'remote control', 'battery', 'charger', 'cable', 'wire',
      'circuit', 'electronic device', 'appliance', 'microwave', 'toaster', 'blender', 'kettle'
    ])) {
      String name = 'Electronic Device';
      if (_anyOf(allText, ['laptop', 'notebook'])) {
        name = 'Laptop';
      } else if (_anyOf(allText, ['smartphone', 'mobile phone', 'cellphone', 'phone'])) {
        name = 'Smartphone';
      } else if (_anyOf(allText, ['tablet', 'ipad'])) {
        name = 'Tablet Device';
      } else if (_anyOf(allText, ['keyboard'])) {
        name = 'Computer Keyboard';
      } else if (_anyOf(allText, ['mouse'])) {
        name = 'Computer Mouse';
      } else if (_anyOf(allText, ['television', 'tv', 'monitor', 'display'])) {
        name = 'Television / Monitor';
      } else if (_anyOf(allText, ['headphone', 'earphone', 'audio'])) {
        name = 'Headphones';
      } else if (_anyOf(allText, ['camera'])) {
        name = 'Camera';
      } else if (_anyOf(allText, ['printer', 'scanner'])) {
        name = 'Printer';
      } else if (_anyOf(allText, ['battery'])) {
        name = 'Battery (Hazardous E-Waste)';
      } else if (_anyOf(allText, ['charger', 'cable', 'wire'])) {
        name = 'Charging Cable / Adapter';
      }

      return _RecognitionResult(
        name: name,
        categoryId: 'ewaste',
        notes: _notesForCategory('ewaste'),
      );
    }

    // 3. ORGANIC / FOOD / PRODUCE
    if (_anyOf(allText, [
      'fruit', 'apple', 'banana', 'orange', 'citrus', 'vegetable', 'tomato',
      'potato', 'carrot', 'onion', 'pepper', 'berry', 'strawberry', 'grape',
      'produce', 'salad', 'bread', 'bakery', 'meat', 'fish', 'plant', 'leaf',
      'flower', 'tree', 'grass', 'coffee', 'tea', 'food', 'snack', 'mushroom',
      'avocado', 'watermelon', 'melon', 'pear', 'mango', 'peach', 'lemon'
    ])) {
      String name = 'Organic / Food Scrap';
      if (_anyOf(allText, ['apple'])) {
        name = 'Apple';
      } else if (_anyOf(allText, ['banana'])) {
        name = 'Banana';
      } else if (_anyOf(allText, ['orange', 'citrus'])) {
        name = 'Orange / Citrus';
      } else if (_anyOf(allText, ['fruit', 'berry'])) {
        name = 'Fresh Fruit';
      } else if (_anyOf(allText, ['vegetable', 'salad'])) {
        name = 'Vegetable';
      } else if (_anyOf(allText, ['plant', 'flower', 'leaf', 'tree'])) {
        name = 'Plant / Garden Organic';
      } else if (_anyOf(allText, ['bread', 'bakery'])) {
        name = 'Bread / Bakery Scrap';
      }

      return _RecognitionResult(
        name: name,
        categoryId: 'organic',
        notes: _notesForCategory('organic'),
      );
    }

    // 4. GLASS (Bottles & Jars)
    if (_anyOf(allText, [
      'wine bottle', 'beer bottle', 'glass bottle', 'mason jar', 'jar',
      'wine glass', 'drinking glass', 'perfume bottle', 'goblet'
    ]) || (allText.contains('glass') && !allText.contains('plastic') && !allText.contains('screen'))) {
      String name = 'Glass Bottle / Jar';
      if (_anyOf(allText, ['wine bottle'])) {
        name = 'Wine Bottle';
      } else if (_anyOf(allText, ['beer bottle'])) {
        name = 'Beer Bottle';
      } else if (_anyOf(allText, ['jar', 'mason jar'])) {
        name = 'Glass Jar';
      } else if (_anyOf(allText, ['glass bottle'])) {
        name = 'Glass Bottle';
      }

      return _RecognitionResult(
        name: name,
        categoryId: 'glass',
        notes: _notesForCategory('glass'),
      );
    }

    // 5. METAL (Cans, Foil, Tins, Cutlery)
    if (_anyOf(allText, [
      'can', 'aluminum can', 'tin can', 'beverage can', 'tin', 'aluminium',
      'aluminum', 'steel', 'spoon', 'fork', 'knife', 'cutlery', 'utensil',
      'foil', 'aluminum foil', 'pan', 'pot', 'aerosol'
    ])) {
      String name = 'Metal Item';
      if (_anyOf(allText, ['aluminum can', 'beverage can', 'can'])) {
        name = 'Aluminum Can';
      } else if (_anyOf(allText, ['tin can', 'tin'])) {
        name = 'Food Tin / Can';
      } else if (_anyOf(allText, ['cutlery', 'spoon', 'fork', 'knife'])) {
        name = 'Metal Cutlery';
      } else if (_anyOf(allText, ['foil'])) {
        name = 'Aluminum Foil';
      }

      return _RecognitionResult(
        name: name,
        categoryId: 'metal',
        notes: _notesForCategory('metal'),
      );
    }

    // 6. PLASTIC (Bottles, Jugs, Packaging)
    if (_anyOf(allText, [
      'water bottle', 'plastic bottle', 'bottle', 'jug', 'tub', 'plastic container',
      'plastic bag', 'wrapper', 'packaging', 'polystyrene', 'foam', 'plastic cup',
      'lid', 'shampoo', 'lotion', 'detergent', 'plastic'
    ])) {
      String name = 'Plastic Container';
      if (_anyOf(allText, ['water bottle', 'plastic bottle', 'bottle'])) {
        name = 'Plastic Bottle';
      } else if (_anyOf(allText, ['plastic bag', 'wrapper', 'packaging'])) {
        name = 'Plastic Packaging';
      } else if (_anyOf(allText, ['shampoo', 'lotion', 'detergent'])) {
        name = 'Plastic Bottle (Toiletry/Cleaner)';
      }

      return _RecognitionResult(
        name: name,
        categoryId: 'plastic',
        notes: _notesForCategory('plastic'),
      );
    }

    // 7. PAPER & CARDBOARD (Boxes, Books, Stationery)
    if (_anyOf(allText, [
      'cardboard', 'cardboard box', 'box', 'carton', 'book', 'publication',
      'newspaper', 'magazine', 'notebook', 'document', 'envelope', 'receipt',
      'paper bag', 'tissue', 'stationery', 'paper'
    ])) {
      String name = 'Paper / Cardboard';
      if (_anyOf(allText, ['cardboard', 'box', 'carton'])) {
        name = 'Cardboard Box';
      } else if (_anyOf(allText, ['book', 'publication'])) {
        name = 'Book';
      } else if (_anyOf(allText, ['newspaper', 'magazine'])) {
        name = 'Newspaper / Magazine';
      } else if (_anyOf(allText, ['notebook', 'document', 'stationery'])) {
        name = 'Paper Document / Notebook';
      }

      return _RecognitionResult(
        name: name,
        categoryId: 'paper',
        notes: _notesForCategory('paper'),
      );
    }

    // 8. FURNITURE & TEXTILES (General Waste / Reuse)
    if (_anyOf(allText, [
      'chair', 'table', 'desk', 'couch', 'sofa', 'bed', 'wardrobe', 'cabinet',
      'rug', 'carpet', 'pillow', 'clothing', 'shirt', 'pants', 'shoe', 'shoes',
      'footwear', 'textile', 'bag', 'backpack', 'toy', 'furniture'
    ])) {
      String name = 'Household Item / Furniture';
      if (_anyOf(allText, ['chair'])) {
        name = 'Chair';
      } else if (_anyOf(allText, ['table', 'desk'])) {
        name = 'Table / Desk';
      } else if (_anyOf(allText, ['clothing', 'shirt', 'pants', 'shoe', 'textile'])) {
        name = 'Clothing / Textile';
      }

      return _RecognitionResult(
        name: name,
        categoryId: 'general',
        notes: 'Consider donating or selling if in reusable condition. Otherwise, dispose of as general household waste or bulky council collection.',
      );
    }

    // Fallback using first clean non-generic label
    const ignoreLabels = {
      'room', 'indoor', 'outdoor', 'wall', 'floor', 'flooring', 'ceiling',
      'lighting', 'light', 'interior design', 'shadow', 'snapshot', 'photography',
      'comfort', 'hand', 'finger', 'arm', 'person', 'body', 'wood', 'surface', 'material'
    };


    String selectedLabel = 'Unrecognised Item';
    for (final l in sortedLabels) {
      if (!ignoreLabels.contains(l.label.toLowerCase())) {
        selectedLabel = l.label;
        break;
      }
    }

    return _RecognitionResult(
      name: _humanLabel(selectedLabel),
      categoryId: 'general',
      notes: 'This item may not be standard recyclable waste. Check local council guidelines or dispose in general waste.',
    );
  }

  bool _anyOf(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  String _notesForCategory(String cat) {
    switch (cat) {
      case 'ewaste':
        return 'Electronic waste — do not put in regular bins. Take to an e-waste drop-off centre. Wipe your personal data before recycling.';
      case 'organic':
        return 'Organic / food waste — compost if possible, or place in your local green/food waste bin.';
      case 'plastic':
        return 'Rinse clean, crush to save space, and place in the plastic recycling bin. Remove lids if different material.';
      case 'glass':
        return 'Rinse the container. Remove lids. Place in glass recycling. Handle broken glass with care.';
      case 'paper':
        return 'Keep dry. Flatten cardboard. Remove plastic tape and place in paper/cardboard recycling.';
      case 'metal':
        return 'Rinse cans. Clean foil. Place in metal recycling bin. Never put aerosol cans with residue in the bin.';
      default:
        return 'This item may not be recyclable. Consider donating if in good condition, or place in general waste.';
    }
  }

  String _humanLabel(String rawLabel) {
    return rawLabel
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _normalizeCategory(String raw) {
    const valid = {'plastic', 'paper', 'glass', 'metal', 'general', 'ewaste', 'organic'};
    final lower = raw.toLowerCase().trim();
    if (valid.contains(lower)) return lower;
    if (lower.contains('electronic') || lower.contains('e-waste')) return 'ewaste';
    if (lower.contains('organic') || lower.contains('food')) return 'organic';
    if (lower.contains('plastic')) return 'plastic';
    if (lower.contains('glass')) return 'glass';
    if (lower.contains('paper') || lower.contains('card')) return 'paper';
    if (lower.contains('metal') || lower.contains('tin') || lower.contains('alum')) return 'metal';
    return 'general';
  }

  // ─────────────────────────────────────────────────────────
  // 3.  Barcode mode — look up in database → smart AI fallback
  // ─────────────────────────────────────────────────────────
  Future<void> analyzeBarcode(String barcode,
      {Uint8List? imageBytes, String? imagePath}) async {
    if (state.isAnalyzing) return;
    state = state.copyWith(isAnalyzing: true, clearError: true, clearResult: true);
    await Future.delayed(const Duration(milliseconds: 300));

    final found = BarcodeLookupService.lookupBarcode(barcode);
    if (found != null) {
      final itemWithImage = imagePath != null 
          ? found.copyWith(localImagePath: imagePath)
          : found;
      state = state.copyWith(isAnalyzing: false, result: itemWithImage);
      return;
    }

    // Barcode NOT in database — smart fallback:
    // 1. Try AI Vision on the camera frame if image is available
    if (imagePath != null) {
      await _runMLKit(imagePath);
      // Override the name to include barcode info
      if (state.result != null) {
        final enhanced = ScanItem(
          id: state.result!.id,
          barcode: barcode,
          name: state.result!.name,
          brand: 'AI Vision (Barcode: $barcode)',
          categoryId: state.result!.categoryId,
          timestamp: state.result!.timestamp,
          notes: state.result!.notes,
          localImagePath: state.result!.localImagePath,
        );
        state = state.copyWith(result: enhanced);
      }
      return;
    }

    // 2. No image — show the manual category picker
    state = state.copyWith(isAnalyzing: false, error: 'NOT_FOUND:$barcode');
  }

  // ─────────────────────────────────────────────────────────
  // 4.  Demo sample chips
  // ─────────────────────────────────────────────────────────
  Future<void> analyzeSample(String sampleName) async {
    state = state.copyWith(isAnalyzing: true, clearError: true, clearResult: true);
    await Future.delayed(const Duration(seconds: 1));
    _handleMockFallback(sampleName);
  }

  void _handleMockFallback(String itemType) {
    final id = const Uuid().v4();
    final now = DateTime.now();

    final mocks = <String, ScanItem>{
      'PET Bottle': ScanItem(id: id, barcode: 'MOCK_PET', name: 'Clear PET Beverage Bottle', brand: 'Generic', categoryId: 'plastic', timestamp: now, notes: 'Empty, crush, and place in plastic recycling. Resin code #1 PETE.'),
      'Pizza Box': ScanItem(id: id, barcode: 'MOCK_PIZZA', name: 'Cardboard Pizza Box', brand: 'Generic', categoryId: 'paper', timestamp: now, notes: 'Tear off greasy parts → general waste. Recycle the clean lid separately.'),
      'Aluminum Can': ScanItem(id: id, barcode: 'MOCK_CAN', name: 'Aluminium Soda Can', brand: 'Generic', categoryId: 'metal', timestamp: now, notes: 'Rinse lightly. Do not crush if local facility uses automated sorters.'),
      'Lithium Battery': ScanItem(id: id, barcode: 'MOCK_BATTERY', name: 'Lithium-ion Battery', brand: 'Generic', categoryId: 'ewaste', timestamp: now, notes: '⚠️ FIRE HAZARD. Never bin. Take to e-waste drop-off point.'),
      'Glass Jar': ScanItem(id: id, barcode: 'MOCK_GLASS', name: 'Glass Food Jar', brand: 'Generic', categoryId: 'glass', timestamp: now, notes: 'Rinse out food residue. Metal lid can be recycled separately.'),
      'Banana Peel': ScanItem(id: id, barcode: 'MOCK_ORGANIC', name: 'Banana Peel', brand: 'Generic', categoryId: 'organic', timestamp: now, notes: 'Fully compostable. Place in green bin or home compost pile.'),
      'Cardboard Box': ScanItem(id: id, barcode: 'MOCK_CARD', name: 'Cardboard Box', brand: 'Generic', categoryId: 'paper', timestamp: now, notes: 'Flatten before recycling. Remove any plastic tape.'),
      'Coffee Cup': ScanItem(id: id, barcode: 'MOCK_COFFEE', name: 'Paper Coffee Cup', brand: 'Generic', categoryId: 'general', timestamp: now, notes: 'Usually plastic-lined — general waste unless marked compostable.'),
    };

    for (final key in mocks.keys) {
      if (itemType.contains(key)) {
        state = state.copyWith(isAnalyzing: false, result: mocks[key]);
        return;
      }
    }

    // Unknown sample — still show something useful
    state = state.copyWith(
      isAnalyzing: false,
      result: ScanItem(
        id: id,
        barcode: 'MOCK_GENERIC',
        name: itemType,
        brand: 'Demo',
        categoryId: 'general',
        timestamp: now,
        notes: 'When unsure, check local guidelines. Reduce → Reuse → Recycle.',
      ),
    );
  }
}

final scannerProvider =
    StateNotifierProvider<ScannerNotifier, ScannerState>((ref) => ScannerNotifier());

class _RecognitionResult {
  final String name;
  final String categoryId;
  final String notes;

  const _RecognitionResult({
    required this.name,
    required this.categoryId,
    required this.notes,
  });
}
