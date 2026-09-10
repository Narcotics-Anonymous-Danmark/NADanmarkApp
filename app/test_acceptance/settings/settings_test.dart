@Tags(['acceptance'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';

import '../support/pump_app.dart';

const language = Key('settings-language');
const firstDay = Key('settings-first-day');
const unitOrder = Key('settings-unit-order');
const slider = Key('settings-search-range-slider');

Future<void> tapSliderAt({
  required WidgetTester tester,
  required double fraction,
}) async {
  final rect = tester.getRect(find.byKey(slider));
  final x = (rect.left + 12 + fraction * (rect.width - 24)).clamp(
    rect.left + 1,
    rect.right - 1,
  );
  await tester.tapAt(Offset(x, rect.center.dy));
  await tester.pumpAndSettle();
}

void main() {
  group('Requirement: Language setting', () {
    testWidgets('Default language is Danish', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      expect(tester.widget<NaListRow>(find.byKey(language)).value, 'Dansk');
    });

    testWidgets('Switching to English re-renders immediately', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      await chooseOption(tester: tester, row: language, option: 'Engelsk');
      expect(pageText('Settings'), findsOneWidget);
      expect(tester.widget<NaListRow>(find.byKey(language)).value, 'English');
      expect(app.storage.snapshot['language'], 'en');
    });
  });

  group('Requirement: First day of week setting', () {
    testWidgets('Default is Monday', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      expect(tester.widget<NaListRow>(find.byKey(firstDay)).value, 'Mandag');
    });

    testWidgets('Sunday first is persisted', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      await chooseOption(tester: tester, row: firstDay, option: 'Søndag');
      expect(app.storage.snapshot['firstday'], 'su');
    });
  });

  group('Requirement: Cleantime unit order setting', () {
    testWidgets('Default unit order', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      expect(
        tester.widget<NaListRow>(find.byKey(unitOrder)).value,
        'år - måneder - dage',
      );
    });

    testWidgets('Days first is persisted', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      await chooseOption(
        tester: tester,
        row: unitOrder,
        option: 'dage - måneder - år',
      );
      expect(app.storage.snapshot['cleanTimeUnitSort'], 'dmy');
    });
  });

  group('Requirement: Default search radius setting', () {
    testWidgets('Default radius is 15 km', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      expect(tester.widget<NaSlider>(find.byKey(slider)).value, 15);
      expect(find.text('Standard søgeradius = 15 km'), findsOneWidget);
      expect(find.text('5 km'), findsOneWidget);
      expect(find.text('50 km'), findsOneWidget);
    });

    testWidgets('Radius is persisted on release', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      await tapSliderAt(tester: tester, fraction: 25 / 45);
      expect(app.storage.snapshot['searchRange'], '30');
      expect(find.text('Standard søgeradius = 30 km'), findsOneWidget);
    });

    testWidgets('Radius bounds', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      await tapSliderAt(tester: tester, fraction: -0.2);
      expect(app.storage.snapshot['searchRange'], '5');
      await tapSliderAt(tester: tester, fraction: 1.2);
      expect(app.storage.snapshot['searchRange'], '50');
    });
  });

  group('Requirement: Selector dialogs', () {
    testWidgets('Cancel keeps the value', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      final writesBefore = app.storage.writes.length;
      await tester.tap(find.byKey(language));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuller'));
      await tester.pumpAndSettle();
      expect(tester.widget<NaListRow>(find.byKey(language)).value, 'Dansk');
      expect(app.storage.writes.length, writesBefore);
    });
  });

  group('Requirement: Typed settings store', () {
    testWidgets('Malformed stored value falls back', (tester) async {
      final app = await pumpApp(
        tester: tester,
        initialLocation: '/settings',
        container: realJftContainer(storedValues: {'searchRange': 'abc'}),
      );
      addTearDown(app.dispose);
      expect(tester.widget<NaSlider>(find.byKey(slider)).value, 15);
      expect(app.storage.snapshot['searchRange'], '15');
    });
  });
}
