import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';

extension type const NaFraction(double value) {}

final class NaProgressBar extends StatelessWidget {
  const NaProgressBar({required this.fraction, super.key});

  static const double height = 4;

  final NaFraction fraction;

  @override
  Widget build(BuildContext context) {
    final colors = NaTheme.of(context).colors;
    final clamped = fraction.value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(clamped * 100).round()} %',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors.background),
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: clamped,
                child: ColoredBox(color: colors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
