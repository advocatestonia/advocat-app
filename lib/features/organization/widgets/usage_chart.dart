import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../models/usage_stats.dart';

/// Minimal line chart for usage over time. Uses CustomPaint to avoid
/// pulling in a heavy chart dependency (fl_chart is NOT in pubspec).
///
/// For the demo this is more than enough — when fl_chart lands we can
/// swap the painter for a `LineChart` without touching the screen code.
class UsageLineChart extends StatelessWidget {
  const UsageLineChart({
    super.key,
    required this.data,
    this.height = 180,
    this.lineColor = AppColors.accent,
    this.fillColor,
  });

  final List<UsageDataPoint> data;
  final double height;
  final Color lineColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No data for this period',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _LinePainter(
          data: data,
          lineColor: lineColor,
          fillColor: fillColor ?? lineColor.withValues(alpha: 0.12),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  final List<UsageDataPoint> data;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const padding = EdgeInsets.fromLTRB(8, 12, 8, 24);
    final w = size.width - padding.horizontal;
    final h = size.height - padding.vertical;

    final maxVal = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = padding.left +
          (data.length == 1 ? w / 2 : (w * i / (data.length - 1)));
      final y =
          padding.top + h - (data[i].value / safeMax) * h;
      points.add(Offset(x, y));
    }

    // Grid (3 horizontal lines).
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = padding.top + (h * i / 2);
      canvas.drawLine(
          Offset(padding.left, y), Offset(padding.left + w, y), gridPaint);
    }

    // Filled area under line.
    final fillPath = Path()..moveTo(points.first.dx, padding.top + h);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, padding.top + h);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // The line itself.
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Endpoint dots.
    final dotPaint = Paint()..color = lineColor;
    canvas.drawCircle(points.last, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.data != data || old.lineColor != lineColor;
}

// ─── Bar chart ──────────────────────────────────────────────────────────

class UsageBarChart extends StatelessWidget {
  const UsageBarChart({
    super.key,
    required this.bars,
    this.height = 240,
  });

  final List<({String label, double value})> bars;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No data',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }
    final maxVal = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            for (final bar in bars)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        bar.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final width = c.maxWidth * (bar.value / safeMax);
                          return Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: width.clamp(0, c.maxWidth),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius:
                                      BorderRadius.circular(7),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: Text(
                        bar.value.toStringAsFixed(0),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
