import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Custom illustrated empty state graphics using vector shapes.
/// These provide visual polish without external dependencies.

/// Empty claims illustration - a document with a plus sign
class EmptyClaimsIllustration extends StatelessWidget {
  final double size;
  
  const EmptyClaimsIllustration({super.key, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
          // Document shape
          Positioned(
            child: Container(
              width: size * 0.45,
              height: size * 0.58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * 0.05),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lines representing text
                  _buildLine(size * 0.28),
                  SizedBox(height: size * 0.03),
                  _buildLine(size * 0.22),
                  SizedBox(height: size * 0.03),
                  _buildLine(size * 0.18),
                  SizedBox(height: size * 0.06),
                  // Plus icon
                  Container(
                    width: size * 0.14,
                    height: size * 0.14,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(size * 0.03),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: size * 0.10,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(double width) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Empty bills illustration - receipt with coins
class EmptyBillsIllustration extends StatelessWidget {
  final double size;
  
  const EmptyBillsIllustration({super.key, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
          // Receipt
          Positioned(
            top: size * 0.12,
            child: CustomPaint(
              size: Size(size * 0.42, size * 0.55),
              painter: _ReceiptPainter(),
            ),
          ),
          // Coins
          Positioned(
            bottom: size * 0.15,
            right: size * 0.2,
            child: _buildCoin(size * 0.14),
          ),
          Positioned(
            bottom: size * 0.22,
            right: size * 0.28,
            child: _buildCoin(size * 0.12),
          ),
        ],
      ),
    );
  }

  Widget _buildCoin(double coinSize) {
    return Container(
      width: coinSize,
      height: coinSize,
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.currency_rupee_rounded,
        size: coinSize * 0.5,
        color: AppColors.secondary,
      ),
    );
  }
}

class _ReceiptPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Receipt with torn bottom edge
    final path = Path();
    path.moveTo(0, 8);
    path.quadraticBezierTo(0, 0, 8, 0);
    path.lineTo(size.width - 8, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 8);
    path.lineTo(size.width, size.height - 8);
    
    // Zigzag bottom
    final zigzagWidth = size.width / 6;
    for (int i = 0; i < 6; i++) {
      final x = size.width - (i * zigzagWidth);
      final nextX = x - zigzagWidth;
      path.lineTo(x - zigzagWidth / 2, size.height);
      path.lineTo(nextX, size.height - 8);
    }
    
    path.close();

    // Shadow
    canvas.drawShadow(path.shift(const Offset(0, 4)), 
        AppColors.secondary.withValues(alpha: 0.1), 8, false);
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Lines
    final linePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.85, size.height * 0.2),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.35),
      Offset(size.width * 0.65, size.height * 0.35),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.5),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// No search results illustration
class NoResultsIllustration extends StatelessWidget {
  final double size;
  
  const NoResultsIllustration({super.key, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
          // Magnifying glass
          Positioned(
            child: Container(
              width: size * 0.45,
              height: size * 0.45,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: size * 0.22,
                color: AppColors.textDisabled,
              ),
            ),
          ),
          // Handle
          Positioned(
            bottom: size * 0.12,
            right: size * 0.18,
            child: Transform.rotate(
              angle: 0.8,
              child: Container(
                width: size * 0.08,
                height: size * 0.2,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(size * 0.04),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty history/audit log illustration
class EmptyHistoryIllustration extends StatelessWidget {
  final double size;
  
  const EmptyHistoryIllustration({super.key, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
          // Clock
          Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.25),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _ClockPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Hour marks
    final markPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * 3.14159 / 180;
      final outer = Offset(
        center.dx + (size.width * 0.38) * -_cos(angle),
        center.dy + (size.height * 0.38) * -_sin(angle),
      );
      final inner = Offset(
        center.dx + (size.width * 0.32) * -_cos(angle),
        center.dy + (size.height * 0.32) * -_sin(angle),
      );
      canvas.drawLine(inner, outer, markPaint);
    }

    // Hour hand
    final hourPaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx - size.width * 0.15, center.dy - size.height * 0.1),
      hourPaint,
    );

    // Minute hand
    final minutePaint = Paint()
      ..color = AppColors.info
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx + size.width * 0.08, center.dy - size.height * 0.22),
      minutePaint,
    );

    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = AppColors.textPrimary);
  }

  double _sin(double angle) => _customSin(angle);
  double _cos(double angle) => _customCos(angle);
  
  // Simple approximations to avoid dart:math import issues
  double _customSin(double x) {
    x = x % (2 * 3.14159);
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
  
  double _customCos(double x) {
    x = x % (2 * 3.14159);
    return 1 - (x * x) / 2 + (x * x * x * x) / 24;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
