import 'package:flutter/widgets.dart';
import 'package:na_design/src/flutter_bridge/na_multi_option_dialog.dart';
import 'package:na_design/src/primitives/na_dialog_surface.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_radii.dart';
import 'package:na_design/src/tokens/na_spacing.dart';
import 'package:na_design/src/values/na_values.dart';

extension type const NaInputText(String value) {}

sealed class NaTextEntry {
  const NaTextEntry();
}

final class NaTextEntered extends NaTextEntry {
  const NaTextEntered({required this.text});

  final NaInputText text;
}

final class NaTextCancelled extends NaTextEntry {
  const NaTextCancelled();
}

Future<NaTextEntry> showNaTextInputDialog({
  required BuildContext context,
  required NaLabel title,
  required NaLabel placeholder,
  required NaInputText initialText,
  required NaLabel cancelLabel,
  required NaLabel confirmLabel,
}) => showNaDialog<NaTextEntry>(
  context: context,
  barrierLabel: cancelLabel,
  dismissed: const NaTextCancelled(),
  builder: (dialogContext) => NaTextInputSheet(
    title: title,
    placeholder: placeholder,
    initialText: initialText,
    cancelLabel: cancelLabel,
    confirmLabel: confirmLabel,
    onDone: (entry) => Navigator.of(dialogContext).pop(entry),
  ),
);

final class NaTextInputSheet extends StatefulWidget {
  const NaTextInputSheet({
    required this.title,
    required this.placeholder,
    required this.initialText,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onDone,
    super.key,
  });

  final NaLabel title;
  final NaLabel placeholder;
  final NaInputText initialText;
  final NaLabel cancelLabel;
  final NaLabel confirmLabel;
  final ValueChanged<NaTextEntry> onDone;

  @override
  State<NaTextInputSheet> createState() => _NaTextInputSheetState();
}

final class _NaTextInputSheetState extends State<NaTextInputSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText.value,
  );
  final FocusNode _focus = FocusNode();

  NaAvailability get _confirm => _controller.text.trim().isEmpty
      ? NaAvailability.disabled
      : NaAvailability.enabled;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_changed)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  void _submit() => switch (_confirm) {
    NaAvailability.enabled => widget.onDone(
      NaTextEntered(text: NaInputText(_controller.text.trim())),
    ),
    NaAvailability.disabled => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return NaDialogSurface(
      children: [
        NaDialogTitle(title: widget.title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colors.border),
              borderRadius: BorderRadius.circular(Radius.button),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Semantics(
                textField: true,
                label: widget.placeholder.value,
                child: Stack(
                  children: [
                    if (_controller.text.isEmpty)
                      ExcludeSemantics(
                        child: Text(
                          widget.placeholder.value,
                          style: theme.typography.body.copyWith(
                            color: theme.colors.inkMuted,
                          ),
                        ),
                      ),
                    EditableText(
                      key: const Key('na-text-input'),
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      style: theme.typography.body.copyWith(
                        color: theme.colors.ink,
                      ),
                      cursorColor: theme.colors.primary,
                      backgroundCursorColor: theme.colors.inkMuted,
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        NaDialogActions(
          children: [
            NaDialogTextButton(
              key: const Key('na-dialog-cancel'),
              label: widget.cancelLabel,
              availability: NaAvailability.enabled,
              onTap: () => widget.onDone(const NaTextCancelled()),
            ),
            NaDialogTextButton(
              key: const Key('na-dialog-confirm'),
              label: widget.confirmLabel,
              availability: _confirm,
              onTap: _submit,
            ),
          ],
        ),
      ],
    );
  }
}
