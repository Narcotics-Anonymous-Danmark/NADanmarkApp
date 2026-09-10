@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';

void main() {
  group('tokens', () {
    test('spacing scale is ascending', () {
      final scale = [
        Space.none,
        Space.xs,
        Space.sm,
        Space.md,
        Space.lg,
        Space.xl,
        Space.xxl,
      ];
      expect(scale, [0, 4, 8, 12, 16, 24, 32]);
    });

    test('radii and motion expose their tokens', () {
      expect(Radius.card, 12);
      expect(NaMotion.standard.normal, const Duration(milliseconds: 220));
    });

    test('typography uses the bundled Plex family everywhere', () {
      final typography = NaTypography.plex(colors: NaColors.light);
      final families = [
        typography.title,
        typography.heading,
        typography.body,
        typography.label,
        typography.caption,
      ].map((style) => style.fontFamily).toSet();
      expect(families, {'packages/na_design/Plex'});
    });
  });
}
