import 'package:flutter/animation.dart';
import 'package:meta/meta.dart';

@immutable
final class NaMotion {
  const NaMotion({
    required this.fast,
    required this.normal,
    required this.slow,
    required this.curve,
  });

  static const standard = NaMotion(
    fast: Duration(milliseconds: 120),
    normal: Duration(milliseconds: 220),
    slow: Duration(milliseconds: 360),
    curve: Curves.easeOutCubic,
  );

  final Duration fast;
  final Duration normal;
  final Duration slow;
  final Curve curve;
}
