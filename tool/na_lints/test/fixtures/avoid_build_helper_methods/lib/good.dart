import 'package:flutter/widgets.dart';

final class Page extends StatelessWidget {
  const Page({super.key});

  @override
  Widget build(final BuildContext context) => const Footer();

  Widget wrapped({required final Widget child}) =>
      Semantics(label: _label(), child: child);

  String _label() => 'page';
}

final class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(final BuildContext context) => const SizedBox();
}
