import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_testing/na_testing.dart';

Future<void> pumpFramed(
  WidgetTester tester,
  Widget child, {
  double width = 360,
}) => tester.pumpWidget(
  NaTheme(
    data: NaThemeData.light(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: NaThemeData.light().typography.body,
        child: ColoredBox(
          color: NaColors.light.background,
          child: goldenFrame(width: width, child: child),
        ),
      ),
    ),
  ),
);
