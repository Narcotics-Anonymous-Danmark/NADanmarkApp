import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';

final class NaPageFrame extends StatelessWidget {
  const NaPageFrame({
    required this.header,
    required this.body,
    required this.bottomInset,
    super.key,
  });

  final Widget header;
  final Widget body;
  final double bottomInset;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: NaTheme.of(context).colors.background,
    child: Column(
      children: [
        header,
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: body,
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
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.zero,
    children: children,
  );
}
