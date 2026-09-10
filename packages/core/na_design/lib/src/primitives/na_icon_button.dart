import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';

final class NaIconButton extends StatelessWidget {
  const NaIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: NaTheme.of(context).colors.primary,
          ),
        ),
      ),
    ),
  );
}
