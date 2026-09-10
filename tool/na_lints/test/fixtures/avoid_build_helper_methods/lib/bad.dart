import 'package:flutter/widgets.dart';

final class Page extends StatelessWidget {
  const Page({super.key});

  @override
  Widget build(final BuildContext context) => _buildBody();

  // expect_lint: avoid_build_helper_methods
  Widget _buildBody() => buildFooter();

  // expect_lint: avoid_build_helper_methods
  Widget buildFooter() => _row();

  // expect_lint: avoid_build_helper_methods
  SizedBox _row() => const SizedBox();
}

final class Factory {
  const Factory();

  // expect_lint: avoid_build_helper_methods
  Widget buildEmpty() => const SizedBox();
}
