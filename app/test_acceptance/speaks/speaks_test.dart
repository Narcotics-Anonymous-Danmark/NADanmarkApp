@Tags(['acceptance'])
library;

import 'package:feature_speaks/feature_speaks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/media.dart';
import '../support/pump_app.dart';
import '../support/speaks.dart';

const SpeakSlug sigi = SpeakSlug('kokna-30-hovedspeak-sigi');
const SpeakSlug anders = SpeakSlug('kokna-27-anders');
const SpeakSlug ase = SpeakSlug('camp-2015-ase');
const SpeakSlug mette = SpeakSlug('viborg-mette');
const SpeakSlug peter = SpeakSlug('aalborg-peter');

const String openingRowKey =
    'speak-row-https://audio.test/speaks/KOKNA 30 2026 åbningsspeak.wav';

void main() {
  group('Requirement: Feed', () {
    testWidgets('One feed failing still loads', (tester) async {
      final wordpress =
          feedOf(
            danish: [
              for (final city in ['Aarhus', 'Odense', 'Aalborg'])
                groupOf(
                  title: FeedText('KOKNA - $city'),
                  speaks: [entryOf(slug: SpeakSlug(city))],
                ),
            ],
          )..serve(
            language: SpeakLanguage.english,
            reply: const WordPressError(status: HttpStatus(500)),
          );
      await pumpSpeaksPage(tester: tester, wordpress: wordpress);
      expect(pageText('3 speaks'), findsOneWidget);
      expect(pageText('Could not load the speaks'), findsNothing);
    });

    testWidgets('Both feeds failing is an error', (tester) async {
      final wordpress = WordPressMimic()
        ..serveBoth(reply: const WordPressError(status: HttpStatus(500)));
      await pumpSpeaksPage(tester: tester, wordpress: wordpress);
      expect(pageText('Could not load the speaks'), findsOneWidget);
      expect(
        pageText('Check your internet connection and try again.'),
        findsOneWidget,
      );
      expect(pageText('TRY AGAIN'), findsOneWidget);
    });

    testWidgets('Try again reloads', (tester) async {
      final wordpress = WordPressMimic()
        ..serveBoth(reply: const WordPressUnreachable());
      await pumpSpeaksPage(tester: tester, wordpress: wordpress);
      wordpress
        ..serve(
          language: SpeakLanguage.danish,
          reply: SpeakGroups(groups: sampleDanishSpeaks),
        )
        ..serve(
          language: SpeakLanguage.english,
          reply: SpeakGroups(groups: sampleEnglishSpeaks),
        );
      await tester.tap(pageText('TRY AGAIN'));
      await drain(tester);
      await settle(tester);
      expect(pageText('12 speaks'), findsOneWidget);
    });

    testWidgets('Failed refresh keeps the list', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      page.wordpress.serveBoth(
        reply: const WordPressError(status: HttpStatus(500)),
      );
      await dragList(tester, const Offset(0, 600));
      expect(page.wordpress.requests, hasLength(4));
      expect(pageText('12 speaks'), findsOneWidget);
      expect(pageText('Could not load the speaks'), findsNothing);
    });

    testWidgets('requests carry the excerpt and Basic auth', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      expect(
        page.wordpress.requests.map(
          (request) => request.uri.queryParameters['excerpt[]'],
        ),
        ['NA-SPEAKS-DK', 'NA-SPEAKS-EN'],
      );
      expect(
        page.wordpress.requests.map((request) => request.authorisation),
        everyElement(Authorisation.accepted),
      );
    });
  });

  group('Requirement: Text folding', () {
    testWidgets('Folding Danish letters', (tester) async {
      final page = await pumpSpeaksPage(
        tester: tester,
        wordpress: feedOf(
          danish: [
            groupOf(
              title: const FeedText('KOKNA'),
              speaks: [
                entryOf(
                  slug: const SpeakSlug('folded'),
                  location: const FeedText('  Åbnings-Speak  København '),
                ),
                entryOf(slug: const SpeakSlug('other')),
              ],
            ),
          ],
        ),
      );
      await searchFor(
        tester,
        page.app,
        const SearchInput('abnings-speak kobenhavn'),
      );
      expect(pageText('1 speaks'), findsOneWidget);
      expect(speakRow(const SpeakSlug('folded')), findsOneWidget);
    });

    testWidgets('Tidy strips stray punctuation', (tester) async {
      await pumpSpeaksPage(tester: tester);
      expect(
        inSpeakRow(mette, find.text('Vilborg trin 10-11-12 · 13-02-2022')),
        findsOneWidget,
      );
    });
  });

  group('Requirement: Convention parsing', () {
    testWidgets('Convention with city', (tester) async {
      await pumpSpeaksPage(tester: tester);
      expect(sectionHeader('KOKNA · København'), findsOneWidget);
    });

    testWidgets('Foreign speaks fold into the same convention', (
      tester,
    ) async {
      final page = await pumpSpeaksPage(tester: tester);
      final kokna = listingIn(page.app).sections.singleWhere(
        (section) => section.convention.key == const ConventionKey('kokna'),
      );
      expect(
        kokna.speaks.map((speak) => speak.language).toSet(),
        {SpeakLanguage.danish, SpeakLanguage.english},
      );
      expect(sectionHeader('KOKNA · København'), findsOneWidget);
    });

    testWidgets('Shouty label is sentence-cased', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      await tester.scrollUntilVisible(
        sectionHeader('Blandede speak'),
        300,
        scrollable: find.descendant(
          of: find.byType(SpeaksResults),
          matching: find.byType(Scrollable),
        ),
      );
      expect(sectionHeader('Blandede speak'), findsOneWidget);
      expect(listingIn(page.app).sections, hasLength(5));
    });
  });

  group('Requirement: Date parsing', () {
    testWidgets('Full date', (tester) async {
      await pumpSpeaksPage(tester: tester);
      expect(
        inSpeakRow(mette, find.textContaining('13-02-2022')),
        findsOneWidget,
      );
    });

    testWidgets('Year from the file name', (tester) async {
      await pumpSpeaksPage(tester: tester);
      expect(
        find.descendant(
          of: find.byKey(const Key(openingRowKey)),
          matching: find.text('KOKNA 30 · 2026'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Unknown date', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      final viborg = listingIn(page.app).sections.singleWhere(
        (section) => section.convention.label.text == 'Viborg online møder',
      );
      expect(viborg.speaks.last.date, const UnknownDate());
      expect(viborg.speaks.last.date.sortKey, const SpeakSortKey(0));
    });
  });

  group('Requirement: Kind detection and speaker', () {
    testWidgets('Name carries the kind', (tester) async {
      await pumpSpeaksPage(tester: tester);
      expect(inSpeakRow(sigi, find.text('Sigi')), findsOneWidget);
      expect(
        inSpeakRow(sigi, find.textContaining('Main speak')),
        findsOneWidget,
      );
    });

    testWidgets('Kind from the file name only', (tester) async {
      await pumpSpeaksPage(tester: tester);
      expect(
        find.descendant(
          of: find.byKey(const Key(openingRowKey)),
          matching: find.text('Opening speak'),
        ),
        findsOneWidget,
      );
    });
  });

  group('Requirement: Title, edition and meta lines', () {
    testWidgets('Meta with edition and year', (tester) async {
      await pumpSpeaksPage(tester: tester);
      expect(
        inSpeakRow(sigi, find.text('Main speak · KOKNA 30 · 2026')),
        findsOneWidget,
      );
    });

    testWidgets('Edition shortened by convention label', (tester) async {
      await pumpSpeaksPage(
        tester: tester,
        storedValues: storedSpeakPoints([(ase, speakPointAt(slug: ase))]),
      );
      expect(
        find.descendant(
          of: continueRow(ase),
          matching: find.text('Konvent-camp Skanderborg · 2015'),
        ),
        findsOneWidget,
      );
      expect(inSpeakRow(ase, find.text('2015')), findsOneWidget);
    });
  });

  group('Requirement: Deduplication and catalog', () {
    testWidgets('Duplicate URL kept once', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      expect(pageText('12 speaks'), findsOneWidget);
      final sections = listingIn(page.app).sections;
      expect(
        sections
            .expand((section) => section.speaks)
            .where((speak) => speak.id == sigi.url.id),
        hasLength(1),
      );
      expect(
        sections
            .singleWhere(
              (section) =>
                  section.convention.key ==
                  const ConventionKey(
                    'blandede speak',
                  ),
            )
            .speaks
            .map((speak) => speak.id),
        [peter.url.id],
      );
    });

    testWidgets('Language words are searchable', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      await searchFor(tester, page.app, const SearchInput('engelsk'));
      expect(listedTitles(page.app), ['John', 'Sarah', 'Mike']);
    });

    testWidgets('Kind words in both languages are searchable', (
      tester,
    ) async {
      final page = await pumpSpeaksPage(tester: tester);
      await searchFor(tester, page.app, const SearchInput('hovedspeak'));
      expect(listedTitles(page.app), ['John', 'Sigi', 'Main speak']);
    });
  });

  group('Requirement: Search', () {
    testWidgets('All terms must match', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      await searchFor(tester, page.app, const SearchInput('kokna 2026'));
      expect(listedTitles(page.app), ['John', 'Opening speak', 'Sigi']);
      expect(pageText('3 speaks'), findsOneWidget);
    });
  });

  group('Requirement: Filters and chips', () {
    testWidgets('Convention chip filters the list', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      await tapVisible(tester, const Key('speak-convention-kokna'));
      expect(
        listingIn(page.app).sections.map((section) => section.convention.key),
        [const ConventionKey('kokna')],
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('speak-filters')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Year options follow other filters', (tester) async {
      await pumpSpeaksPage(tester: tester);
      await openFilters(tester);
      await tapVisible(tester, const Key('speak-language-en'));
      final years = find.descendant(
        of: find.byKey(const Key('speak-years')),
        matching: find.byType(Text),
      );
      expect(
        tester.widgetList<Text>(years).map((text) => text.data),
        ['All', '2026', '2024', '2022'],
      );
    });

    testWidgets('Reset clears everything', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      await searchFor(tester, page.app, const SearchInput('kokna'));
      await openFilters(tester);
      await tapVisible(tester, const Key('speak-language-da'));
      await tapVisible(tester, const Key('speak-year-2026'));
      await tapVisible(tester, const Key('speak-sort-name'));
      await tapVisible(tester, const Key('speak-panel-reset'));
      final filters = page.app.container.read(speakFiltersProvider);
      expect(filters.selection, SpeakSelection.initial);
      expect(filters.selection.sort, SpeakSort.newest);
      expect(filters.typed, const SearchInput(''));
      expect(
        tester
            .widget<EditableText>(inPage(find.byType(EditableText)))
            .controller
            .text,
        '',
      );
      expect(pageText('12 speaks'), findsOneWidget);
    });
  });

  group('Requirement: Sorting and grouping', () {
    testWidgets('Newest first within a convention', (tester) async {
      final page = await pumpSpeaksPage(
        tester: tester,
        wordpress: feedOf(
          danish: [
            groupOf(
              title: const FeedText('KOKNA'),
              speaks: [
                entryOf(
                  slug: const SpeakSlug('unknown'),
                  name: const FeedText('Unknown'),
                  location: const FeedText('?'),
                  year: const FeedText('?'),
                ),
                entryOf(
                  slug: const SpeakSlug('old'),
                  name: const FeedText('Old'),
                  year: const FeedText('2025'),
                ),
                entryOf(
                  slug: const SpeakSlug('new'),
                  name: const FeedText('New'),
                ),
              ],
            ),
          ],
        ),
      );
      expect(listedTitles(page.app), ['New', 'Old', 'Unknown']);
      expect(
        listingIn(page.app).sections.single.speaks.map(
          (speak) => speak.date.sortKey,
        ),
        const [SpeakSortKey(20260000), SpeakSortKey(20250000), SpeakSortKey(0)],
      );
    });

    testWidgets('Name sort folds Danish letters', (tester) async {
      final page = await pumpSpeaksPage(
        tester: tester,
        wordpress: feedOf(
          danish: [
            groupOf(
              title: const FeedText('KOKNA'),
              speaks: [
                for (final name in ['Åse', 'Bo', 'Anders'])
                  entryOf(slug: SpeakSlug(name), name: FeedText(name)),
              ],
            ),
          ],
        ),
      );
      await openFilters(tester);
      await tapVisible(tester, const Key('speak-sort-name'));
      expect(listedTitles(page.app), ['Anders', 'Åse', 'Bo']);
    });

    testWidgets('Empty result state', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      await searchFor(tester, page.app, const SearchInput('zzz'));
      expect(pageText('No speaks found'), findsOneWidget);
      expect(
        pageText('Try another search word, or reset the filters.'),
        findsOneWidget,
      );
      expect(pageText('RESET'), findsOneWidget);
    });
  });

  group('Requirement: Paging', () {
    testWidgets('Second page', (tester) async {
      final page = await pumpSpeaksPage(
        tester: tester,
        wordpress: feedOf(danish: manySpeaks()),
      );
      List<Speak> shown() => listingIn(page.app).sections.single.speaks;
      expect(shown(), hasLength(40));
      await dragList(tester, const Offset(0, -100));
      expect(shown(), hasLength(80));
      await dragList(tester, const Offset(0, -100));
      expect(shown(), hasLength(80));
      await dragList(tester, const Offset(0, -3500));
      expect(shown(), hasLength(100));
      expect(listingIn(page.app).more, MoreSpeaks.none);
    });

    testWidgets('a filter change starts again at the top', (tester) async {
      final page = await pumpSpeaksPage(
        tester: tester,
        wordpress: feedOf(danish: manySpeaks()),
      );
      await dragList(tester, const Offset(0, -2500));
      expect(speaksOffset(tester), greaterThan(0));
      await searchFor(tester, page.app, const SearchInput('speaker'));
      expect(listingIn(page.app).sections.single.speaks, hasLength(40));
      expect(speaksOffset(tester), 0);
      expect(pageText('100 speaks'), findsOneWidget);
    });
  });

  group('Requirement: Continue listening', () {
    testWidgets('Most recent first, capped at ten', (tester) async {
      await pumpSpeaksPage(
        tester: tester,
        wordpress: feedOf(danish: manySpeaks(count: const RowCount(12))),
        storedValues: storedSpeakPoints([
          for (final index in List.generate(12, (index) => index))
            (
              SpeakSlug('many-$index'),
              speakPointAt(
                slug: SpeakSlug('many-$index'),
                updatedAt: Instant(DateTime.utc(2026, 1, index + 1)),
              ),
            ),
        ]),
      );
      expect(continueRow(const SpeakSlug('many-11')), findsOneWidget);
      expect(continueRow(const SpeakSlug('many-2')), findsOneWidget);
      expect(continueRow(const SpeakSlug('many-1')), findsNothing);
      expect(continueRow(const SpeakSlug('many-0')), findsNothing);
      expect(
        tester.getTopLeft(continueRow(const SpeakSlug('many-11'))).dy,
        lessThan(tester.getTopLeft(continueRow(const SpeakSlug('many-10'))).dy),
      );
    });

    testWidgets('Swipe forgets the speak', (tester) async {
      final page = await pumpSpeaksPage(
        tester: tester,
        storedValues: storedSpeakPoints([(anders, speakPointAt(slug: anders))]),
      );
      await tester.drag(continueRow(anders), const Offset(-250, 0));
      await tester.pumpAndSettle();
      await tester.tap(pageText('Remove from list'));
      await drain(tester);
      await settle(tester);
      expect(continueRow(anders), findsNothing);
      expect(
        storedPoint(
          page.app,
          kind: PlaylistKind.speak,
          id: anders.url.id,
        ),
        const NotStarted(),
      );
      expect(storedIndex(page.app, kind: PlaylistKind.speak).points, isEmpty);
    });
  });

  group('Requirement: Rows and playback', () {
    testWidgets('Tap plays the speak', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      await tester.tap(speakRow(sigi));
      await drain(tester);
      await settle(tester);
      final active = activeOf(page.app);
      expect(active.playlist.id, sigi.url.id);
      expect(active.playlist.kind, PlaylistKind.speak);
      expect(active.playlist.title, const PlaylistTitle('KOKNA - København'));
      expect(active.playlist.cover, speakCover);
      expect(
        active.track.title,
        const TrackTitle('Sigi · Main speak · KOKNA 30 · 2026'),
      );
      expect(find.byKey(const Key('docked-player')), findsOneWidget);
    });

    testWidgets('Tapping the active row pauses', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      await tester.tap(speakRow(sigi));
      await drain(tester);
      await settle(tester);
      expect(activeOf(page.app).status, ActiveStatus.playing);
      expect(
        inSpeakRow(sigi, find.byKey(const Key('speak-icon-pause'))),
        findsOneWidget,
      );
      await tester.tap(speakRow(sigi));
      await drain(tester);
      await settle(tester);
      expect(activeOf(page.app).status, ActiveStatus.paused);
      expect(
        inSpeakRow(sigi, find.byKey(const Key('speak-icon-play'))),
        findsOneWidget,
      );
    });

    testWidgets('A speak shows its length and can be scrubbed', (
      tester,
    ) async {
      final page = await pumpSpeaksPage(tester: tester);
      page.app.engine.reportedLength = const KnownLength(
        duration: Duration(minutes: 10),
      );
      await tester.tap(speakRow(sigi));
      await drain(tester);
      await settle(tester);
      expect(dockedText(tester, const Key('na-scrubber-length')), '10:00');
      final track = tester.getRect(find.byKey(const Key('na-scrubber-track')));
      final gesture = await tester.startGesture(
        Offset(track.left + 8, track.center.dy),
      );
      await gesture.moveTo(
        Offset(track.left + 8 + (track.width - 16) / 2, track.center.dy),
      );
      await gesture.up();
      await drain(tester);
      await settle(tester);
      expect(page.app.engine.seeks, [const Duration(minutes: 5)]);
      expect(activeOf(page.app).position, const Duration(minutes: 5));
      expect(
        storedPosition(page.app, kind: PlaylistKind.speak, id: sigi.url.id),
        const Duration(minutes: 5),
      );
    });

    testWidgets('Active row shows live progress', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      page.app.engine.reportedLength = const KnownLength(
        duration: Duration(minutes: 10),
      );
      await tester.tap(speakRow(sigi));
      await drain(tester);
      await advance(page.app, tester, const Duration(minutes: 2));
      await settle(tester);
      expect(
        inSpeakRow(sigi, find.text('Now playing · 2:00 / 10:00')),
        findsOneWidget,
      );
    });

    testWidgets('Progress refreshes when the player closes', (tester) async {
      final page = await pumpSpeaksPage(tester: tester);
      page.app.engine.reportedLength = const KnownLength(
        duration: Duration(minutes: 10),
      );
      await tester.tap(speakRow(sigi));
      await drain(tester);
      await advance(page.app, tester, const Duration(minutes: 4, seconds: 10));
      await tester.tap(find.byKey(const Key('player-close')));
      await drain(tester);
      await settle(tester);
      expect(playerOf(page.app), const PlayerIdle());
      expect(
        inSpeakRow(sigi, find.text('Continue from 4:10 · 5:50 left')),
        findsOneWidget,
      );
      expect(continueRow(sigi), findsOneWidget);
    });
  });
}
