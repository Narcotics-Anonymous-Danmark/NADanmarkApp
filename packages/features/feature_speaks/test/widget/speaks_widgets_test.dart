@Tags(['widget'])
library;

import 'package:feature_speaks/feature_speaks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/harness.dart';

const SpeakSlug sigi = SpeakSlug('kokna-30-hovedspeak-sigi');
const SpeakSlug anders = SpeakSlug('kokna-27-anders');
const SpeakSlug mette = SpeakSlug('viborg-mette');

Finder get scrollView => find.descendant(
  of: find.byType(SpeaksResults),
  matching: find.byType(Scrollable),
);

void main() {
  setUpAll(loadNaFonts);

  group('SpeaksBody', () {
    testWidgets('the loaded list shows sections, counts and meta lines', (
      tester,
    ) async {
      final harness = speaksHarness();
      await pumpSpeaks(tester: tester, harness: harness);
      expect(find.text('12 speaks'), findsOneWidget);
      expect(find.text('KOKNA · København'), findsOneWidget);
      expect(
        inRow(sigi, find.text('Main speak · KOKNA 30 · 2026')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('speak-convention-kokna')), findsOneWidget);
      expect(find.byKey(const Key('speak-continue')), findsNothing);
      await expectGolden(finder: goldenTarget, name: 'speaks_list');
      await expectAccessible(tester);
    });

    testWidgets('the Danish list localises kind titles', (tester) async {
      final harness = speaksHarness();
      await pumpSpeaks(
        tester: tester,
        harness: harness,
        language: Language.danish,
      );
      expect(find.text('Åbningsspeak'), findsOneWidget);
      expect(find.text('12 speaks'), findsOneWidget);
      expect(find.text('Filtre'), findsOneWidget);
    });

    testWidgets('loading shows placeholder rows', (tester) async {
      final harness = speaksHarness();
      final hold = harness.speaksFeed.hold(language: SpeakLanguage.danish);
      await pumpFeature(
        tester: tester,
        harness: harness,
        language: Language.english,
        child: const SpeaksBody(),
      );
      expect(find.byType(NaSkeletonRow), findsNWidgets(8));
      hold.release();
      await settle(tester);
      expect(find.byType(NaSkeletonRow), findsNothing);
    });

    testWidgets('a failed load offers to try again', (tester) async {
      final harness = speaksHarness();
      harness.speaksFeed.failBoth();
      await pumpSpeaks(tester: tester, harness: harness);
      expect(find.text('Could not load the speaks'), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'speaks_failed');
      await expectAccessible(tester);
      harness.speaksFeed.serve(
        language: SpeakLanguage.danish,
        outcome: Ok(
          value: feedGroupsOf(
            dtos: sampleDanishSpeaks,
            language: SpeakLanguage.danish,
          ),
        ),
      );
      await tester.tap(find.text('TRY AGAIN'));
      await settle(tester);
      expect(find.text('9 speaks'), findsOneWidget);
    });

    testWidgets('the filter panel filters by language and resets', (
      tester,
    ) async {
      final harness = speaksHarness();
      await pumpSpeaks(tester: tester, harness: harness);
      await tester.tap(find.byKey(const Key('speak-filters')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('speak-filter-panel')), findsOneWidget);
      expect(find.byKey(const Key('speak-only-started')), findsNothing);
      await expectGolden(finder: goldenTarget, name: 'speaks_filters');
      await expectAccessible(tester);
      await tester.tap(find.byKey(const Key('speak-language-en')));
      await tester.pumpAndSettle();
      expect(find.text('3 speaks'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('speak-filters')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('speak-year-2026')), findsOneWidget);
      expect(find.byKey(const Key('speak-year-2015')), findsNothing);
      await tester.tap(find.byKey(const Key('speak-year-2022')));
      await tester.tap(find.byKey(const Key('speak-sort-name')));
      await tester.pumpAndSettle();
      expect(find.text('1 speaks'), findsOneWidget);
      await tester.tap(find.byKey(const Key('speak-panel-reset')));
      await tester.pumpAndSettle();
      expect(find.text('12 speaks'), findsOneWidget);
      expect(
        harness.read(speakFiltersProvider).selection,
        SpeakSelection.initial,
      );
      await tester.tap(find.byKey(const Key('speak-panel-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('speak-filter-panel')), findsNothing);
    });

    testWidgets('convention chips filter and All clears them', (tester) async {
      final harness = speaksHarness();
      await pumpSpeaks(tester: tester, harness: harness);
      await tester.ensureVisible(
        find.byKey(const Key('speak-convention-eccna')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('speak-convention-eccna')));
      await tester.pumpAndSettle();
      expect(find.text('1 speaks'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('speak-convention-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('speak-convention-all')));
      await tester.pumpAndSettle();
      expect(find.text('12 speaks'), findsOneWidget);
    });

    testWidgets('a search without matches offers to reset', (tester) async {
      final harness = speaksHarness();
      await pumpSpeaks(tester: tester, harness: harness);
      await typeQuery(tester, harness, const SearchInput('zzz'));
      expect(find.text('No speaks found'), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'speaks_empty');
      await tester.tap(find.text('RESET'));
      await tester.pumpAndSettle();
      expect(find.text('12 speaks'), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '',
      );
    });

    testWidgets('continue rows show progress and can be removed', (
      tester,
    ) async {
      final harness = speaksHarness(
        storedValues: storedSpeakPoints([(anders, aSpeakPoint())]),
      );
      await pumpSpeaks(tester: tester, harness: harness);
      final continueRow = find.byKey(Key('speak-continue-${anders.url.value}'));
      expect(continueRow, findsOneWidget);
      expect(
        find.descendant(
          of: continueRow,
          matching: find.text('KOKNA 27 · 2023'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: continueRow,
          matching: find.text('Continue from 4:10 · 5:50 left'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('speak-filters')));
      await tester.pumpAndSettle();
      expect(find.text('Only started (1)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('speak-filters')));
      await tester.pumpAndSettle();
      await expectGolden(finder: goldenTarget, name: 'speaks_continue');
      await expectAccessible(tester);
      await tester.drag(continueRow, const Offset(-200, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from list'));
      await settle(tester);
      expect(continueRow, findsNothing);
      expect(
        harness.storage.snapshot.keys,
        isNot(contains(PlaylistKind.speak.pointKey(id: speakId(anders)).name)),
      );
    });

    testWidgets('tapping a row plays it and tapping again pauses', (
      tester,
    ) async {
      final harness = speaksHarness();
      await pumpSpeaks(tester: tester, harness: harness);
      await tester.tap(rowOf(sigi));
      await settle(tester);
      final player = playerOf(harness);
      expect(player, isA<PlayerActive>());
      final active = player as PlayerActive;
      expect(active.playlist.id, speakId(sigi));
      expect(active.playlist.kind, PlaylistKind.speak);
      expect(inRow(sigi, find.byKey(const Key('speak-icon-pause'))), findsOne);
      expect(inRow(sigi, find.textContaining('Now playing')), findsOneWidget);
      await tester.tap(rowOf(sigi));
      await settle(tester);
      expect(inRow(sigi, find.byKey(const Key('speak-icon-play'))), findsOne);
    });

    testWidgets('typing searches after the debounce', (tester) async {
      final harness = speaksHarness();
      await pumpSpeaks(tester: tester, harness: harness);
      await typeQuery(tester, harness, const SearchInput('engelsk'));
      expect(find.text('3 speaks'), findsOneWidget);
      expect(rowOf(mette), findsNothing);
    });

    testWidgets('pulling down refreshes the feed', (tester) async {
      final harness = speaksHarness();
      await pumpSpeaks(tester: tester, harness: harness);
      await tester.drag(scrollView, const Offset(0, 600));
      await settle(tester);
      expect(harness.speaksFeed.loads, const CallCount(4));
      expect(find.text('12 speaks'), findsOneWidget);
    });

    testWidgets('scrolling to the end loads the next page', (tester) async {
      final harness = speaksHarness();
      harness.speaksFeed
        ..serve(
          language: SpeakLanguage.danish,
          outcome: Ok(
            value: feedGroupsOf(
              dtos: manySpeaks(),
              language: SpeakLanguage.danish,
            ),
          ),
        )
        ..serve(
          language: SpeakLanguage.english,
          outcome: const Ok(value: []),
        );
      await pumpSpeaks(tester: tester, harness: harness);
      expect(find.byKey(const Key('speaks-more')), findsNothing);
      expect(harness.read(speakFiltersProvider).shown, ShownCount.firstPage);
      await tester.drag(scrollView, const Offset(0, -1500));
      await settle(tester);
      expect(harness.read(speakFiltersProvider).shown, const ShownCount(80));
      expect(find.byKey(const Key('speaks-more')), findsNothing);
    });
  });
}
