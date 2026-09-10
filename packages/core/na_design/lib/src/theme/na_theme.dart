import 'package:flutter/widgets.dart';
import 'package:na_design/src/tokens/na_colors.dart';
import 'package:na_design/src/tokens/na_motion.dart';
import 'package:na_design/src/tokens/na_typography.dart';

final class NaThemeData {
  const NaThemeData({
    required this.colors,
    required this.typography,
    required this.motion,
  });

  factory NaThemeData.light() => NaThemeData(
    colors: NaColors.light,
    typography: NaTypography.plex(colors: NaColors.light),
    motion: NaMotion.standard,
  );

  final NaColors colors;
  final NaTypography typography;
  final NaMotion motion;
}

final class NaTheme extends InheritedWidget {
  const NaTheme({required this.data, required super.child, super.key});

  final NaThemeData data;

  static NaThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<NaTheme>();
    return switch (theme) {
      final NaTheme found => found.data,
      null => throw StateError('NaTheme is missing above this widget'),
    };
  }

  @override
  bool updateShouldNotify(NaTheme oldWidget) => oldWidget.data != data;
}
