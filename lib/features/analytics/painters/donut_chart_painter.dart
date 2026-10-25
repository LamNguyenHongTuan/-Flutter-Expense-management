import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Interactive animated donut/pie chart using [CustomPainter].
/// Drawn directly on canvas without third-party chart libraries.
class DonutChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double progress; // 0.0 → 1.0 (animation)
  final Map<String, Color> categoryColors;
  final String? selectedCategory;

  const DonutChartPainter({
    required this.data,
    required this.progress,
    required this.categoryColors,
    this.selectedCategory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final total = data.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = min(size.width, size.height) / 2 - 16;
    const baseStrokeWidth = 46.0;

    const gapAngle = 0.025; // gap between segments in radians
    var sweepSoFar = -pi / 2.0; // start from top (12 o'clock)

    final entries = data.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final sweep = ((entry.value / total) * 2 * pi - gapAngle) * progress;
      if (sweep <= 0) continue;

      final isSelected = entry.key == selectedCategory;
      final strokeW = isSelected ? baseStrokeWidth + 10.0 : baseStrokeWidth;
      final radius = isSelected ? baseRadius + 4.0 : baseRadius;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round
        ..color = categoryColors[entry.key] ?? Colors.grey;

      // Draw subtle glow shadow if selected
      if (isSelected) {
        final shadowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW + 6.0
          ..strokeCap = StrokeCap.round
          ..color = (categoryColors[entry.key] ?? Colors.grey).withValues(alpha: 0.35);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          sweepSoFar,
          sweep,
          false,
          shadowPaint,
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        sweepSoFar,
        sweep,
        false,
        paint,
      );

      sweepSoFar += sweep + gapAngle;
    }

    // ── Interactive Center Info ──────────────────────────────────────
    if (progress > 0.5) {
      _drawCenterContent(canvas, center, total);
    }
  }

  void _drawCenterContent(Canvas canvas, Offset center, double total) {
    final fmt = NumberFormat.compactCurrency(locale: 'vi_VN', symbol: '₫');

    if (selectedCategory != null && data.containsKey(selectedCategory)) {
      final val = data[selectedCategory]!;
      final pct = (val / total * 100).toStringAsFixed(1);
      final color = categoryColors[selectedCategory] ?? Colors.deepPurple;

      final tp = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$selectedCategory\n',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            TextSpan(
              text: '${fmt.format(val)}\n',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: '$pct%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )..layout(maxWidth: 120);

      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    } else {
      final tp = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        text: TextSpan(
          children: [
            TextSpan(
              text: '${data.length}\n',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const TextSpan(
              text: 'Categories\n',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const TextSpan(
              text: 'Tap slice for info',
              style: TextStyle(fontSize: 9, color: Colors.blueGrey),
            ),
          ],
        ),
      )..layout(maxWidth: 120);

      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.selectedCategory != selectedCategory;
}
