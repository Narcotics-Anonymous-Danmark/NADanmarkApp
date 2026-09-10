import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_radii.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

final class NaCard extends StatelessWidget {
  const NaCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.surface,
          border: Border.all(color: theme.colors.border),
          borderRadius: BorderRadius.circular(Radius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: child,
        ),
      ),
    );
  }
}

final class NaCardTitle extends StatelessWidget {
  const NaCardTitle({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.md),
    child: Semantics(
      header: true,
      child: Text(text, style: NaTheme.of(context).typography.title),
    ),
  );
}
