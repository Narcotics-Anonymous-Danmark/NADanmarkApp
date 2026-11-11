import 'package:flutter/widgets.dart';
import 'package:na_design/src/primitives/na_list_row.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_radii.dart';
import 'package:na_design/src/tokens/na_spacing.dart';
import 'package:na_design/src/values/na_values.dart';

final class NaToggleChip extends StatelessWidget {
  const NaToggleChip({
    required this.label,
    required this.selection,
    required this.onTap,
    super.key,
  });

  static const double height = 32;

  final NaLabel label;
  final NaSelection selection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    final colors = theme.colors;
    return Semantics(
      button: true,
      selected: selection == NaSelection.selected,
      label: label.value,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Center(
            heightFactor: 1,
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: switch (selection) {
                  NaSelection.selected => colors.primary,
                  NaSelection.unselected => colors.surface,
                },
                border: Border.all(color: colors.primary),
                borderRadius: BorderRadius.circular(Radius.chip),
              ),
              child: SizedBox(
                height: height,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.md),
                  child: Center(
                    widthFactor: 1,
                    child: ExcludeSemantics(
                      child: Text(
                        label.value,
                        style: theme.typography.label.copyWith(
                          color: switch (selection) {
                            NaSelection.selected => colors.onPrimary,
                            NaSelection.unselected => colors.primary,
                          },
                        ),
                      ),
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

final class NaChipStrip extends StatelessWidget {
  const NaChipStrip({required this.chips, super.key});

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: Space.md),
    child: Row(
      children: [
        for (final chip in chips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xs),
            child: chip,
          ),
      ],
    ),
  );
}
