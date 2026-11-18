@Tags(['widget'])
library;

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';

import '../support/framed.dart';

final MemoryImage pixel = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwAD'
    'hgGAWjR9awAAAABJRU5ErkJggg==',
  ),
);

Future<void> pumpThumbnail(WidgetTester tester, NaThumbnailImage image) =>
    pumpFramed(
      tester,
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: NaThumbnail(image: image, fallback: pixel),
      ),
    );

void main() {
  group('NaThumbnail', () {
    testWidgets('no image shows the fallback at thumbnail size', (
      tester,
    ) async {
      await pumpThumbnail(tester, const NaNoImage());
      expect(find.byKey(const Key('thumbnail-fallback')), findsOneWidget);
      expect(find.byKey(const Key('thumbnail-remote')), findsNothing);
      expect(
        tester.getSize(find.byType(NaThumbnail)),
        const Size.square(NaThumbnail.size),
      );
    });

    testWidgets('a remote image that fails shows the fallback', (
      tester,
    ) async {
      await pumpThumbnail(
        tester,
        NaRemoteImage(uri: Uri.parse('https://images.test/missing.jpg')),
      );
      expect(find.byKey(const Key('thumbnail-remote')), findsOneWidget);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.byKey(const Key('thumbnail-fallback')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('thumbnails are hidden from semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpThumbnail(tester, const NaNoImage());
      expect(
        tester.getSemantics(find.byType(NaThumbnail)).label,
        isEmpty,
      );
      handle.dispose();
    });
  });
}
