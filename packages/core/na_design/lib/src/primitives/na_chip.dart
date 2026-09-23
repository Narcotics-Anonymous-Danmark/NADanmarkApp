import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_colors.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

enum NaChipTone {
  danger,
  language,
  primary,
  dark
  ;

  Color colourIn({required NaColors colors}) => switch (this) {
    NaChipTone.danger => colors.danger,
    NaChipTone.language => colors.tertiary,
    NaChipTone.primary => colors.primary,
    NaChipTone.dark => colors.dark,
  };
}

final class NaChip extends StatelessWidget {
  const NaChip({required this.label, required this.tone, super.key});

  final String label;
  final NaChipTone tone;

  static const double height = 20;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.colourIn(colors: theme.colors),
        borderRadius: BorderRadius.circular(height / 4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm,
          vertical: 2,
        ),
        child: Text(
          label,
          style: theme.typography.caption.copyWith(
            color: theme.colors.onPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

final class NaBadge extends StatelessWidget {
  const NaBadge({required this.label, required this.tone, super.key});

  final String label;
  final NaChipTone tone;

  static const double minWidth = 44;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: minWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.colourIn(colors: theme.colors),
          borderRadius: BorderRadius.circular(Space.xs),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.sm,
            vertical: Space.xs,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.typography.body.copyWith(
              color: theme.colors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
