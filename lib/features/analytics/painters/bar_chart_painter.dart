import 'package:flutter/material.dart';

/// Interactive animated weekly spending bar chart using [CustomPainter].
/// Drawn directly on canvas without third-party chart libraries.
class BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data; // [{day: 'Mon', total: 50000.0}, ...]
  final double progress; // 0.0 → 1.0 (animation)
  final Color barColor;
  final int? selectedIndex;

  const BarChartPainter({
    required this.data,
    required this.progress,
    required this.barColor,
    this.selectedIndex,
  });

  // Layout constants
  static const _padLeft = 44.0;
  static const _padBottom = 36.0;
  static const _padTop = 26.0;
  static const _padRight = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      _drawEmpty(canvas, size);
      return;
    }

    final maxVal = data
        .map((d) => (d['total'] as double))
        .fold(0.0, (a, b) => a > b ? a : b);

    if (maxVal == 0) {
      _drawEmpty(canvas, size);
      return;
    }

    final chartW = size.width - _padLeft - _padRight;
    final chartH = size.height - _padTop - _padBottom;
    final barSlot = chartW / data.length;
    final barW = barSlot * 0.52;

    // ── Grid lines + Y labels ────────────────────────────────────────
    const gridCount = 4;
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(fontSize: 10, color: Colors.grey.shade500);

    for (int i = 0; i <= gridCount; i++) {
      final y = _padTop + chartH * (1 - i / gridCount);
      canvas.drawLine(
        Offset(_padLeft, y),
        Offset(size.width - _padRight, y),
        gridPaint,
      );

      final val = maxVal * i / gridCount;
      _drawText(
        canvas,
        _shortNum(val),
        labelStyle,
        Offset(0, y - 6),
        maxWidth: _padLeft - 4,
        align: TextAlign.right,
      );
    }

    // ── X-axis line ──────────────────────────────────────────────────
    canvas.drawLine(
      Offset(_padLeft, _padTop + chartH),
      Offset(size.width - _padRight, _padTop + chartH),
      Paint()
        ..color = Colors.grey.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );

    // ── Bars ─────────────────────────────────────────────────────────
    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['total'] as double);
      final barH = (val / maxVal) * chartH * progress;
      final x = _padLeft + barSlot * i + (barSlot - barW) / 2;
      final y = _padTop + chartH - barH;
      final isSelected = i == selectedIndex;

      if (barH > 0) {
        final barRect = Rect.fromLTWH(x, y, barW, barH);

        // Highlight background column when selected
        if (isSelected) {
          final columnHighlight = Paint()
            ..color = barColor.withValues(alpha: 0.12)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                _padLeft + barSlot * i + 2,
                _padTop,
                barSlot - 4,
                chartH,
              ),
              const Radius.circular(8),
            ),
            columnHighlight,
          );
        }

        // Gradient fill
        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isSelected
                ? [barColor, barColor.withValues(alpha: 0.8)]
                : [barColor, barColor.withValues(alpha: 0.45)],
          ).createShader(barRect);

        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(5)),
          barPaint,
        );

        // Selected bar border outline
        if (isSelected) {
          final borderPaint = Paint()
            ..color = barColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawRRect(
            RRect.fromRectAndRadius(barRect, const Radius.circular(5)),
            borderPaint,
          );
        }

        // Value label above bar
        if (progress > 0.75 && val > 0) {
          _drawText(
            canvas,
            _shortNum(val),
            TextStyle(
              fontSize: 10,
              color: isSelected ? barColor : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            Offset(x + barW / 2, y - 14),
            align: TextAlign.center,
            maxWidth: barW + 24,
          );
        }
      }

      // Day label below X-axis
      _drawText(
        canvas,
        data[i]['day'] as String,
        labelStyle.copyWith(
          color: isSelected ? barColor : Colors.grey.shade600,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        Offset(x + barW / 2, size.height - _padBottom + 8),
        align: TextAlign.center,
        maxWidth: barSlot,
      );
    }
  }

  void _drawEmpty(Canvas canvas, Size size) {
    _drawText(
      canvas,
      'No spending recorded this week',
      const TextStyle(fontSize: 13, color: Colors.grey),
      Offset(size.width / 2, size.height / 2 - 8),
      align: TextAlign.center,
      maxWidth: size.width,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset position, {
    TextAlign align = TextAlign.left,
    double maxWidth = 200,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final dx = align == TextAlign.center
        ? position.dx - tp.width / 2
        : align == TextAlign.right
            ? position.dx - tp.width
            : position.dx;
    tp.paint(canvas, Offset(dx, position.dy));
  }

  String _shortNum(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(BarChartPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.barColor != barColor ||
      old.selectedIndex != selectedIndex;
}
