import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:recyclescan/core/services/barcode_lookup_service.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('gemini_api_key') ?? '';
      if (saved.isNotEmpty) return saved;
    } catch (_) {}
    return const String.fromEnvironment('AI_VISION_API_KEY');
  }

  /// Returns true if Gemini succeeded and state was updated.
  Future<bool> _tryGemini({required Uint8List bytes, required String apiKey, required String imagePath}) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final prompt = TextPart('''
Analyze the image. Identify the primary object accurately (laptop, apple, plastic bottle, spoon, etc).
Return ONLY valid JSON – no markdown, no explanation:
{
  "itemName": "specific object name",
  "category": "ONE of: plastic | paper | glass | metal | general | ewaste | organic",
  "binName": "correct disposal bin name",
  "isRecyclable": true_or_false,
  "preparationSummary": "brief disposal/recycling/composting instruction"
}
Rules:
- Electronics/devices → ewaste
- Food/fruit/veg/meat/plants → organic
- Plastic packaging/bottles → plastic
- Glass jars/bottles → glass
- Paper/cardboard → paper
- Metal cans/cutlery → metal
- Clothing/furniture (if reusable) → general (note to donate)
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
      // Use higher confidence threshold so it returns more accurate results
      final options = ImageLabelerOptions(confidenceThreshold: 0.65);
      final labeler = ImageLabeler(options: options);
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await labeler.processImage(inputImage);
      await labeler.close();

      if (labels.isEmpty) {
        // Absolute last resort — smart generic result
        _emitSmartGeneric();
        return;
      }

      // Gather all labels for richer matching
      final allText = labels.map((l) => l.label.toLowerCase()).join(' ');
      debugPrint('[MLKit] labels: $allText');

      final category = _mlkitCategoryFromLabels(allText);
      final notes = _notesForCategory(category);
      
      const ignoreLabels = {'hand', 'finger', 'arm', 'wall', 'floor', 'room', 'ceiling', 'poster', 'person', 'table', 'desk', 'background', 'indoor', 'outdoor', 'wood', 'glass', 'plastic', 'metal', 'paper'};
      String selectedLabel = labels.first.label;
      for (final l in labels) {
        if (!ignoreLabels.contains(l.label.toLowerCase())) {
          selectedLabel = l.label;
          break;
        }
      }
      
      final bestLabel = _humanLabel(selectedLabel);

      state = state.copyWith(
        isAnalyzing: false,
        result: ScanItem(
          id: const Uuid().v4(),
          barcode: 'MLKIT_VISION',
          name: bestLabel,
          brand: 'On-Device AI',
          categoryId: category,
          timestamp: DateTime.now(),
          notes: notes,
          localImagePath: imagePath,
        ),
      );
    } catch (e) {
      debugPrint('[MLKit] $e');
      // Still show something useful instead of an error
      _emitSmartGeneric();
    }
  }

  void _emitSmartGeneric() {
    state = state.copyWith(
      isAnalyzing: false,
      result: ScanItem(
        id: const Uuid().v4(),
        barcode: 'VISION_GENERIC',
        name: 'Unrecognised Item',
        brand: 'AI Vision',
        categoryId: 'general',
        timestamp: DateTime.now(),
        notes: 'Could not identify the object. When in doubt, place in general waste.',
      ),
    );
  }

  String _mlkitCategoryFromLabels(String allLabels) {
    // E-Waste
    if (_anyOf(allLabels, ['computer', 'laptop', 'phone', 'smartphone', 'tablet',
        'keyboard', 'television', 'monitor', 'electronic', 'circuit', 'battery',
        'charger', 'cable', 'camera', 'headphone', 'printer', 'mouse pad'])) {
      return 'ewaste';
    }
    // Organic
    if (_anyOf(allLabels, ['fruit', 'vegetable', 'food', 'plant', 'leaf', 'grass',
        'apple', 'banana', 'orange', 'meat', 'fish', 'flower', 'tree', 'produce',
        'salad', 'bread', 'mushroom', 'berry', 'pear', 'mango', 'potato', 'pepper'])) {
      return 'organic';
    }
    // Glass
    if (_anyOf(allLabels, ['glass', 'bottle', 'jar', 'wine', 'beer', 'drinking'])) {
      // Make sure it's actually glass, not plastic bottle
      if (!allLabels.contains('plastic') && !allLabels.contains('water bottle')) {
        return 'glass';
      }
    }
    // Plastic
    if (_anyOf(allLabels, ['plastic', 'water bottle', 'jug', 'container', 'bag',
        'packaging', 'wrapper', 'polystyrene', 'foam'])) {
      return 'plastic';
    }
    // Paper
    if (_anyOf(allLabels, ['paper', 'cardboard', 'box', 'book', 'newspaper',
        'document', 'magazine', 'envelope', 'notebook'])) {
      return 'paper';
    }
    // Metal
    if (_anyOf(allLabels, ['metal', 'can', 'tin', 'aluminium', 'aluminum', 'steel',
        'spoon', 'fork', 'knife', 'cutlery', 'utensil', 'iron', 'copper', 'silver'])) {
      return 'metal';
    }
    return 'general';
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
    // MLKit returns labels like "Laptop computer" — just capitalise properly
    return rawLabel
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _normalizeCategory(String raw) {
    const valid = {'plastic', 'paper', 'glass', 'metal', 'general', 'ewaste', 'organic'};
    final lower = raw.toLowerCase().trim();
    if (valid.contains(lower)) return lower;
    // Try common aliases
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
