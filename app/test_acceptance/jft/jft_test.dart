@Tags(['acceptance'])
library;

import 'package:feature_jft/feature_jft.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

import '../support/pump_app.dart';

TestContainer containerOn({
  required int month,
  required int day,
  int year = 2026,
}) => realJftContainer(
  time: TestTime.copenhagen(
    startAt: anInstant(year: year, month: month, day: day),
  ),
);

void main() {
  group('Requirement: Bundled entries', () {
    testWidgets('Every day has an entry', (tester) async {
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      final loaded = await app.container.read(jftPortProvider).load();
      final calendar = (loaded as Ok<JftCalendar, Failure>).value;
      expect(calendar.entries, hasLength(366));
      expect(calendar.missingDays, isEmpty);
    });
  });

  group("Requirement: Today's entry", () {
    testWidgets('Entry for the current date', (tester) async {
      final app = await pumpApp(
        tester: tester,
        initialLocation: '/jft',
        container: containerOn(month: 5, day: 3),
      );
      addTearDown(app.dispose);
      expect(find.text('3. maj'), findsOneWidget);
    });

    testWidgets('Leap day', (tester) async {
      final app = await pumpApp(
        tester: tester,
        initialLocation: '/jft',
        container: containerOn(year: 2028, month: 2, day: 29),
      );
      addTearDown(app.dispose);
      expect(find.text('29. februar'), findsOneWidget);
    });
  });

  group('Requirement: Full page layout', () {
    testWidgets('Page fields in order', (tester) async {
      final app = await pumpApp(
        tester: tester,
        initialLocation: '/jft',
        container: containerOn(month: 1, day: 1),
      );
      addTearDown(app.dispose);
      expect(pageText('Dagens tekst'), findsOneWidget);
      expect(find.text('1. januar'), findsOneWidget);
      expect(find.text('Årvågenhed'), findsOneWidget);
      final closing = tester.widget<Text>(find.byKey(const Key('jft-closing')));
      final lead = switch (closing.textSpan) {
        TextSpan(children: [final TextSpan first, ...]) => first,
        final InlineSpan? other => fail('unexpected closing span: $other'),
      };
      expect(lead.text, 'Bare for i dag:');
      expect(lead.style?.fontWeight, FontWeight.w700);
      final dateY = tester.getTopLeft(find.byKey(const Key('jft-date'))).dy;
      final titleY = tester.getTopLeft(find.byKey(const Key('jft-title'))).dy;
      final closingY = tester
          .getTopLeft(find.byKey(const Key('jft-closing')))
          .dy;
      expect(dateY, lessThan(titleY));
      expect(titleY, lessThan(closingY));
      await scrollPageTo(tester, find.byKey(const Key('jft-copyright')));
      const copyright =
          'Copyright (c) 2007-2026, NA World Services, Inc. '
          'All Rights Reserved';
      expect(find.text(copyright), findsOneWidget);
    });
  });

  group('Requirement: Home preview card', () {
    testWidgets('Preview is clipped', (tester) async {
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      final clip = find.byType(NaFadeClip);
      expect(clip, findsOneWidget);
      expect(tester.getSize(clip).height, lessThanOrEqualTo(120));
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('Preview opens the page', (tester) async {
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      await tester.tap(find.byKey(const Key('jft-preview-card')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('jft-copyright')), findsOneWidget);
      expect(find.byType(JftPreviewCard), findsNothing);
    });
  });

  group('Requirement: Text remains Danish', () {
    testWidgets('English UI keeps Danish text', (tester) async {
      final app = await pumpApp(
        tester: tester,
        initialLocation: '/jft',
        container: realJftContainer(
          storedValues: {'language': 'en'},
          time: TestTime.copenhagen(startAt: anInstant(month: 1, day: 1)),
        ),
      );
      addTearDown(app.dispose);
      expect(pageText('Just for today'), findsOneWidget);
      expect(find.text('Årvågenhed'), findsOneWidget);
      expect(find.text('1. januar'), findsOneWidget);
    });
  });
}
