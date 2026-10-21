@Tags(['widget'])
library;

import 'package:feature_cleantime/feature_cleantime.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/harness.dart';

extension type const FrameHeight(double pixels) {}

final class TapLog {
  CallCount taps = const CallCount(0);

  void record() => taps = taps.next;
}

Future<void> pumpPage({
  required WidgetTester tester,
  required TestContainer harness,
  required Widget child,
  Language language = Language.danish,
  FrameHeight height = const FrameHeight(1500),
}) async {
  await pumpFeature(
    tester: tester,
    harness: harness,
    language: language,
    child: goldenFrame(
      child: SizedBox(
        height: height.pixels,
        child: ColoredBox(color: NaColors.light.background, child: child),
      ),
    ),
  );
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}

List<String> valuesOf(WidgetTester tester) => List.unmodifiable(
  tester
      .widgetList<Text>(find.byKey(const Key('cleantime-value')))
      .map((text) => text.data ?? ''),
);

void main() {
  setUpAll(loadNaFonts);

  group('CleantimeBody', () {
    testWidgets('years, months and days first', (tester) async {
      final harness = cleantimeHarness(
        storedValues: aStoredCleantimeProfiles(entries: [aCleantimeProfile()]),
      );
      await pumpPage(
        tester: tester,
        harness: harness,
        child: const CleantimeBody(),
      );
      expect(valuesOf(tester), [
        '6 år',
        '4 måneder',
        '7 dage',
        '76 måneder',
        '7 dage',
        '2321 dage',
      ]);
      expect(find.byKey(const Key('cleantime-cleanday')), findsNothing);
      await expectGolden(finder: goldenTarget, name: 'cleantime_ymd');
      await expectAccessible(tester);
    });

    testWidgets('days first with the Cleanday card', (tester) async {
      final harness = cleantimeHarness(
        storedValues: {
          'cleanTimeUnitSort': 'dmy',
          ...aStoredCleantimeProfiles(
            entries: [
              aCleantimeProfile(cleanDate: september10.plusYears(years: -1)),
            ],
          ),
        },
      );
      await pumpPage(
        tester: tester,
        harness: harness,
        language: Language.english,
        height: const FrameHeight(1900),
        child: const CleantimeBody(),
      );
      expect(valuesOf(tester).take(3), ['0 days', '0 months', '1 year']);
      expect(find.byKey(const Key('cleantime-cleanday')), findsOneWidget);
      expect(find.bySemanticsLabel('1 year key tag'), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'cleantime_dmy_cleanday');
      await expectAccessible(tester);
    });

    testWidgets('header actions open their dialogs', (tester) async {
      final harness = cleantimeHarness(
        storedValues: aStoredCleantimeProfiles(entries: [aCleantimeProfile()]),
      );
      await pumpPage(
        tester: tester,
        harness: harness,
        child: const CleantimeBody(),
      );
      await tester.tap(find.byKey(const Key('cleantime-add-profile')));
      await tester.pumpAndSettle();
      expect(find.text('Ny profilnavn her'), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'cleantime_add_dialog');
      await tester.tap(find.byKey(const Key('na-dialog-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cleantime-rename-profile')));
      await tester.pumpAndSettle();
      expect(find.text('Omdøb profil'), findsOneWidget);
      await tester.tap(find.byKey(const Key('na-dialog-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cleantime-delete-profile')));
      await tester.pumpAndSettle();
      expect(find.text('Er du sikker?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('na-dialog-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cleantime-profile-selector')));
      await tester.pumpAndSettle();
      expect(find.text('Vælg profil'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cleantime-date-field')));
      await tester.pumpAndSettle();
      expect(find.text('maj'), findsWidgets);
      await expectGolden(finder: goldenTarget, name: 'cleantime_date_picker');
      await tester.tap(find.byKey(const Key('na-dialog-cancel')));
      await tester.pumpAndSettle();
      expect(harness.storage.snapshot['cleantimeProfiles'], contains('Anna'));
    });
  });

  group('CleantimeHomeCards', () {
    Future<void> pumpHome(
      WidgetTester tester,
      TestContainer harness,
      TapLog taps,
    ) => pumpPage(
      tester: tester,
      harness: harness,
      height: const FrameHeight(260),
      child: ColoredBox(
        color: NaColors.light.primary,
        child: CleantimeHomeCards(onTap: taps.record),
      ),
    );

    testWidgets('one card has no dots and opens the calculator', (
      tester,
    ) async {
      final taps = TapLog();
      final harness = cleantimeHarness(
        storedValues: aStoredCleantimeProfiles(entries: [aCleantimeProfile()]),
      );
      await pumpHome(tester, harness, taps);
      expect(find.text('6 år, 4 måneder, 7 dage'), findsOneWidget);
      expect(find.text('03. maj 2020'), findsOneWidget);
      expect(find.byKey(const Key('na-page-dots')), findsNothing);
      await tester.tap(find.byKey(const Key('home-cleantime-card-0')));
      expect(taps.taps, const CallCount(1));
      await expectGolden(finder: goldenTarget, name: 'cleantime_home_card');
      await expectAccessible(tester);
    });

    testWidgets('two profiles show dots', (tester) async {
      final harness = cleantimeHarness(
        storedValues: aStoredCleantimeProfiles(
          entries: [
            aCleantimeProfile(),
            aCleantimeProfile(name: bo),
          ],
        ),
      );
      await pumpHome(tester, harness, TapLog());
      expect(find.byKey(const Key('na-page-dots')), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'cleantime_home_two');
    });

    testWidgets('no profiles show nothing', (tester) async {
      final harness = cleantimeHarness();
      await pumpHome(tester, harness, TapLog());
      expect(find.byKey(const Key('home-cleantime-carousel')), findsNothing);
    });
  });
}
