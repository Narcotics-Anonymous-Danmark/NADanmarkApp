@Tags(['widget'])
library;

import 'package:feature_settings/feature_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_testing/na_testing.dart';

Future<TestContainer> pumpSettings(WidgetTester tester) async {
  final harness = TestContainer.build();
  addTearDown(harness.dispose);
  await harness.read(settingsControllerProvider.notifier).load();
  await pumpFeature(
    tester: tester,
    harness: harness,
    child: const SettingsBody(),
  );
  return harness;
}

void main() {
  testWidgets('shows the current values of all four settings', (tester) async {
    await pumpSettings(tester);
    expect(
      tester
          .widget<NaListRow>(find.byKey(const Key('settings-language')))
          .value,
      'Dansk',
    );
    expect(
      tester
          .widget<NaListRow>(find.byKey(const Key('settings-first-day')))
          .value,
      'Mandag',
    );
    expect(
      tester
          .widget<NaListRow>(find.byKey(const Key('settings-unit-order')))
          .value,
      'år - måneder - dage',
    );
    expect(find.text('Standard søgeradius = 15 km'), findsOneWidget);
  });

  testWidgets('picking an option persists it, cancel does not', (tester) async {
    final harness = await pumpSettings(tester);
    await tester.tap(find.byKey(const Key('settings-first-day')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Søndag').last);
    await tester.pumpAndSettle();
    expect(harness.storage.snapshot['firstday'], 'su');
    await tester.tap(find.byKey(const Key('settings-unit-order')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuller'));
    await tester.pumpAndSettle();
    expect(harness.storage.snapshot['cleanTimeUnitSort'], 'ymd');
    await tester.tap(find.byKey(const Key('settings-unit-order')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('dage - måneder - år').last);
    await tester.pumpAndSettle();
    expect(harness.storage.snapshot['cleanTimeUnitSort'], 'dmy');
    await tester.tap(find.byKey(const Key('settings-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Engelsk').last);
    await tester.pumpAndSettle();
    expect(harness.storage.snapshot['language'], 'en');
  });

  testWidgets(
    'dragging the slider updates the caption and persists on release',
    (tester) async {
      final harness = await pumpSettings(tester);
      final rect = tester.getRect(
        find.byKey(const Key('settings-search-range-slider')),
      );
      final gesture = await tester.startGesture(
        Offset(rect.left + 12, rect.center.dy),
      );
      await gesture.moveTo(Offset(rect.right - 12, rect.center.dy));
      await tester.pump();
      expect(find.text('Standard søgeradius = 50 km'), findsOneWidget);
      expect(harness.storage.snapshot['searchRange'], '15');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(harness.storage.snapshot['searchRange'], '50');
    },
  );
}
