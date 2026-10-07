import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';

@immutable
final class NaRangeValues {
  const NaRangeValues({required this.lower, required this.upper});

  final int lower;
  final int upper;

  @override
  int get hashCode => Object.hash(lower, upper);

  @override
  bool operator ==(Object other) =>
      other is NaRangeValues && other.lower == lower && other.upper == upper;

  @override
  String toString() => '$lower-$upper';
}

enum _Thumb { lower, upper }

final class NaRangeSlider extends StatefulWidget {
  const NaRangeSlider({
    required this.values,
    required this.min,
    required this.max,
    required this.lowerLabel,
    required this.upperLabel,
    required this.onChanged,
    super.key,
  });

  final NaRangeValues values;
  final int min;
  final int max;
  final String lowerLabel;
  final String upperLabel;
  final ValueChanged<NaRangeValues> onChanged;

  static const double height = 48;
  static const double thumbRadius = 12;

  @override
  State<NaRangeSlider> createState() => _NaRangeSliderState();
}

final class _NaRangeSliderState extends State<NaRangeSlider> {
  static const double trackHeight = 4;

  late NaRangeValues _values = widget.values;
  _Thumb _active = _Thumb.lower;

  @override
  void didUpdateWidget(NaRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) {
      _values = widget.values;
    }
  }

  double _fractionOf({required int value}) =>
      (value - widget.min) / (widget.max - widget.min);

  int _valueAt({required double dx, required double width}) {
    const radius = NaRangeSlider.thumbRadius;
    final fraction = ((dx - radius) / (width - radius * 2)).clamp(0.0, 1.0);
    return (widget.min + fraction * (widget.max - widget.min)).round();
  }

  _Thumb _nearest({required int value}) =>
      (value - _values.lower).abs() <= (value - _values.upper).abs() &&
          value <= _values.upper
      ? _Thumb.lower
      : _Thumb.upper;

  void _move({required _Thumb thumb, required int to}) {
    final next = switch (thumb) {
      _Thumb.lower => NaRangeValues(
        lower: to.clamp(widget.min, _values.upper),
        upper: _values.upper,
      ),
      _Thumb.upper => NaRangeValues(
        lower: _values.lower,
        upper: to.clamp(_values.lower, widget.max),
      ),
    };
    if (next == _values) {
      return;
    }
    setState(() => _values = next);
    widget.onChanged(next);
  }

  void _startAt({required double dx, required double width}) {
    final value = _valueAt(dx: dx, width: width);
    _active = _nearest(value: value);
    _move(thumb: _active, to: value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const radius = NaRangeSlider.thumbRadius;
        double xOf(int value) =>
            radius + (width - radius * 2) * _fractionOf(value: value);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onHorizontalDragStart: (details) =>
              _startAt(dx: details.localPosition.dx, width: width),
          onHorizontalDragUpdate: (details) => _move(
            thumb: _active,
            to: _valueAt(dx: details.localPosition.dx, width: width),
          ),
          onTapUp: (details) =>
              _startAt(dx: details.localPosition.dx, width: width),
          child: SizedBox(
            width: width,
            height: NaRangeSlider.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RangeTrackPainter(
                      from: xOf(_values.lower),
                      to: xOf(_values.upper),
                      track: theme.colors.background,
                      active: theme.colors.primary,
                    ),
                  ),
                ),
                _ThumbHandle(
                  centerX: xOf(_values.lower),
                  label: widget.lowerLabel,
                  value: _values.lower,
                  colour: theme.colors.primary,
                  onIncrease: () =>
                      _move(thumb: _Thumb.lower, to: _values.lower + 1),
                  onDecrease: () =>
                      _move(thumb: _Thumb.lower, to: _values.lower - 1),
                ),
                _ThumbHandle(
                  centerX: xOf(_values.upper),
                  label: widget.upperLabel,
                  value: _values.upper,
                  colour: theme.colors.primary,
                  onIncrease: () =>
                      _move(thumb: _Thumb.upper, to: _values.upper + 1),
                  onDecrease: () =>
                      _move(thumb: _Thumb.upper, to: _values.upper - 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _ThumbHandle extends StatelessWidget {
  const _ThumbHandle({
    required this.centerX,
    required this.label,
    required this.value,
    required this.colour,
    required this.onIncrease,
    required this.onDecrease,
  });

  final double centerX;
  final String label;
  final int value;
  final Color colour;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) => Positioned(
    left: centerX - NaRangeSlider.height / 2,
    top: 0,
    width: NaRangeSlider.height,
    height: NaRangeSlider.height,
    child: Semantics(
      slider: true,
      label: label,
      value: '$value',
      increasedValue: '${value + 1}',
      decreasedValue: '${value - 1}',
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      child: Center(
        child: SizedBox.square(
          dimension: NaRangeSlider.thumbRadius * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
          ),
        ),
      ),
    ),
  );
}

final class _RangeTrackPainter extends CustomPainter {
  const _RangeTrackPainter({
    required this.from,
    required this.to,
    required this.track,
    required this.active,
  });

  final double from;
  final double to;
  final Color track;
  final Color active;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = NaRangeSlider.thumbRadius;
    final centerY = size.height / 2;
    Paint line(Color colour) => Paint()
      ..color = colour
      ..strokeWidth = _NaRangeSliderState.trackHeight
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(
        Offset(radius, centerY),
        Offset(size.width - radius, centerY),
        line(track),
      )
      ..drawLine(Offset(from, centerY), Offset(to, centerY), line(active));
  }

  @override
  bool shouldRepaint(_RangeTrackPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.track != track ||
      oldDelegate.active != active;
}
