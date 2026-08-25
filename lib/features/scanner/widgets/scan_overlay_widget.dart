import 'package:flutter/material.dart';
import 'package:recyclescan/core/constants/app_colors.dart';

class ScanOverlayWidget extends StatefulWidget {
  const ScanOverlayWidget({super.key});

  @override
  State<ScanOverlayWidget> createState() => _ScanOverlayWidgetState();
}

class _ScanOverlayWidgetState extends State<ScanOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const boxSize = 280.0;
    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2 - 30;

    return Stack(
      children: [
        // Dark overlay
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Corner brackets
        Positioned(
          left: left,
          top: top,
          child: _buildCorner(topLeft: true),
        ),
        Positioned(
          right: left,
          top: top,
          child: _buildCorner(topRight: true),
        ),
        Positioned(
          left: left,
          bottom: size.height - top - boxSize,
          child: _buildCorner(bottomLeft: true),
        ),
        Positioned(
          right: left,
          bottom: size.height - top - boxSize,
          child: _buildCorner(bottomRight: true),
        ),

        // Animated scan line
        AnimatedBuilder(
          animation: _scanLineAnimation,
          builder: (context, child) {
            return Positioned(
              left: left + 10,
              top: top + _scanLineAnimation.value * (boxSize - 4),
              child: Container(
                width: boxSize - 20,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.mintGreen,
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mintGreen.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCorner({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    const cornerSize = 24.0;
    const cornerWidth = 4.0;
    const color = AppColors.mintGreen;

    return SizedBox(
      width: cornerSize,
      height: cornerSize,
      child: CustomPaint(
        painter: _CornerPainter(
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
          color: color,
          strokeWidth: cornerWidth,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  final Color color;
  final double strokeWidth;

  _CornerPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (topLeft) {
      canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(0, size.height), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(size.width, 0), const Offset(0, 0), paint);
      canvas.drawLine(
          Offset(size.width, 0), Offset(size.width, size.height), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(
          Offset(0, size.height), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
    }
    if (bottomRight) {
      canvas.drawLine(
          Offset(size.width, size.height), Offset(0, size.height), paint);
      canvas.drawLine(
          Offset(size.width, size.height), Offset(size.width, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
