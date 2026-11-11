import 'package:flutter/widgets.dart';
import 'package:na_design/src/primitives/na_button.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_spacing.dart';
import 'package:na_design/src/values/na_values.dart';

sealed class NaMessageAction {
  const NaMessageAction();
}

final class NaMessageButton extends NaMessageAction {
  const NaMessageButton({required this.label, required this.onPressed});

  final NaLabel label;
  final VoidCallback onPressed;
}

final class NoMessageAction extends NaMessageAction {
  const NoMessageAction();
}

final class NaMessageBlock extends StatelessWidget {
  const NaMessageBlock({
    required this.title,
    required this.body,
    required this.action,
    super.key,
  });

  final NaLabel title;
  final NaLabel body;
  final NaMessageAction action;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title.value,
              textAlign: TextAlign.center,
              style: theme.typography.heading.copyWith(color: theme.colors.ink),
            ),
            const SizedBox(height: Space.sm),
            Text(
              body.value,
              textAlign: TextAlign.center,
              style: theme.typography.body,
            ),
            ...switch (action) {
              NaMessageButton(:final label, :final onPressed) => [
                const SizedBox(height: Space.lg),
                IntrinsicWidth(
                  child: NaButton(label: label.value, onPressed: onPressed),
                ),
              ],
              NoMessageAction() => const <Widget>[],
            },
          ],
        ),
      ),
    );
  }
}
