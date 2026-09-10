import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';
import 'package:na_design/src/tokens/na_colors.dart';

@immutable
final class NaTypography {
  const NaTypography({
    required this.display,
    required this.title,
    required this.heading,
    required this.body,
    required this.label,
    required this.caption,
    required this.footnote,
  });

  factory NaTypography.plex({required NaColors colors}) {
    const family = 'Plex';
    const package = 'na_design';
    TextStyle style({required double size, required Color color}) => TextStyle(
      fontFamily: family,
      package: package,
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color,
    );
    return NaTypography(
      display: style(size: 24, color: colors.ink),
      title: style(size: 22, color: colors.ink),
      heading: style(size: 18, color: colors.primary),
      body: style(size: 16, color: colors.inkMuted),
      label: style(size: 14, color: colors.primary),
      caption: style(size: 12, color: colors.inkMuted),
      footnote: style(size: 10, color: colors.inkMuted),
    );
  }

  final TextStyle display;
  final TextStyle title;
  final TextStyle heading;
  final TextStyle body;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle footnote;
}
