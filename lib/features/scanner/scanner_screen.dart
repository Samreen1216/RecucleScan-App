import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/providers/scanner_provider.dart';
import 'package:recyclescan/core/services/barcode_lookup_service.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── Camera ──
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIdx = 0;
  bool _isCameraInitialized = false;
  bool _isSwitchingCamera = false;
  bool _isStreaming = false;

  // ── Animation ──
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;

  // ── MLKit Barcode & Throttling ──
  late final BarcodeScanner _barcodeScanner;
  bool _isProcessingFrame = false;
  DateTime _lastFrameTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _minFrameIntervalMs = 250; // Throttle to max 4 frames per sec
  String? _lastDetectedBarcode;

  // ── Gallery ──
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _barcodeScanner = BarcodeScanner();
    _initCamera();

    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopStreamSafely();
      controller.dispose();
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras.isNotEmpty) {
        _setCamera(_cameras[_selectedCameraIdx]);
      }
    }
  }

  // ── Camera initialization ──
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty && mounted) {
        await _setCamera(_cameras[_selectedCameraIdx]);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _setCamera(CameraDescription desc) async {
    if (!mounted) return;
    setState(() => _isCameraInitialized = false);

    // 1. Safely stop any running image stream
    await _stopStreamSafely();

    // 2. Completely dispose old controller before initializing a new one (prevents camera hardware HAL locks)
    final oldCtrl = _cameraController;
    _cameraController = null;
    try {
      await oldCtrl?.dispose();
    } catch (e) {
      debugPrint('Error disposing old camera controller: $e');
    }

    // 3. Create and initialize new controller
    final ctrl = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      _cameraController = ctrl;
      setState(() => _isCameraInitialized = true);

      // 4. If in barcode mode, start stream safely
      if (ref.read(scannerProvider).mode == ScannerMode.barcode) {
        await _startStreamSafely();
      }
    } catch (e) {
      debugPrint('Camera setup error: $e');
      if (mounted) setState(() => _isCameraInitialized = false);
    }
  }

  bool get _isFrontCamera {
    if (_cameras.isEmpty || _selectedCameraIdx >= _cameras.length) return false;
    return _cameras[_selectedCameraIdx].lensDirection == CameraLensDirection.front;
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2 || _isSwitchingCamera) return;
    _isSwitchingCamera = true;
    try {
      final nextIdx = (_selectedCameraIdx + 1) % _cameras.length;
      await _setCamera(_cameras[nextIdx]);
      _selectedCameraIdx = nextIdx;
    } finally {
      _isSwitchingCamera = false;
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized || _isFrontCamera) return;
    try {
      final cur = _cameraController!.value.flashMode;
      await _cameraController!.setFlashMode(
        cur == FlashMode.torch ? FlashMode.off : FlashMode.torch,
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Toggle flash error: $e');
    }
  }

  // ── Safe Image Stream Management ──
  Future<void> _startStreamSafely() async {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized || _isStreaming) return;
    try {
      _isStreaming = true;
      await ctrl.startImageStream(_processCameraFrame);
    } catch (e) {
      _isStreaming = false;
      debugPrint('Error starting image stream: $e');
    }
  }

  Future<void> _stopStreamSafely() async {
    final ctrl = _cameraController;
    if (ctrl == null || !_isStreaming) return;
    _isStreaming = false;
    try {
      if (ctrl.value.isStreamingImages) {
        await ctrl.stopImageStream();
      }
    } catch (e) {
      debugPrint('Error stopping image stream: $e');
    }
  }

  // ── Live barcode frame processing (throttled & non-blocking) ──
  Future<void> _processCameraFrame(CameraImage image) async {
    final now = DateTime.now();
    if (now.difference(_lastFrameTime).inMilliseconds < _minFrameIntervalMs) {
      return; // Skip frame to avoid saturating ML thread pool
    }

    if (_isProcessingFrame || !mounted) return;
    if (_cameraController == null || !_isCameraInitialized) return;
    if (ref.read(scannerProvider).isAnalyzing) return;
    if (ref.read(scannerProvider).mode != ScannerMode.barcode) return;

    _isProcessingFrame = true;
    _lastFrameTime = now;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }

      if (_cameras.isEmpty || _selectedCameraIdx >= _cameras.length) return;
      final camera = _cameras[_selectedCameraIdx];
      final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      final inputImage = InputImage.fromBytes(
        bytes: allBytes.done().buffer.asUint8List(),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: Platform.isAndroid
              ? InputImageFormat.nv21
              : InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty && mounted && ref.read(scannerProvider).mode == ScannerMode.barcode) {
        final code = barcodes.first.rawValue;
        if (code != null && code.trim().isNotEmpty && code.trim() != _lastDetectedBarcode) {
          _lastDetectedBarcode = code.trim();
          HapticFeedback.mediumImpact();

          // Safely analyze barcode with priority local database matching
          ref.read(scannerProvider.notifier).analyzeBarcode(code.trim());
        }
      }
    } catch (e) {
      debugPrint('Frame processing: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  // ── Shutter pressed (AI Vision mode) ──
  Future<void> _captureImage() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    if (_cameraController!.value.isTakingPicture) return;
    if (ref.read(scannerProvider).isAnalyzing) return;

    // Stop any stream before capture
    await _stopStreamSafely();

    try {
      HapticFeedback.mediumImpact();
      final XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      ref.read(scannerProvider.notifier).analyzeImage(bytes: bytes, imagePath: file.path);
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  // ── Gallery pick (AI Vision mode) ──
  Future<void> _pickGalleryImage() async {
    if (ref.read(scannerProvider).isAnalyzing) return;
    try {
      final XFile? file =
          await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file != null) {
        final bytes = await file.readAsBytes();
        ref.read(scannerProvider.notifier)
            .analyzeImage(bytes: bytes, imagePath: file.path);
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopStreamSafely();
    _cameraController?.dispose();
    _scanLineCtrl.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  // ── Navigation / error handling ──
  void _handleStateChange(ScannerState? prev, ScannerState next) {
    if (!mounted) return;

    if (next.result != null && prev?.result != next.result) {
      _lastDetectedBarcode = null;
      context.push('/result/${next.result!.id}', extra: next.result);
      Future.microtask(() => ref.read(scannerProvider.notifier).reset());
      return;
    }

    if (next.error != null && prev?.error != next.error) {
      if (next.error!.startsWith('NOT_FOUND:')) {
        final barcode = next.error!.replaceFirst('NOT_FOUND:', '');
        _lastDetectedBarcode = null;
        _showNotFoundSheet(barcode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ));
      }
      Future.microtask(() => ref.read(scannerProvider.notifier).reset());
    }
  }

  Future<void> _showNotFoundSheet(String barcode) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text('🔍', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            const Text(
              'Product Not in Database',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Barcode: $barcode',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the correct category manually:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
              children: RecyclingData.categories.map((cat) {
                return GestureDetector(
                  onTap: () {
                    final item = BarcodeLookupService.createManualItem(
                        barcode: barcode, categoryId: cat.id, name: 'Scanned Product');
                    Navigator.of(ctx).pop();
                    context.push('/result/${item.id}', extra: item);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cat.lightColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cat.color.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            cat.imageAsset,
                            width: 16,
                            height: 16,
                            cacheWidth: 40,
                            cacheHeight: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(cat.name,
                            style: TextStyle(
                                color: cat.color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scannerProvider);
    final size = MediaQuery.of(context).size;

    ref.listen<ScannerState>(scannerProvider, (prev, next) => _handleStateChange(prev, next));

    const boxSize = 270.0;
    final boxTop = (size.height - boxSize) / 2 - 40;
    final boxLeft = (size.width - boxSize) / 2;

    final flashMode = _cameraController?.value.flashMode ?? FlashMode.off;
    final isTorchOn = flashMode == FlashMode.torch;
    final isBarcodeMode = state.mode == ScannerMode.barcode;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 1. Camera Preview ──
          SizedBox.expand(
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E2124), Color(0xFF111214)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 64),
                          SizedBox(height: 12),
                          Text('Starting camera…', style: TextStyle(color: Colors.white38)),
                        ],
                      ),
                    ),
                  ),
          ),

          // ── 2. Dark overlay with scan hole ──
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanOverlayPainter(
                  boxLeft: boxLeft, boxTop: boxTop, boxSize: boxSize),
            ),
          ),

          // ── 3. Animated laser line ──
          AnimatedBuilder(
            animation: _scanLineAnim,
            builder: (context, _) => Positioned(
              left: boxLeft + 12,
              top: boxTop + _scanLineAnim.value * (boxSize - 6),
              child: Container(
                width: boxSize - 24,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.mintGreen,
                      AppColors.mintGreen,
                      Colors.transparent
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.mintGreen.withValues(alpha: 0.7),
                        blurRadius: 6,
                        spreadRadius: 1)
                  ],
                ),
              ),
            ),
          ),

          // ── 4. Corner brackets ──
          ..._buildCorners(boxLeft, boxTop, boxSize),

          // ── 5. Helper label ──
          Positioned(
            top: boxTop - 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isBarcodeMode
                      ? 'Point at a barcode — auto-detects!'
                      : 'Align item in frame, then tap 📷',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),

          // ── 6. Top header bar ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleButton(
                        icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                    // Mode pill
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ModePill(
                            title: '🤖 AI Vision',
                            isActive: !isBarcodeMode,
                            onTap: () async {
                              ref
                                  .read(scannerProvider.notifier)
                                  .setMode(ScannerMode.aiVision);
                              await _stopStreamSafely();
                            },
                          ),
                          _ModePill(
                            title: '📷 Barcode',
                            isActive: isBarcodeMode,
                            onTap: () async {
                              ref
                                  .read(scannerProvider.notifier)
                                  .setMode(ScannerMode.barcode);
                              _lastDetectedBarcode = null;
                              await _startStreamSafely();
                            },
                          ),
                        ],
                      ),
                    ),
                    if (!_isFrontCamera)
                      _CircleButton(
                        icon: isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: isTorchOn ? AppColors.amber : null,
                        onTap: _toggleFlash,
                      )
                    else
                      const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
          ),

          // ── 7. Bottom controls ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 32, top: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sample chips (only in AI Vision mode)
                  if (!isBarcodeMode)
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _SampleChip(label: '🥤 PET Bottle', onTap: () => ref.read(scannerProvider.notifier).analyzeSample('PET Bottle')),
                          _SampleChip(label: '🍕 Pizza Box', onTap: () => ref.read(scannerProvider.notifier).analyzeSample('Pizza Box')),
                          _SampleChip(label: '🥫 Alum Can', onTap: () => ref.read(scannerProvider.notifier).analyzeSample('Aluminum Can')),
                          _SampleChip(label: '🔋 Battery', onTap: () => ref.read(scannerProvider.notifier).analyzeSample('Lithium Battery')),
                          _SampleChip(label: '🫙 Glass Jar', onTap: () => ref.read(scannerProvider.notifier).analyzeSample('Glass Jar')),
                          _SampleChip(label: '🍌 Banana', onTap: () => ref.read(scannerProvider.notifier).analyzeSample('Banana Peel')),
                          _SampleChip(label: '📦 Cardboard', onTap: () => ref.read(scannerProvider.notifier).analyzeSample('Cardboard Box')),
                          _SampleChip(label: '☕ Coffee Cup', onTap: () => ref.read(scannerProvider.notifier).analyzeSample('Coffee Cup')),
                        ],
                      ),
                    ),
                  if (isBarcodeMode)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Auto-scanning… Point camera at any product barcode.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Control row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery
                      IconButton(
                        onPressed: isBarcodeMode ? null : _pickGalleryImage,
                        icon: Icon(
                          Icons.photo_library_rounded,
                          color: isBarcodeMode ? Colors.white24 : Colors.white,
                          size: 28,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),

                      // Shutter / auto-badge
                      GestureDetector(
                        onTap: isBarcodeMode ? null : _captureImage,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: isBarcodeMode
                                    ? AppColors.amber.withValues(alpha: 0.5)
                                    : AppColors.primaryGreen.withValues(alpha: 0.6),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isBarcodeMode
                                    ? AppColors.amber.withValues(alpha: 0.7)
                                    : AppColors.primaryGreen,
                              ),
                              child: Icon(
                                isBarcodeMode
                                    ? Icons.qr_code_scanner
                                    : Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Flip Camera
                      IconButton(
                        onPressed: _toggleCamera,
                        icon: const Icon(Icons.flip_camera_ios_rounded,
                            color: Colors.white, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── 8. Analyzing overlay ──
          if (state.isAnalyzing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 52, height: 52,
                          child: CircularProgressIndicator(
                              color: AppColors.primaryGreen, strokeWidth: 4),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isBarcodeMode
                              ? '🔍 Looking up product…'
                              : '🤖 Identifying object…',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isBarcodeMode
                              ? 'Checking product database'
                              : 'Running on-device AI',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners(double boxLeft, double boxTop, double boxSize) {
    const cLen = 26.0;
    const cW = 4.0;
    const col = AppColors.mintGreen;

    Widget bracket({bool top = false, bool left = false}) {
      return Positioned(
        left: left ? boxLeft - 1 : null,
        right: left
            ? null
            : MediaQuery.of(context).size.width - boxLeft - boxSize - 1,
        top: top ? boxTop - 1 : null,
        bottom: top
            ? null
            : MediaQuery.of(context).size.height - boxTop - boxSize - 1,
        child: SizedBox(
          width: cLen, height: cLen,
          child: CustomPaint(
            painter: _CornerPainter(
              topLeft: top && left,
              topRight: top && !left,
              bottomLeft: !top && left,
              bottomRight: !top && !left,
              color: col,
              strokeWidth: cW,
            ),
          ),
        ),
      );
    }

    return [
      bracket(top: true, left: true),
      bracket(top: true, left: false),
      bracket(top: false, left: true),
      bracket(top: false, left: false),
    ];
  }
}

// ─────────────── Painters / Helpers ───────────────

class _ScanOverlayPainter extends CustomPainter {
  final double boxLeft, boxTop, boxSize;
  const _ScanOverlayPainter(
      {required this.boxLeft, required this.boxTop, required this.boxSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final scanRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, boxTop, boxSize, boxSize),
        const Radius.circular(16));
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(scanRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
    canvas.drawRRect(
        scanRect,
        Paint()
          ..color = AppColors.mintGreen.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) =>
      old.boxLeft != boxLeft || old.boxTop != boxTop || old.boxSize != boxSize;
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  final Color color;
  final double strokeWidth;
  const _CornerPainter(
      {required this.topLeft,
      required this.topRight,
      required this.bottomLeft,
      required this.bottomRight,
      required this.color,
      required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;
    if (topLeft) {
      canvas.drawLine(Offset(0, h), const Offset(0, 0), p);
      canvas.drawLine(const Offset(0, 0), Offset(w, 0), p);
    }
    if (topRight) {
      canvas.drawLine(const Offset(0, 0), Offset(w, 0), p);
      canvas.drawLine(Offset(w, 0), Offset(w, h), p);
    }
    if (bottomLeft) {
      canvas.drawLine(const Offset(0, 0), Offset(0, h), p);
      canvas.drawLine(Offset(0, h), Offset(w, h), p);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(w, 0), Offset(w, h), p);
      canvas.drawLine(Offset(w, h), Offset(0, h), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _CircleButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color ?? Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );
}

class _ModePill extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  const _ModePill({required this.title, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
}

class _SampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SampleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          label: Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
          onPressed: onTap,
        ),
      );
}

