import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_icons.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

enum NaSectionTone { normal, highlighted }

enum NaExpansion { expanded, collapsed }

final class NaSectionHeader extends StatelessWidget {
  const NaSectionHeader({
    required this.label,
    required this.tone,
    required this.expansion,
    required this.onTap,
    super.key,
  });

  final String label;
  final NaSectionTone tone;
  final NaExpansion expansion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    final colour = switch (tone) {
      NaSectionTone.normal => theme.colors.primary,
      NaSectionTone.highlighted => theme.colors.secondary,
    };
    return Semantics(
      button: true,
      header: true,
      expanded: switch (expansion) {
        NaExpansion.expanded => true,
        NaExpansion.collapsed => false,
      },
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.typography.heading.copyWith(color: colour),
                    ),
                  ),
                  Icon(
                    switch (expansion) {
                      NaExpansion.expanded => NaIcons.close,
                      NaExpansion.collapsed => NaIcons.add,
                    },
                    size: 24,
                    color: colour,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
