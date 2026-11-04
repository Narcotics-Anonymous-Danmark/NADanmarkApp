import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/values/na_values.dart';

final class NaSpinner extends StatelessWidget {
  const NaSpinner({required this.label, required this.size, super.key});

  static const Duration turn = Duration(milliseconds: 900);

  final NaLabel label;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label.value,
    liveRegion: true,
    child: SizedBox.square(
      dimension: size,
      child: RepeatingAnimationBuilder<double>(
        animatable: Tween(begin: 0, end: 1),
        duration: turn,
        builder: (context, value, child) => CustomPaint(
          painter: _ArcPainter(
            turn: value,
            color: NaTheme.of(context).colors.primary,
          ),
        ),
      ),
    ),
  );
}

final class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.turn, required this.color});

  final double turn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide / 10;
    canvas.drawArc(
      (Offset.zero & size).deflate(stroke),
      turn * 2 * math.pi,
      math.pi * 1.4,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.turn != turn || oldDelegate.color != color;
}
