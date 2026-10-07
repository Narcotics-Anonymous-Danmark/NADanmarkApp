@Tags(['unit'])
library;

import 'package:flutter/widgets.dart';
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

    test(
      'colours carry the legacy palette, darkened where contrast requires it',
      () {
        expect(NaColors.light.primary, const Color(0xFF0A61AD));
        expect(NaColors.light.secondary, const Color(0xFF0B77D3));
        expect(NaColors.light.tertiary, const Color(0xFF3F4BD9));
        expect(NaColors.light.dark, const Color(0xFF222428));
        expect(NaColors.light.danger, const Color(0xFFB71C1C));
      },
    );

    test('meeting icons are distinct', () {
      expect(
        {
          NaIcons.play,
          NaIcons.add,
          NaIcons.close,
          NaIcons.dismiss,
          NaIcons.note,
          NaIcons.mapPin,
          NaIcons.cloud,
          NaIcons.phone,
          NaIcons.clock,
        },
        hasLength(9),
      );
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
