import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_icons.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

final class NaListRow extends StatelessWidget {
  const NaListRow({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Semantics(
      button: true,
      label: label,
      value: value,
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
                      style: theme.typography.body.copyWith(
                        color: theme.colors.primary,
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Text(
                      value,
                      style: theme.typography.body.copyWith(
                        color: theme.colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  Icon(NaIcons.caret, size: 16, color: theme.colors.inkMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class NaMenuTile extends StatelessWidget {
  const NaMenuTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final NaSelection selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    final color = switch (selected) {
      NaSelection.selected => theme.colors.secondary,
      NaSelection.unselected => theme.colors.primary,
    };
    return Semantics(
      button: true,
      selected: selected == NaSelection.selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.colors.background)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.md,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 24, color: color),
                  const SizedBox(width: Space.lg),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        style: theme.typography.body.copyWith(color: color),
                      ),
                    ),
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

enum NaSelection { selected, unselected }
