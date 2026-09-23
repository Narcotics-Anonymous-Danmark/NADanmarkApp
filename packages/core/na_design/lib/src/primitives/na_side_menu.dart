import 'package:flutter/widgets.dart';
import 'package:na_design/src/primitives/na_header_bar.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

final class NaSideMenu extends StatelessWidget {
  const NaSideMenu({
    required this.title,
    required this.entries,
    required this.footer,
    super.key,
  });

  final String title;
  final List<Widget> entries;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    final insets = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: theme.colors.surface,
      child: Column(
        children: [
          NaHeaderBar(
            leading: const NaHeaderSpacer(),
            title: title,
            trailing: const NaHeaderSpacer(),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                padding: EdgeInsets.only(
                  left: insets.left,
                  bottom: insets.bottom,
                ),
                children: [
                  ...entries,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.lg,
                      vertical: Space.md,
                    ),
                    child: DefaultTextStyle(
                      style: theme.typography.caption.copyWith(
                        color: theme.colors.primary,
                      ),
                      child: footer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
