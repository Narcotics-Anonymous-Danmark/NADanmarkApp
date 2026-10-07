import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_icons.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

final class NaDisclosureRow extends StatelessWidget {
  const NaDisclosureRow({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.surface,
            border: Border(bottom: BorderSide(color: theme.colors.background)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.md,
              ),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.typography.heading.copyWith(
                          color: theme.colors.primary,
                        ),
                      ),
                    ),
                    Icon(NaIcons.play, size: 28, color: theme.colors.secondary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
