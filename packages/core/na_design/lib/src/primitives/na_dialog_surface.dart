import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_radii.dart';
import 'package:na_design/src/tokens/na_spacing.dart';
import 'package:na_design/src/values/na_values.dart';

final class NaDialogSurface extends StatelessWidget {
  const NaDialogSurface({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.surface,
            borderRadius: BorderRadius.circular(Radius.card),
            border: Border.all(color: theme.colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

final class NaDialogTitle extends StatelessWidget {
  const NaDialogTitle({required this.title, super.key});

  final NaLabel title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Space.lg),
    child: Semantics(
      header: true,
      child: Text(title.value, style: NaTheme.of(context).typography.heading),
    ),
  );
}

final class NaDialogActions extends StatelessWidget {
  const NaDialogActions({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Space.sm),
    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: children),
  );
}

Future<R> showNaDialog<R>({
  required BuildContext context,
  required NaLabel barrierLabel,
  required R dismissed,
  required Widget Function(BuildContext dialogContext) builder,
}) async {
  final theme = NaTheme.of(context);
  final result = await showGeneralDialog<R>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel.value,
    barrierColor: const Color(0x66000000),
    transitionDuration: theme.motion.fast,
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        NaTheme(data: theme, child: builder(dialogContext)),
  );
  return switch (result) {
    final R made => made,
    null => dismissed,
  };
}
