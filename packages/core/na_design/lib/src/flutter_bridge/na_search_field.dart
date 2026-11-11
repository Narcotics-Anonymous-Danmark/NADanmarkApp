import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:na_design/src/flutter_bridge/na_text_input_dialog.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_icons.dart';
import 'package:na_design/src/tokens/na_radii.dart';
import 'package:na_design/src/tokens/na_spacing.dart';
import 'package:na_design/src/values/na_values.dart';

final class NaSearchField extends StatefulWidget {
  const NaSearchField({
    required this.text,
    required this.placeholder,
    required this.clearLabel,
    required this.onChanged,
    super.key,
  });

  final NaInputText text;
  final NaLabel placeholder;
  final NaLabel clearLabel;
  final ValueChanged<NaInputText> onChanged;

  @override
  State<NaSearchField> createState() => _NaSearchFieldState();
}

final class _NaSearchFieldState extends State<NaSearchField> {
  final FocusNode _focus = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller
      ..text = widget.text.value
      ..addListener(_changed);
  }

  @override
  void didUpdateWidget(NaSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text.value != _controller.text) {
      _controller.text = widget.text.value;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_changed)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    if (_controller.text != widget.text.value) {
      widget.onChanged(NaInputText(_controller.text));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.onPrimary,
        border: Border.all(color: theme.colors.background),
        borderRadius: BorderRadius.circular(Radius.button),
      ),
      child: Row(
        children: [
          const SizedBox(width: Space.md),
          ExcludeSemantics(
            child: Icon(NaIcons.search, size: 20, color: theme.colors.inkMuted),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Semantics(
              textField: true,
              label: widget.placeholder.value,
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  if (_controller.text.isEmpty)
                    ExcludeSemantics(
                      child: Text(
                        widget.placeholder.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.body.copyWith(
                          color: theme.colors.inkMuted,
                        ),
                      ),
                    ),
                  EditableText(
                    key: const Key('na-search-input'),
                    controller: _controller,
                    focusNode: _focus,
                    textInputAction: TextInputAction.search,
                    style: theme.typography.body.copyWith(
                      color: theme.colors.ink,
                    ),
                    cursorColor: theme.colors.primary,
                    backgroundCursorColor: theme.colors.inkMuted,
                    onSubmitted: (_) => _focus.unfocus(),
                  ),
                ],
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            Semantics(
              button: true,
              label: widget.clearLabel.value,
              child: GestureDetector(
                key: const Key('na-search-clear'),
                behavior: HitTestBehavior.opaque,
                onTap: _controller.clear,
                child: SizedBox.square(
                  dimension: 48,
                  child: Icon(
                    NaIcons.dismiss,
                    size: 20,
                    color: theme.colors.inkMuted,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }
}
