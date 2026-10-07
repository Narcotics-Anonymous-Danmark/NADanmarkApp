import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_icons.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

final class NaNote extends StatelessWidget {
  const NaNote({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.noteSurface,
        border: Border(
          left: BorderSide(color: theme.colors.noteAccent, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(NaIcons.note, size: 18, color: theme.colors.noteInk),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                text,
                style: theme.typography.body.copyWith(
                  color: theme.colors.noteInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
