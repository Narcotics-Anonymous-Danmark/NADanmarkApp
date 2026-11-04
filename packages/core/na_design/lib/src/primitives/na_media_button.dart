import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/values/na_values.dart';

enum NaMediaButtonSize {
  regular(icon: 28),
  large(icon: 44)
  ;

  const NaMediaButtonSize({required this.icon});

  final double icon;
}

final class NaMediaButton extends StatelessWidget {
  const NaMediaButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.availability,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final NaLabel label;
  final NaMediaButtonSize size;
  final NaAvailability availability;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = NaTheme.of(context).colors;
    return Semantics(
      button: true,
      enabled: availability == NaAvailability.enabled,
      label: label.value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: switch (availability) {
          NaAvailability.enabled => onPressed,
          NaAvailability.disabled => null,
        },
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: Icon(
              icon,
              size: size.icon,
              color: switch (availability) {
                NaAvailability.enabled => colors.primary,
                NaAvailability.disabled => colors.primary.withValues(
                  alpha: 0.35,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}
