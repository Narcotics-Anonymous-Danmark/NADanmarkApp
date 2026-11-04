import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';

final class NaSlider extends StatefulWidget {
  const NaSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  final int value;
  final int min;
  final int max;
  final String label;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  @override
  State<NaSlider> createState() => _NaSliderState();
}

final class _NaSliderState extends State<NaSlider> {
  static const double trackHeight = 4;
  static const double thumbRadius = 12;
  static const double height = 48;

  _SliderDraft _draft = const _WidgetValue();

  int get _value => switch (_draft) {
    _WidgetValue() => widget.value,
    _LocalValue(:final value) => value,
  };

  @override
  void didUpdateWidget(NaSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _draft = const _WidgetValue();
    }
  }

  int _valueAt({required double dx, required double width}) {
    final usable = width - thumbRadius * 2;
    final fraction = ((dx - thumbRadius) / usable).clamp(0.0, 1.0);
    return (widget.min + fraction * (widget.max - widget.min)).round();
  }

  void _update(int next) {
    if (next == _value) {
      return;
    }
    setState(() => _draft = _LocalValue(value: next));
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Semantics(
      slider: true,
      label: widget.label,
      value: '$_value',
      increasedValue: '${(_value + 1).clamp(widget.min, widget.max)}',
      decreasedValue: '${(_value - 1).clamp(widget.min, widget.max)}',
      onIncrease: () {
        _update((_value + 1).clamp(widget.min, widget.max));
        widget.onChangeEnd(_value);
      },
      onDecrease: () {
        _update((_value - 1).clamp(widget.min, widget.max));
        widget.onChangeEnd(_value);
      },
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) => _update(
            _valueAt(dx: details.localPosition.dx, width: constraints.maxWidth),
          ),
          onHorizontalDragUpdate: (details) => _update(
            _valueAt(dx: details.localPosition.dx, width: constraints.maxWidth),
          ),
          onHorizontalDragEnd: (details) => widget.onChangeEnd(_value),
          onTapUp: (details) {
            _update(
              _valueAt(
                dx: details.localPosition.dx,
                width: constraints.maxWidth,
              ),
            );
            widget.onChangeEnd(_value);
          },
          child: SizedBox(
            height: height,
            width: constraints.maxWidth,
            child: CustomPaint(
              painter: _SliderPainter(
                fraction: (_value - widget.min) / (widget.max - widget.min),
                track: theme.colors.background,
                active: theme.colors.danger,
                thumb: theme.colors.danger,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

sealed class _SliderDraft {
  const _SliderDraft();
}

final class _WidgetValue extends _SliderDraft {
  const _WidgetValue();
}

final class _LocalValue extends _SliderDraft {
  const _LocalValue({required this.value});

  final int value;
}

final class _SliderPainter extends CustomPainter {
  const _SliderPainter({
    required this.fraction,
    required this.track,
    required this.active,
    required this.thumb,
  });

  final double fraction;
  final Color track;
  final Color active;
  final Color thumb;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = _NaSliderState.thumbRadius;
    final centerY = size.height / 2;
    const startX = radius;
    final endX = size.width - radius;
    final thumbX = startX + (endX - startX) * fraction;
    final trackPaint = Paint()
      ..color = track
      ..strokeWidth = _NaSliderState.trackHeight
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = active
      ..strokeWidth = _NaSliderState.trackHeight
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(startX, centerY), Offset(endX, centerY), trackPaint)
      ..drawLine(Offset(startX, centerY), Offset(thumbX, centerY), activePaint)
      ..drawCircle(Offset(thumbX, centerY), radius, Paint()..color = thumb);
  }

  @override
  bool shouldRepaint(_SliderPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.track != track ||
      oldDelegate.active != active ||
      oldDelegate.thumb != thumb;
}
