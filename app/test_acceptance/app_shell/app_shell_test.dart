@Tags(['acceptance'])
library;

import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_testing/na_testing.dart';

import '../support/meetings.dart';
import '../support/pump_app.dart';

void main() {
  group('Requirement: Side menu entries', () {
    testWidgets('Menu lists the twelve entries in legacy order', (
      tester,
    ) async {
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      await openMenu(tester);
      final labels = MenuDestination.values
          .map(
            (d) => tester
                .widget<NaMenuTile>(find.byKey(Key('menu-${d.name}')))
                .label,
          )
          .toList();
      expect(labels, [
        'Hjem',
        'Kort',
        'Møder i nærheden',
        'Mødeliste',
        'Dagens tekst',
        'Cleantimeberegner',
        'Arrangementer',
        'Lydbøger',
        'Speaks',
        'Gruppeoplæsninger',
        'Indstillinger',
        'Om denne app / Kontakt',
      ]);
      final tops = MenuDestination.values
          .map((d) => tester.getTopLeft(find.byKey(Key('menu-${d.name}'))).dy)
          .toList();
      expect(tops, List.of(tops)..sort());
    });

    testWidgets('Menu entry navigates and closes the menu', (tester) async {
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('menu-events')));
      await tester.pumpAndSettle();
      expect(pageText('Arrangementer'), findsOneWidget);
      expect(
        app.container.read(menuControllerProvider),
        NaDrawerVisibility.closed,
      );
      await pressBack(tester);
      expect(find.byKey(const Key('welcome-title')), findsOneWidget);
    });
  });

  group('Requirement: Version display in the menu', () {
    testWidgets('Version row shows the build version', (tester) async {
      final app = await pumpApp(
        tester: tester,
        container: realJftContainer(
          appInfo: anAppInfo(version: '2.0.0'),
        ),
      );
      addTearDown(app.dispose);
      await openMenu(tester);
      expect(find.text('Version: 2.0.0'), findsOneWidget);
    });
  });

  group('Requirement: Routes', () {
    testWidgets('Root redirects to home', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/');
      addTearDown(app.dispose);
      expect(find.byKey(const Key('welcome-title')), findsOneWidget);
    });

    testWidgets('Unknown route falls back to home', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/nowhere');
      addTearDown(app.dispose);
      expect(find.byKey(const Key('welcome-title')), findsOneWidget);
    });

    testWidgets('Municipality sub-page keeps the menu entry', (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        location: '/listfull/K%C3%B8benhavn',
        bmlt: bmltServing(
          meetings: [
            aBmltMeetingJson(id: 1, weekday: 2, municipality: 'København'),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(pageText('København'), findsWidgets);
      await openMenu(tester);
      expect(
        tester
            .widget<NaMenuTile>(find.byKey(const Key('menu-meetings')))
            .selected,
        NaSelection.selected,
      );
    });
  });

  group('Requirement: Page header with menu button', () {
    testWidgets('Header shows title and menu button', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      expect(find.byKey(const Key('menu-button')), findsOneWidget);
      expect(pageText('Indstillinger'), findsOneWidget);
    });
  });

  group('Requirement: Hardware back button', () {
    testWidgets('Back from a page returns home', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      await pressBack(tester);
      expect(find.byKey(const Key('welcome-title')), findsOneWidget);
      expect(app.systemPops, isEmpty);
    });

    testWidgets('Back from a book page returns to the audiobooks list', (
      tester,
    ) async {
      final app = await pumpApp(tester: tester, initialLocation: '/basic-text');
      addTearDown(app.dispose);
      expect(pageText('Basis Tekst'), findsOneWidget);
      await pressBack(tester);
      expect(pageText('Lydbøger'), findsOneWidget);
    });

    testWidgets('Back on home leaves the app', (tester) async {
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      await pressBack(tester);
      expect(app.systemPops, ['SystemNavigator.pop']);
    });

    testWidgets('Back from municipality meetings returns to the list', (
      tester,
    ) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        bmlt: bmltServing(
          municipalities: ['Aarhus'],
          meetings: [
            aBmltMeetingJson(id: 1, weekday: 2, municipality: 'Aarhus'),
          ],
        ),
      );
      addTearDown(app.dispose);
      await pressBack(tester);
      expect(pageText('Meetings'), findsOneWidget);
      expect(find.byKey(const Key('municipality-row-Aarhus')), findsOneWidget);
      expect(app.systemPops, isEmpty);
    });

    testWidgets('Back closes the formats popover first', (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        bmlt: bmltServing(
          meetings: [
            aBmltMeetingJson(id: 1, weekday: 2, municipality: 'Aarhus'),
          ],
        ),
      );
      addTearDown(app.dispose);
      await toggleDay(tester, 'monday');
      await openFormats(tester, 1);
      expect(find.byKey(const Key('formats-popover')), findsOneWidget);
      await pressBack(tester);
      expect(find.byKey(const Key('formats-popover')), findsNothing);
      expect(card(1), findsOneWidget);
      expect(pageText('Aarhus'), findsWidgets);
    });
  });

  group('Requirement: Global loading bar', () {
    testWidgets('Bar stays while any operation is pending', (tester) async {
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      final loading = app.container.read(globalLoadingProvider.notifier)
        ..present(text: 'Locating…')
        ..present(text: 'Finding meetings…');
      await tester.pump();
      expect(find.byKey(const Key('global-loading-bar')), findsOneWidget);
      loading.dismiss();
      await tester.pump();
      expect(find.byKey(const Key('global-loading-bar')), findsOneWidget);
      loading.dismiss();
      await tester.pump();
      expect(find.byKey(const Key('global-loading-bar')), findsNothing);
    });

    testWidgets('Dismiss never goes negative', (tester) async {
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      app.container.read(globalLoadingProvider.notifier).dismiss();
      await tester.pump();
      expect(app.container.read(globalLoadingProvider), const LoadingIdle());
      expect(find.byKey(const Key('global-loading-bar')), findsNothing);
    });
  });

  group('Requirement: Docked media player host', () {
    testWidgets('Player hidden when idle', (tester) async {
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      expect(find.byType(DockedPlayerHost), findsOneWidget);
      expect(tester.getSize(find.byType(DockedPlayerHost)).height, 0);
      expect(
        tester.widget<NaPageFrame>(find.byType(NaPageFrame)).bottomInset,
        0,
      );
    });
  });

  group('Requirement: Language applied at start', () {
    testWidgets('First start is Danish', (tester) async {
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      expect(find.text('Narcotics Anonymous Danmark'), findsOneWidget);
      expect(app.storage.snapshot['language'], 'da');
    });

    testWidgets('Stored English is applied', (tester) async {
      final app = await pumpApp(
        tester: tester,
        container: realJftContainer(storedValues: {'language': 'en'}),
      );
      addTearDown(app.dispose);
      expect(find.text('Narcotics Anonymous Denmark'), findsOneWidget);
      await openMenu(tester);
      expect(inMenu(find.text('Settings')), findsOneWidget);
    });
  });

  group('Requirement: Visual theme', () {
    testWidgets('Cards use the legacy palette', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/contact');
      addTearDown(app.dispose);
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byKey(const Key('contact-about-app')),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFEEEEEE));
      expect(decoration.border?.top.color, const Color(0xFF0A61AD));
      expect(decoration.border?.top.width, 1);
    });
  });
}
