import 'dart:math' as math;
import 'package:flutter/material.dart';

class WeeklyProgressRing extends StatelessWidget {
  final double hours;
  final double goal;
  final double size;
  final double stroke;

  const WeeklyProgressRing({
    super.key,
    required this.hours,
    this.goal = 40,
    this.size = 96,
    this.stroke = 9,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (hours / goal).clamp(0.0, 1.0);
    final isOver = hours > goal;
    final ringColor = isOver
        ? const Color(0xFFD97706)
        : const Color(0xFFFA5D24);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: pct),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (ctx, animPct, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            pct: animPct,
            stroke: stroke,
            ringColor: ringColor,
            trackColor: const Color(0xFFF1ECE3),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _fmtDuration(hours),
                  style: TextStyle(
                    fontFamily: 'ui-monospace',
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontSize: size >= 96 ? 22 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: isOver
                        ? const Color(0xFFD97706)
                        : const Color(0xFF1A1814),
                    height: 1,
                  ),
                ),
                if (size >= 72) ...[
                  const SizedBox(height: 2),
                  Text(
                    'of ${goal % 1 == 0 ? goal.toInt() : goal}h',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8A837A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDuration(double h) {
    final total = (h * 60).round();
    final hh = total ~/ 60;
    final mm = total % 60;
    if (hh == 0 && mm == 0) return '–';
    if (hh == 0) return '${mm}m';
    if (mm == 0) return '${hh}h';
    return '${hh}h ${mm}m';
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final double stroke;
  final Color ringColor;
  final Color trackColor;

  _RingPainter({
    required this.pct,
    required this.stroke,
    required this.ringColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = ringColor;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * pct, false, progress);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.pct != pct || old.ringColor != ringColor;
}
