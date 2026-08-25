import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/services/barcode_lookup_service.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;

  bool _isProcessing = false;
  bool _torchOn = false;
  bool _paused = false;
  String? _lastScannedValue;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );

    // Explicitly start the controller
    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      await _controller.start();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error starting camera: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _scanLineCtrl.repeat(reverse: true);
        if (!_paused && !_isProcessing) {
          _startCamera();
        }
      case AppLifecycleState.inactive:
        _scanLineCtrl.stop();
        _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scanLineCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing || _paused) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    if (rawValue == _lastScannedValue) return;
    _lastScannedValue = rawValue;

    setState(() => _isProcessing = true);
    _paused = true;
    await _controller.stop();

    HapticFeedback.mediumImpact();
    await _processBarcode(rawValue);
  }

  Future<void> _processBarcode(String rawValue) async {
    final found = BarcodeLookupService.lookupBarcode(rawValue);

    if (!mounted) return;

    if (found != null) {
      await context.push('/result', extra: found);
    } else {
      await _showNotFoundSheet(rawValue);
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _lastScannedValue = null;
      });
      _paused = false;
      await _startCamera();
    }
  }

  Future<void> _manualScan() async {
    if (_isProcessing) return;
    HapticFeedback.lightImpact();
    await _controller.stop();
    await Future.delayed(const Duration(milliseconds: 150));
    await _startCamera();
    setState(() {});
  }

  Future<void> _showNotFoundSheet(String barcode) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotFoundSheet(
        barcode: barcode,
        onCategorySelected: (categoryId) {
          final item = BarcodeLookupService.createManualItem(
            barcode: barcode,
            categoryId: categoryId,
          );
          Navigator.of(ctx).pop();
          context.push('/result', extra: item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const boxSize = 270.0;
    final boxTop = (size.height - boxSize) / 2 - 40;
    final boxLeft = (size.width - boxSize) / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _handleDetection,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          'Camera Error\n${error.errorCode.name}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please ensure you have granted camera permissions.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _startCamera,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (!_isCameraInitialized)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.mintGreen),
                ),
              ),
            ),

          Positioned.fill(
            child: CustomPaint(
              painter: _ScanOverlayPainter(
                boxLeft: boxLeft,
                boxTop: boxTop,
                boxSize: boxSize,
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _scanLineAnim,
            builder: (context, _) {
              return Positioned(
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
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mintGreen.withValues(alpha: 0.7),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          ..._buildCorners(boxLeft, boxTop, boxSize),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Scan Item',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  _CircleButton(
                    icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                    color: _torchOn ? AppColors.amber : null,
                    onTap: () {
                      _controller.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: boxTop - 44,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Point camera at a barcode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isProcessing
                          ? const Text(
                              '🔍 Searching product...',
                              key: ValueKey('searching'),
                              style: TextStyle(
                                color: AppColors.mintGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : const Text(
                              'Hold steady for auto-scan, or press the button',
                              key: ValueKey('hint'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _isProcessing ? null : _manualScan,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: _isProcessing
                              ? const LinearGradient(
                                  colors: [Color(0xFF555555), Color(0xFF444444)],
                                )
                              : const LinearGradient(
                                  colors: [
                                    AppColors.primaryGreen,
                                    AppColors.primaryMedium,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: _isProcessing
                              ? []
                              : [
                                  BoxShadow(
                                    color: AppColors.primaryGreen.withValues(alpha: 0.45),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isProcessing
                                  ? Icons.hourglass_top_rounded
                                  : Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isProcessing ? 'Scanning...' : 'Press to Scan',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _isProcessing ? null : () => _showNotFoundSheet('MANUAL'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Select category manually',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners(double boxLeft, double boxTop, double boxSize) {
    const cornerLen = 26.0;
    const cornerWidth = 4.0;
    const color = AppColors.mintGreen;
    const r = Radius.circular(4);

    Widget bracket({bool top = false, bool left = false}) {
      return Positioned(
        left: left ? boxLeft - 1 : null,
        right: left ? null : MediaQuery.of(context).size.width - boxLeft - boxSize - 1,
        top: top ? boxTop - 1 : null,
        bottom: top ? null : MediaQuery.of(context).size.height - boxTop - boxSize - 1,
        child: SizedBox(
          width: cornerLen,
          height: cornerLen,
          child: CustomPaint(
            painter: _CornerPainter(
              topLeft: top && left,
              topRight: top && !left,
              bottomLeft: !top && left,
              bottomRight: !top && !left,
              color: color,
              strokeWidth: cornerWidth,
              radius: r,
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

class _ScanOverlayPainter extends CustomPainter {
  final double boxLeft;
  final double boxTop;
  final double boxSize;

  const _ScanOverlayPainter({
    required this.boxLeft,
    required this.boxTop,
    required this.boxSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.58);
    final scanRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxLeft, boxTop, boxSize, boxSize),
      const Radius.circular(16),
    );

    final bgPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(scanRect);
    final path = Path.combine(PathOperation.difference, bgPath, holePath);

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = AppColors.mintGreen.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(scanRect, borderPaint);
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) =>
      old.boxLeft != boxLeft || old.boxTop != boxTop || old.boxSize != boxSize;
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  final Color color;
  final double strokeWidth;
  final Radius radius;

  const _CornerPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    if (topLeft) {
      canvas.drawLine(const Offset(0, 0), Offset(0, h), p);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CircleButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color ?? Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _NotFoundSheet extends StatelessWidget {
  final String barcode;
  final void Function(String categoryId) onCategorySelected;

  const _NotFoundSheet({required this.barcode, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('🔍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          const Text(
            'Item Not Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          if (barcode != 'MANUAL')
            Text('Barcode: $barcode', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace')),
          const SizedBox(height: 8),
          const Text(
            'Select the category that best matches this item:',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: RecyclingData.categories.map((cat) {
              return GestureDetector(
                onTap: () => onCategorySelected(cat.id),
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
                      Icon(cat.icon, color: cat.color, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        cat.name,
                        style: TextStyle(
                          color: cat.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
