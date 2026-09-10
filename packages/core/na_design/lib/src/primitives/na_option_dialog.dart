import 'package:flutter/widgets.dart';
import 'package:na_design/src/primitives/na_list_row.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_icons.dart';
import 'package:na_design/src/tokens/na_radii.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

@immutable
final class NaOption<T> {
  const NaOption({required this.value, required this.label});

  final T value;
  final String label;
}

sealed class NaOptionChoice<T> {
  const NaOptionChoice();
}

final class NaOptionPicked<T> extends NaOptionChoice<T> {
  const NaOptionPicked({required this.value});

  final T value;
}

final class NaOptionCancelled<T> extends NaOptionChoice<T> {
  const NaOptionCancelled();
}

Future<NaOptionChoice<T>> showNaOptionDialog<T>({
  required BuildContext context,
  required String title,
  required List<NaOption<T>> options,
  required T selected,
  required String cancelLabel,
}) async {
  final theme = NaTheme.of(context);
  final choice = await showGeneralDialog<NaOptionChoice<T>>(
    context: context,
    barrierDismissible: true,
    barrierLabel: cancelLabel,
    barrierColor: const Color(0x66000000),
    transitionDuration: theme.motion.fast,
    pageBuilder: (dialogContext, animation, secondaryAnimation) => NaTheme(
      data: theme,
      child: NaOptionSheet<T>(
        title: title,
        options: options,
        selected: selected,
        cancelLabel: cancelLabel,
        onPicked: (value) => Navigator.of(
          dialogContext,
        ).pop(NaOptionPicked<T>(value: value)),
        onCancelled: () =>
            Navigator.of(dialogContext).pop(NaOptionCancelled<T>()),
      ),
    ),
  );
  return switch (choice) {
    final NaOptionChoice<T> made => made,
    null => NaOptionCancelled<T>(),
  };
}

final class NaOptionSheet<T> extends StatelessWidget {
  const NaOptionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.cancelLabel,
    required this.onPicked,
    required this.onCancelled,
    super.key,
  });

  final String title;
  final List<NaOption<T>> options;
  final T selected;
  final String cancelLabel;
  final ValueChanged<T> onPicked;
  final VoidCallback onCancelled;

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
            children: [
              Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Semantics(
                  header: true,
                  child: Text(title, style: theme.typography.heading),
                ),
              ),
              ...options.map(
                (option) => NaMenuTile(
                  icon: option.value == selected
                      ? NaIcons.checked
                      : NaIcons.unchecked,
                  label: option.label,
                  selected: option.value == selected
                      ? NaSelection.selected
                      : NaSelection.unselected,
                  onTap: () => onPicked(option.value),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Semantics(
                    button: true,
                    label: cancelLabel,
                    child: GestureDetector(
                      onTap: onCancelled,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: ExcludeSemantics(
                          child: Text(
                            cancelLabel,
                            style: theme.typography.label,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
