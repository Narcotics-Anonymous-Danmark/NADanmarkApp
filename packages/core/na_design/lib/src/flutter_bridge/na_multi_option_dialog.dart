import 'package:flutter/widgets.dart';
import 'package:na_design/src/primitives/na_list_row.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_icons.dart';
import 'package:na_design/src/tokens/na_radii.dart';
import 'package:na_design/src/tokens/na_spacing.dart';
import 'package:na_design/src/values/na_values.dart';

@immutable
final class NaMultiOption<T> {
  const NaMultiOption({required this.value, required this.label});

  final T value;
  final NaLabel label;
}

sealed class NaMultiChoice<T> {
  const NaMultiChoice();
}

final class NaOptionsConfirmed<T> extends NaMultiChoice<T> {
  const NaOptionsConfirmed({required this.values});

  final Set<T> values;
}

final class NaOptionsCancelled<T> extends NaMultiChoice<T> {
  const NaOptionsCancelled();
}

Future<NaMultiChoice<T>> showNaMultiOptionDialog<T>({
  required BuildContext context,
  required NaLabel title,
  required List<NaMultiOption<T>> options,
  required Set<T> selected,
  required NaLabel cancelLabel,
  required NaLabel confirmLabel,
}) async {
  final theme = NaTheme.of(context);
  final choice = await showGeneralDialog<NaMultiChoice<T>>(
    context: context,
    barrierDismissible: true,
    barrierLabel: cancelLabel.value,
    barrierColor: const Color(0x66000000),
    transitionDuration: theme.motion.fast,
    pageBuilder: (dialogContext, animation, secondaryAnimation) => NaTheme(
      data: theme,
      child: NaMultiOptionSheet<T>(
        title: title,
        options: options,
        selected: selected,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        onConfirmed: (values) => Navigator.of(
          dialogContext,
        ).pop(NaOptionsConfirmed<T>(values: values)),
        onCancelled: () =>
            Navigator.of(dialogContext).pop(NaOptionsCancelled<T>()),
      ),
    ),
  );
  return switch (choice) {
    final NaMultiChoice<T> made => made,
    null => NaOptionsCancelled<T>(),
  };
}

final class NaMultiOptionSheet<T> extends StatefulWidget {
  const NaMultiOptionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onConfirmed,
    required this.onCancelled,
    super.key,
  });

  final NaLabel title;
  final List<NaMultiOption<T>> options;
  final Set<T> selected;
  final NaLabel cancelLabel;
  final NaLabel confirmLabel;
  final ValueChanged<Set<T>> onConfirmed;
  final VoidCallback onCancelled;

  @override
  State<NaMultiOptionSheet<T>> createState() => _NaMultiOptionSheetState<T>();
}

final class _NaMultiOptionSheetState<T> extends State<NaMultiOptionSheet<T>> {
  late Set<T> _checked = Set.of(widget.selected);

  void _toggle(T value) => setState(
    () => _checked = _checked.contains(value)
        ? (Set.of(_checked)..remove(value))
        : (Set.of(_checked)..add(value)),
  );

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
                  child: Text(
                    widget.title.value,
                    style: theme.typography.heading,
                  ),
                ),
              ),
              ...widget.options.map(
                (option) => Semantics(
                  checked: _checked.contains(option.value),
                  child: NaMenuTile(
                    key: Key('na-multi-option-${option.label.value}'),
                    icon: _checked.contains(option.value)
                        ? NaIcons.checked
                        : NaIcons.unchecked,
                    label: option.label.value,
                    selected: _checked.contains(option.value)
                        ? NaSelection.selected
                        : NaSelection.unselected,
                    onTap: () => _toggle(option.value),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    NaDialogTextButton(
                      key: const Key('na-multi-option-cancel'),
                      label: widget.cancelLabel,
                      onTap: widget.onCancelled,
                    ),
                    NaDialogTextButton(
                      key: const Key('na-multi-option-confirm'),
                      label: widget.confirmLabel,
                      onTap: () =>
                          widget.onConfirmed(Set.unmodifiable(_checked)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class NaDialogTextButton extends StatelessWidget {
  const NaDialogTextButton({
    required this.label,
    required this.onTap,
    super.key,
  });

  final NaLabel label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label.value,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: ExcludeSemantics(
            child: Text(
              label.value.toUpperCase(),
              textAlign: TextAlign.center,
              style: NaTheme.of(context).typography.label,
            ),
          ),
        ),
      ),
    ),
  );
}
