import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';

final class NaIndeterminateBar extends StatelessWidget {
  const NaIndeterminateBar({required this.statusText, super.key});

  final String statusText;

  static const double height = 4;
  static const Duration sweep = Duration(milliseconds: 1200);

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Semantics(
      liveRegion: true,
      label: statusText,
      child: SizedBox(
        height: height,
        child: RepeatingAnimationBuilder<double>(
          animatable: Tween(begin: 0, end: 1),
          duration: sweep,
          builder: (context, value, child) => CustomPaint(
            painter: _BarPainter(
              progress: value,
              color: theme.colors.secondary,
              background: theme.colors.surface,
            ),
          ),
        ),
      ),
    );
  }
}

final class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.progress,
    required this.color,
    required this.background,
  });

  final double progress;
  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final segment = size.width * 0.3;
    final start = -segment + (size.width + segment) * progress;
    canvas.drawRect(
      Rect.fromLTWH(start, 0, segment, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_BarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
