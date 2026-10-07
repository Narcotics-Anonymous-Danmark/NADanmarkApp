import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_radii.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

final class NaActionButton extends StatelessWidget {
  const NaActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
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
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.lg,
                    vertical: Space.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20, color: theme.colors.onPrimary),
                      const SizedBox(width: Space.sm),
                      Flexible(
                        child: Text(
                          label.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: theme.typography.label.copyWith(
                            color: theme.colors.onPrimary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
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
