// expect_lint: avoid_material_cupertino_import
import 'package:flutter/cupertino.dart';
// expect_lint: avoid_material_cupertino_import
import 'package:flutter/material.dart';

final class Empty extends StatelessWidget {
  const Empty({super.key});

  @override
  Widget build(final BuildContext context) => const SizedBox();
}
