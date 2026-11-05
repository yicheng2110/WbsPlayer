import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_context.dart';
import '../../../ui/core/app_colors.dart';

class EmptyServerState extends StatelessWidget {
  const EmptyServerState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(painter: _EmptyPackagePainter()),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.emptyServersMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  fontSize: 20,
                  height: 1.55,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPackagePainter extends CustomPainter {
  const _EmptyPackagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 300;
    canvas.save();
    canvas.scale(scale, scale);

    final stroke = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.fill;

    final backLeft = Path()
      ..moveTo(148, 133)
      ..lineTo(91, 64)
      ..lineTo(36, 80)
      ..quadraticBezierTo(29, 83, 34, 91)
      ..lineTo(69, 145);
    final backRight = Path()
      ..moveTo(151, 133)
      ..lineTo(208, 64)
      ..lineTo(264, 81)
      ..quadraticBezierTo(271, 84, 266, 92)
      ..lineTo(231, 145);
    canvas.drawPath(backLeft, stroke);
    canvas.drawPath(backRight, stroke);

    final rightFace = Path()
      ..moveTo(150, 135)
      ..lineTo(253, 163)
      ..lineTo(253, 224)
      ..quadraticBezierTo(253, 235, 242, 240)
      ..lineTo(150, 275)
      ..close();
    canvas.drawPath(rightFace, fill);

    final leftFace = Path()
      ..moveTo(150, 135)
      ..lineTo(48, 163)
      ..lineTo(48, 224)
      ..quadraticBezierTo(48, 235, 59, 240)
      ..lineTo(150, 275)
      ..close();
    canvas.drawPath(leftFace, Paint()..color = AppColors.pageBackground);
    canvas.drawPath(leftFace, stroke);

    canvas.drawLine(const Offset(150, 135), const Offset(150, 275), stroke);
    final frontLeft = Path()
      ..moveTo(150, 135)
      ..lineTo(69, 146)
      ..lineTo(31, 177)
      ..quadraticBezierTo(26, 182, 32, 188)
      ..lineTo(112, 215)
      ..quadraticBezierTo(119, 217, 123, 210)
      ..close();
    final frontRight = Path()
      ..moveTo(150, 135)
      ..lineTo(231, 146)
      ..lineTo(269, 177)
      ..quadraticBezierTo(274, 182, 268, 188)
      ..lineTo(188, 215)
      ..quadraticBezierTo(181, 217, 177, 210)
      ..close();
    canvas.drawPath(frontLeft, Paint()..color = AppColors.pageBackground);
    canvas.drawPath(frontLeft, stroke);
    canvas.drawPath(frontRight, Paint()..color = AppColors.pageBackground);
    canvas.drawPath(frontRight, stroke);

    final trail = Path()
      ..moveTo(111, 145)
      ..cubicTo(91, 124, 101, 108, 126, 106)
      ..cubicTo(155, 103, 189, 111, 190, 81)
      ..cubicTo(191, 61, 177, 51, 162, 48);
    for (final metric in trail.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 9).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), stroke);
        distance += 18;
      }
    }

    final marker = Path()
      ..moveTo(158, 39)
      ..cubicTo(161, 28, 170, 20, 181, 20)
      ..cubicTo(188, 20, 192, 26, 188, 32)
      ..lineTo(180, 40)
      ..lineTo(194, 40)
      ..cubicTo(201, 40, 203, 48, 197, 52)
      ..lineTo(184, 52)
      ..cubicTo(188, 60, 183, 69, 174, 69)
      ..cubicTo(159, 69, 150, 58, 150, 46)
      ..lineTo(140, 46)
      ..lineTo(148, 36)
      ..close();
    canvas.drawPath(marker, fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EmptyPackagePainter oldDelegate) => false;
}
