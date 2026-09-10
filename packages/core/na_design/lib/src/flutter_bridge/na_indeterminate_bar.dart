import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';

final class NaIndeterminateBar extends StatefulWidget {
  const NaIndeterminateBar({required this.statusText, super.key});

  final String statusText;

  static const double height = 4;

  @override
  State<NaIndeterminateBar> createState() => _NaIndeterminateBarState();
}

final class _NaIndeterminateBarState extends State<NaIndeterminateBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Semantics(
      liveRegion: true,
      label: widget.statusText,
      child: SizedBox(
        height: NaIndeterminateBar.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            painter: _BarPainter(
              progress: _controller.value,
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
