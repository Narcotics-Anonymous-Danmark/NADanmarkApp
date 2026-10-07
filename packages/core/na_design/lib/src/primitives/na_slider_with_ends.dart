import 'package:flutter/widgets.dart';
import 'package:na_design/src/flutter_bridge/na_slider.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/values/na_values.dart';

final class NaSliderWithEnds extends StatelessWidget {
  const NaSliderWithEnds({
    required this.sliderKey,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.minLabel,
    required this.maxLabel,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  final Key sliderKey;
  final SliderValue value;
  final SliderValue min;
  final SliderValue max;
  final NaLabel label;
  final NaLabel minLabel;
  final NaLabel maxLabel;
  final ValueChanged<SliderValue> onChanged;
  final ValueChanged<SliderValue> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final caption = NaTheme.of(context).typography.caption;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NaSlider(
          key: sliderKey,
          value: value.value,
          min: min.value,
          max: max.value,
          label: label.value,
          onChanged: (raw) => onChanged(SliderValue(raw)),
          onChangeEnd: (raw) => onChangeEnd(SliderValue(raw)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel.value, style: caption),
            Text(maxLabel.value, style: caption),
          ],
        ),
      ],
    );
  }
}
