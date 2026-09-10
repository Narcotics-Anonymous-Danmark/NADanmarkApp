import 'dart:ui';

import 'package:meta/meta.dart';

@immutable
final class NaColors {
  const NaColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.onPrimary,
    required this.ink,
    required this.inkMuted,
    required this.border,
    required this.danger,
    required this.success,
    required this.warning,
  });

  static const light = NaColors(
    background: Color(0xFFDDDDDD),
    surface: Color(0xFFEEEEEE),
    primary: Color(0xFF0A61AD),
    secondary: Color(0xFF0B77D3),
    onPrimary: Color(0xFFFFFFFF),
    ink: Color(0xFF1D3030),
    inkMuted: Color(0xFF2F4F4F),
    border: Color(0xFF0A61AD),
    danger: Color(0xFFF04141),
    success: Color(0xFF10DC60),
    warning: Color(0xFFFFCE00),
  );

  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color onPrimary;
  final Color ink;
  final Color inkMuted;
  final Color border;
  final Color danger;
  final Color success;
  final Color warning;
}
