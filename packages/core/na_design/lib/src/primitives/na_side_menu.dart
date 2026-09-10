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
            child: ListView(padding: EdgeInsets.zero, children: entries),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: footer,
          ),
        ],
      ),
    );
  }
}
