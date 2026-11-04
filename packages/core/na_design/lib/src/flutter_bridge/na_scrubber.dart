import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/values/na_values.dart';
import 'package:na_kernel/na_kernel.dart';

typedef NaTimeText = NaLabel Function(Duration time);

final class NaScrubber extends StatefulWidget {
  const NaScrubber({
    required this.position,
    required this.length,
    required this.label,
    required this.unknownLength,
    required this.timeText,
    required this.onCommit,
    super.key,
  });

  static const double height = 48;
  static const double timeWidth = 56;
  static const Duration forwardStep = Duration(seconds: 30);
  static const Duration backwardStep = Duration(seconds: 15);

  final Duration position;
  final MediaLength length;
  final NaLabel label;
  final NaLabel unknownLength;
  final NaTimeText timeText;
  final ValueChanged<Duration> onCommit;

  @override
  State<NaScrubber> createState() => _NaScrubberState();
}

final class _NaScrubberState extends State<NaScrubber> {
  static const double thumbRadius = 8;

  _Drag _drag = const _NotDragging();

  Duration get _shown => switch (_drag) {
    _NotDragging() => widget.position,
    _Dragging(:final value) => value,
  };

  Duration _at({
    required double dx,
    required double width,
    required Duration whole,
  }) {
    final usable = width - thumbRadius * 2;
    final fraction = ((dx - thumbRadius) / usable).clamp(0.0, 1.0);
    return Duration(seconds: (whole.inSeconds * fraction).round());
  }

  void _dragTo({required Duration value}) =>
      setState(() => _drag = _Dragging(value: value));

  void _commit({required Duration value}) {
    setState(() => _drag = const _NotDragging());
    widget.onCommit(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    final style = theme.typography.caption.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final whole = switch (widget.length) {
      KnownLength(:final duration) => duration,
      UnknownLength() => null,
    };
    final fraction = whole == null || whole.inSeconds == 0
        ? 0.0
        : (_shown.inSeconds / whole.inSeconds).clamp(0.0, 1.0);
    final painter = CustomPaint(
      painter: _ScrubberPainter(
        fraction: fraction,
        track: theme.colors.background,
        active: whole == null ? theme.colors.inkMuted : theme.colors.primary,
      ),
    );
    return SizedBox(
      height: NaScrubber.height,
      child: Row(
        children: [
          SizedBox(
            width: NaScrubber.timeWidth,
            child: ExcludeSemantics(
              child: Text(
                widget.timeText(_shown).value,
                key: const Key('na-scrubber-position'),
                textAlign: TextAlign.center,
                style: style,
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              slider: true,
              enabled: whole != null,
              label: widget.label.value,
              value: widget.timeText(_shown).value,
              increasedValue: whole == null
                  ? null
                  : widget
                        .timeText(
                          _clamped(
                            value: _shown + NaScrubber.forwardStep,
                            whole: whole,
                          ),
                        )
                        .value,
              decreasedValue: whole == null
                  ? null
                  : widget
                        .timeText(
                          _clamped(
                            value: _shown - NaScrubber.backwardStep,
                            whole: whole,
                          ),
                        )
                        .value,
              onIncrease: whole == null
                  ? null
                  : () => widget.onCommit(
                      _clamped(
                        value: _shown + NaScrubber.forwardStep,
                        whole: whole,
                      ),
                    ),
              onDecrease: whole == null
                  ? null
                  : () => widget.onCommit(
                      _clamped(
                        value: _shown - NaScrubber.backwardStep,
                        whole: whole,
                      ),
                    ),
              child: whole == null
                  ? SizedBox.expand(
                      key: const Key('na-scrubber-track'),
                      child: painter,
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) => GestureDetector(
                        key: const Key('na-scrubber-track'),
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (details) => _dragTo(
                          value: _at(
                            dx: details.localPosition.dx,
                            width: constraints.maxWidth,
                            whole: whole,
                          ),
                        ),
                        onHorizontalDragUpdate: (details) => _dragTo(
                          value: _at(
                            dx: details.localPosition.dx,
                            width: constraints.maxWidth,
                            whole: whole,
                          ),
                        ),
                        onHorizontalDragEnd: (details) =>
                            _commit(value: _shown),
                        onHorizontalDragCancel: () =>
                            setState(() => _drag = const _NotDragging()),
                        onTapUp: (details) => _commit(
                          value: _at(
                            dx: details.localPosition.dx,
                            width: constraints.maxWidth,
                            whole: whole,
                          ),
                        ),
                        child: SizedBox.expand(child: painter),
                      ),
                    ),
            ),
          ),
          SizedBox(
            width: NaScrubber.timeWidth,
            child: Semantics(
              label: whole == null ? widget.unknownLength.value : null,
              excludeSemantics: whole == null,
              child: Text(
                whole == null ? '--:--' : widget.timeText(whole).value,
                key: const Key('na-scrubber-length'),
                textAlign: TextAlign.center,
                style: style,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Duration _clamped({
    required Duration value,
    required Duration whole,
  }) => value < Duration.zero
      ? Duration.zero
      : value > whole
      ? whole
      : value;
}

sealed class _Drag {
  const _Drag();
}

final class _NotDragging extends _Drag {
  const _NotDragging();
}

final class _Dragging extends _Drag {
  const _Dragging({required this.value});

  final Duration value;
}

final class _ScrubberPainter extends CustomPainter {
  const _ScrubberPainter({
    required this.fraction,
    required this.track,
    required this.active,
  });

  static const double trackHeight = 4;

  final double fraction;
  final Color track;
  final Color active;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = _NaScrubberState.thumbRadius;
    final centerY = size.height / 2;
    const startX = radius;
    final endX = size.width - radius;
    final thumbX = startX + (endX - startX) * fraction;
    canvas
      ..drawLine(
        Offset(startX, centerY),
        Offset(endX, centerY),
        Paint()
          ..color = track
          ..strokeWidth = trackHeight
          ..strokeCap = StrokeCap.round,
      )
      ..drawLine(
        Offset(startX, centerY),
        Offset(thumbX, centerY),
        Paint()
          ..color = active
          ..strokeWidth = trackHeight
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(Offset(thumbX, centerY), radius, Paint()..color = active);
  }

  @override
  bool shouldRepaint(_ScrubberPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.track != track ||
      oldDelegate.active != active;
}
