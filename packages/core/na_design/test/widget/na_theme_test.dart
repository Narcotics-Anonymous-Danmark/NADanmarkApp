@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';

Widget aThemedProbe({required void Function(NaThemeData data) onBuild}) =>
    NaTheme(
      data: NaThemeData.light(),
      child: Builder(
        builder: (context) {
          onBuild(NaTheme.of(context));
          return const SizedBox.shrink();
        },
      ),
    );

void main() {
  group('NaTheme', () {
    testWidgets('exposes the light tokens to descendants', (tester) async {
      late NaThemeData seen;
      await tester.pumpWidget(aThemedProbe(onBuild: (data) => seen = data));
      expect(seen.colors.primary, const Color(0xFF0A61AD));
      expect(seen.typography.body.fontFamily, 'packages/na_design/Plex');
    });

    testWidgets('fails loudly when missing', (tester) async {
      await tester.pumpWidget(
        Builder(builder: (context) => Text('${NaTheme.of(context)}')),
      );
      expect(tester.takeException(), isA<StateError>());
    });
  });
}
