import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_radii.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

final class NaButton extends StatelessWidget {
  const NaButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colors.primary,
                borderRadius: BorderRadius.circular(Radius.button),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.lg,
                    vertical: Space.md,
                  ),
                  child: Text(
                    label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: theme.typography.label.copyWith(
                      color: theme.colors.onPrimary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
