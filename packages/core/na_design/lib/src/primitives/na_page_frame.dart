import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

final class NaPageFrame extends StatelessWidget {
  const NaPageFrame({
    required this.header,
    required this.body,
    required this.footer,
    required this.bottomInset,
    super.key,
  });

  final Widget header;
  final Widget body;
  final Widget footer;
  final double bottomInset;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: NaTheme.of(context).colors.background,
    child: Column(
      children: [
        header,
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: body),
                  footer,
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

final class NaScrollBody extends StatelessWidget {
  const NaScrollBody({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return ListView(
      padding: EdgeInsets.only(
        left: insets.left,
        right: insets.right,
        bottom: insets.bottom,
      ),
      children: children,
    );
  }
}

final class NaFooterBar extends StatelessWidget {
  const NaFooterBar({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        border: Border(top: BorderSide(color: theme.colors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.lg,
          Space.sm + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
