@Tags(['acceptance'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/pump_app.dart';

void main() {
  group('Requirement: Cards in order', () {
    testWidgets('Cards are shown in order', (tester) async {
      final app = await pumpApp(
        tester: tester,
        initialLocation: '/contact',
        container: realJftContainer(
          appInfo: anAppInfo(buildType: 'release'),
        ),
      );
      addTearDown(app.dispose);
      expect(find.byKey(const Key('contact-not-approved')), findsNothing);
      await scrollPageTo(tester, find.byKey(const Key('contact-fine-print')));
      await scrollPageTo(tester, find.byKey(const Key('contact-meeting-list')));
      final tops = [
        'contact-meeting-list',
        'contact-na-online',
        'contact-about-app',
        'contact-fine-print',
      ].map((k) => tester.getTopLeft(find.byKey(Key(k))).dy).toList();
      expect(tops, List.of(tops)..sort());
      expect(find.text('Ændringer til mødelisten'), findsOneWidget);
      expect(find.text('Det med småt'), findsOneWidget);
    });
  });

  group('Requirement: Links', () {
    testWidgets('Website opens externally', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/contact');
      addTearDown(app.dispose);
      await tester.tap(find.byKey(const Key('contact-link-website')));
      await tester.pumpAndSettle();
      expect(app.links.opened.map((u) => u.toString()), [
        'https://nadanmark.dk/',
      ]);
    });

    testWidgets('Mail link opens the mail app', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/contact');
      addTearDown(app.dispose);
      await scrollPageTo(
        tester,
        find.byKey(const Key('contact-link-bug-reports')),
      );
      await tester.tap(find.byKey(const Key('contact-link-bug-reports')));
      await tester.pumpAndSettle();
      expect(app.links.opened.map((u) => u.toString()), [
        'mailto:app@nadanmark.dk',
      ]);
    });
  });

  group('Requirement: Build information', () {
    testWidgets('Release build information', (tester) async {
      final app = await pumpApp(
        tester: tester,
        initialLocation: '/contact',
        container: realJftContainer(
          appInfo: anAppInfo(
            version: VersionName('2.0.0'),
            buildType: 'release',
          ),
        ),
      );
      addTearDown(app.dispose);
      await scrollPageTo(tester, find.byKey(const Key('contact-version')));
      expect(pageText('Buildtype: release'), findsOneWidget);
      expect(pageText('Version: 2.0.0'), findsOneWidget);
    });
  });

  group('Requirement: Not-approved warning', () {
    testWidgets('Warning hidden in approved builds', (tester) async {
      final app = await pumpApp(
        tester: tester,
        initialLocation: '/contact',
        container: realJftContainer(
          appInfo: anAppInfo(approval: BuildApproval.approved),
        ),
      );
      addTearDown(app.dispose);
      expect(find.byKey(const Key('contact-not-approved')), findsNothing);
    });

    testWidgets('Warning shown in trial builds', (tester) async {
      final app = await pumpApp(
        tester: tester,
        initialLocation: '/contact',
        container: realJftContainer(
          appInfo: anAppInfo(approval: BuildApproval.trial),
        ),
      );
      addTearDown(app.dispose);
      final warning = find.byKey(const Key('contact-not-approved'));
      expect(warning, findsOneWidget);
      expect(
        tester.getTopLeft(warning).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('contact-meeting-list'))).dy,
        ),
      );
      expect(find.text('Denne app er [endnu] ikke godkendt!'), findsOneWidget);
    });
  });
}
