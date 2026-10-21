import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/values/na_values.dart';

final class NaIconButton extends StatelessWidget {
  const NaIconButton({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final NaTone tone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = NaTheme.of(context).colors;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: switch (tone) {
              NaTone.neutral => Icon(icon, size: 28, color: colors.primary),
              NaTone.success => NaFilledIcon(
                icon: icon,
                background: colors.success,
                foreground: colors.dark,
              ),
              NaTone.primary => NaFilledIcon(
                icon: icon,
                background: colors.primary,
                foreground: colors.onPrimary,
              ),
              NaTone.danger => NaFilledIcon(
                icon: icon,
                background: colors.danger,
                foreground: colors.onPrimary,
              ),
            },
          ),
        ),
      ),
    );
  }
}

final class NaFilledIcon extends StatelessWidget {
  const NaFilledIcon({
    required this.icon,
    required this.background,
    required this.foreground,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: SizedBox(
      width: 36,
      height: 36,
      child: Center(child: Icon(icon, size: 22, color: foreground)),
    ),
  );
}
