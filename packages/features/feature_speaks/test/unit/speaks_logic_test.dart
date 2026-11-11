@Tags(['unit'])
library;

import 'package:feature_speaks/feature_speaks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/harness.dart';

const SpeakSlug sigi = SpeakSlug('kokna-30-hovedspeak-sigi');
const SpeakSlug anders = SpeakSlug('kokna-27-anders');
const SpeakSlug louise = SpeakSlug('kokna-29-afslutning-louise');
const SpeakSlug john = SpeakSlug('kokna-30-main-john');
const SpeakSlug ase = SpeakSlug('camp-2015-ase');
const SpeakSlug mette = SpeakSlug('viborg-mette');

SpeakListing listingOf({
  SpeakCatalog? catalog,
  SpeakSelection selection = SpeakSelection.initial,
  ShownCount shown = ShownCount.firstPage,
  SearchInput typed = const SearchInput(''),
  Set<PlaylistId> started = const {},
}) => SpeakListing.of(
  catalog: catalog ?? sampleSpeakCatalog(),
  filters: SpeakFilters(
    typed: typed,
    selection: selection,
    panel: FilterPanel.closed,
    shown: shown,
  ),
  started: started,
  texts: english,
);

List<String> titlesIn(SpeakListing listing) => listing.sections
    .expand((section) => section.speaks)
    .map((speak) => english.title(speak: speak).value)
    .toList();

List<String> sectionsIn(SpeakListing listing) => listing.sections
    .map((section) => english.section(convention: section.convention).value)
    .toList();

SpeakCatalog catalogWith(List<SpeakEntryDto> speaks) => SpeakCatalog.build(
  groups: feedGroupsOf(
    dtos: [aSpeakGroupDto(speaks: speaks)],
    language: SpeakLanguage.danish,
  ),
  kindWords: testSpeakKindWords,
);

void main() {
  group('SpeaksCatalogLoader', () {
    test('both feeds load into one catalogue, Danish first', () async {
      final harness = speaksHarness();
      final state = await loadedCatalog(harness);
      expect(state, isA<CatalogReady>());
      final catalog = state.catalogOrEmpty;
      expect(catalog.speaks, hasLength(12));
      expect(catalog.speaks.first.language, SpeakLanguage.danish);
      expect(catalog.speaks.last.language, SpeakLanguage.english);
      expect(harness.speaksFeed.loads, const CallCount(2));
    });

    test('one feed failing still loads', () async {
      final harness = speaksHarness();
      harness.speaksFeed.serve(
        language: SpeakLanguage.english,
        outcome: const Err(error: NetworkFailure(detail: 'en')),
      );
      final state = await loadedCatalog(harness);
      expect(state.catalogOrEmpty.speaks, hasLength(9));
      expect(
        state.catalogOrEmpty.speaks.map((speak) => speak.language).toSet(),
        {SpeakLanguage.danish},
      );
    });

    test('both feeds failing fails with the Danish failure', () async {
      final harness = speaksHarness();
      harness.speaksFeed.failBoth();
      expect(
        await loadedCatalog(harness),
        const CatalogFailed(failure: NetworkFailure(detail: 'da')),
      );
      expect(catalogOf(harness), SpeakCatalog.empty);
    });

    test('try again after a failure loads again', () async {
      final harness = speaksHarness();
      harness.speaksFeed.failBoth();
      await loadedCatalog(harness);
      harness.speaksFeed.serve(
        language: SpeakLanguage.danish,
        outcome: Ok(
          value: feedGroupsOf(
            dtos: sampleDanishSpeaks,
            language: SpeakLanguage.danish,
          ),
        ),
      );
      final reload = harness.read(speaksCatalogProvider.notifier).reload();
      expect(harness.read(speaksCatalogProvider), const CatalogLoading());
      await reload;
      expect(catalogOf(harness).speaks, hasLength(9));
    });

    test('a refresh shows progress and keeps the list on failure', () async {
      final harness = speaksHarness();
      final loaded = await loadedCatalog(harness);
      final hold = (harness.speaksFeed..failBoth()).hold(
        language: SpeakLanguage.danish,
      );
      final reload = harness.read(speaksCatalogProvider.notifier).reload();
      expect(
        harness.read(speaksCatalogProvider),
        CatalogReady(
          catalog: loaded.catalogOrEmpty,
          refresh: RefreshState.refreshing,
        ),
      );
      await harness.read(speaksCatalogProvider.notifier).reload();
      hold.release();
      await reload;
      expect(
        harness.read(speaksCatalogProvider),
        CatalogReady(
          catalog: loaded.catalogOrEmpty,
          refresh: RefreshState.idle,
        ),
      );
      expect(harness.speaksFeed.loads, const CallCount(4));
    });

    test('a reload while loading is ignored and the cache is reused', () async {
      final harness = speaksHarness()..read(speaksCatalogProvider);
      await harness.read(speaksCatalogProvider.notifier).reload();
      await flush();
      harness.read(speaksCatalogProvider);
      expect(harness.speaksFeed.loads, const CallCount(2));
    });

    test('kind words hold the labels of both languages', () {
      expect(
        SpeakTexts.kindWords(),
        const SpeakKindWords(
          opening: FoldedText('abningsspeak opening speak'),
          main: FoldedText('hovedspeak main speak'),
          closing: FoldedText('afslutningsspeak closing speak'),
        ),
      );
    });
  });

  group('SpeakFiltersController', () {
    SpeakFilters filtersOf(TestContainer harness) =>
        harness.read(speakFiltersProvider);

    SpeakFiltersController controllerOf(TestContainer harness) {
      harness.container.listen(speakFiltersProvider, (previous, next) {});
      return harness.read(speakFiltersProvider.notifier);
    }

    test('typing applies the query after 200 ms', () {
      final harness = speaksHarness();
      controllerOf(harness).type(text: const SearchInput('kokna'));
      expect(filtersOf(harness).typed, const SearchInput('kokna'));
      expect(filtersOf(harness).selection.query, const SearchInput(''));
      harness.time.advance(by: const Duration(milliseconds: 199));
      expect(filtersOf(harness).selection.query, const SearchInput(''));
      harness.time.advance(by: const Duration(milliseconds: 1));
      expect(filtersOf(harness).selection.query, const SearchInput('kokna'));
    });

    test('toggles add and remove values and reset pages', () {
      final harness = speaksHarness();
      final controller = controllerOf(harness)
        ..showMore(after: ShownCount.firstPage)
        ..toggleLanguage(language: SpeakLanguage.english)
        ..toggleConvention(convention: const ConventionKey('kokna'))
        ..toggleYear(year: const SpeakYear(2026))
        ..toggleYear(year: const SpeakYear(2025))
        ..toggleYear(year: const SpeakYear(2026))
        ..toggleOnlyStarted()
        ..sortBy(sort: SpeakSort.name);
      expect(
        filtersOf(harness).selection,
        const SpeakSelection(
          query: SearchInput(''),
          languages: {SpeakLanguage.english},
          conventions: {ConventionKey('kokna')},
          years: {SpeakYear(2025)},
          onlyStarted: OnlyStarted.on,
          sort: SpeakSort.name,
        ),
      );
      expect(filtersOf(harness).shown, ShownCount.firstPage);
      controller
        ..clearLanguages()
        ..clearConventions()
        ..clearYears()
        ..toggleOnlyStarted();
      expect(
        filtersOf(harness).selection,
        SpeakSelection.initial.withSort(sort: SpeakSort.name),
      );
    });

    test('reset clears everything and drops a pending query', () {
      final harness = speaksHarness();
      controllerOf(harness)
        ..toggleLanguage(language: SpeakLanguage.danish)
        ..type(text: const SearchInput('sigi'))
        ..reset();
      harness.time.advance(by: SpeakFilters.queryDelay);
      expect(filtersOf(harness).typed, const SearchInput(''));
      expect(filtersOf(harness).selection, SpeakSelection.initial);
    });

    test('show more adds one page per position', () {
      final harness = speaksHarness();
      controllerOf(harness)
        ..showMore(after: ShownCount.firstPage)
        ..showMore(after: ShownCount.firstPage);
      expect(filtersOf(harness).shown, const ShownCount(80));
    });

    test('the panel opens and closes', () {
      final harness = speaksHarness();
      final controller = controllerOf(harness)..togglePanel();
      expect(filtersOf(harness).panel, FilterPanel.open);
      controller.togglePanel();
      expect(filtersOf(harness).panel, FilterPanel.closed);
    });

    test('filters and selections compare by value', () {
      expect(
        SpeakFilters.initial,
        SpeakFilters.initial.withShown(
          shown: ShownCount.firstPage,
        ),
      );
      expect(SpeakFilters.initial.toString(), contains('newest'));
      expect(
        SpeakSelection.initial.hashCode,
        SpeakSelection.initial.withQuery(query: const SearchInput('')).hashCode,
      );
      expect(const SearchInput('  ').presence, TextPresence.blank);
    });
  });

  group('SpeakListing', () {
    test('Newest first within a convention', () {
      final listing = listingOf();
      expect(sectionsIn(listing), [
        'KOKNA · København',
        'Konvent-camp Skanderborg',
        'Viborg online møder',
        'Blandede speak',
        'ECCNA',
      ]);
      expect(titlesIn(listing).take(6), [
        'John',
        'Opening speak',
        'Sigi',
        'Louise',
        'Sarah',
        'Anders',
      ]);
      expect(titlesIn(listing).skip(8).take(2), ['Mette', 'Main speak']);
      expect(listing.matchCount, const SpeakCount(12));
      expect(listing.more, MoreSpeaks.none);
      expect(listing.inUse, FiltersInUse.no);
    });

    test('oldest first keeps unknown dates last', () {
      final listing = listingOf(
        selection: SpeakSelection.initial.withSort(sort: SpeakSort.oldest),
      );
      expect(titlesIn(listing).take(6), [
        'Anders',
        'Sarah',
        'Louise',
        'John',
        'Opening speak',
        'Sigi',
      ]);
      expect(titlesIn(listing).skip(8).take(2), ['Mette', 'Main speak']);
    });

    test('Name sort folds Danish letters', () {
      final listing = listingOf(
        catalog: catalogWith([
          sampleSpeak(
            slug: const SpeakSlug('a'),
            name: const FeedText('Åse'),
            location: const FeedText('KOKNA 1'),
            year: const FeedText('2020'),
          ),
          sampleSpeak(
            slug: const SpeakSlug('b'),
            name: const FeedText('Bo'),
            location: const FeedText('KOKNA 1'),
            year: const FeedText('2021'),
          ),
          sampleSpeak(
            slug: const SpeakSlug('c'),
            name: const FeedText('Anders'),
            location: const FeedText('KOKNA 1'),
            year: const FeedText('2019'),
          ),
        ]),
        selection: SpeakSelection.initial.withSort(sort: SpeakSort.name),
      );
      expect(titlesIn(listing), ['Anders', 'Åse', 'Bo']);
    });

    test('All terms must match', () {
      final listing = listingOf(
        selection: SpeakSelection.initial.withQuery(
          query: const SearchInput(' KOKNA  2026 '),
        ),
        typed: const SearchInput('kokna 2026'),
      );
      expect(titlesIn(listing), ['John', 'Opening speak', 'Sigi']);
      expect(listing.inUse, FiltersInUse.yes);
      expect(listing.activeFilters, const FilterCount(0));
    });

    test('Language words are searchable', () {
      final listing = listingOf(
        selection: SpeakSelection.initial.withQuery(
          query: const SearchInput('engelsk'),
        ),
      );
      expect(titlesIn(listing), ['John', 'Sarah', 'Mike']);
    });

    test('Kind words in both languages are searchable', () {
      final listing = listingOf(
        selection: SpeakSelection.initial.withQuery(
          query: const SearchInput('hovedspeak'),
        ),
      );
      expect(titlesIn(listing), ['John', 'Sigi', 'Main speak']);
    });

    test('Convention chip filters the list', () {
      final listing = listingOf(
        selection: SpeakSelection.initial.withConventions(
          conventions: {const ConventionKey('kokna')},
        ),
      );
      expect(sectionsIn(listing), ['KOKNA · København']);
      expect(listing.activeFilters, const FilterCount(1));
    });

    test('a convention missing after a reload is ignored', () {
      final listing = listingOf(
        selection: SpeakSelection.initial.withConventions(
          conventions: {const ConventionKey('gone')},
        ),
      );
      expect(listing.matchCount, const SpeakCount(12));
      expect(listing.activeFilters, const FilterCount(0));
    });

    test('Year options follow other filters', () {
      final english = listingOf(
        selection: SpeakSelection.initial.withLanguages(
          languages: {SpeakLanguage.english},
        ),
      );
      expect(english.yearOptions, const [
        SpeakYear(2026),
        SpeakYear(2024),
        SpeakYear(2022),
      ]);
      final withYear = listingOf(
        selection: SpeakSelection.initial
            .withLanguages(languages: {SpeakLanguage.english})
            .withYears(years: {const SpeakYear(1998)}),
      );
      expect(withYear.yearOptions.first, const SpeakYear(2026));
      expect(withYear.yearOptions.last, const SpeakYear(1998));
      expect(withYear.matchCount, const SpeakCount(0));
      expect(withYear.activeFilters, const FilterCount(2));
    });

    test('years filter by the speak year', () {
      final listing = listingOf(
        selection: SpeakSelection.initial.withYears(
          years: {const SpeakYear(2022)},
        ),
      );
      expect(titlesIn(listing), ['Mette', 'Mike']);
    });

    test('only started keeps the started speaks', () {
      final listing = listingOf(
        selection: SpeakSelection.initial.withOnlyStarted(
          onlyStarted: OnlyStarted.on,
        ),
        started: {speakId(anders), speakId(mette)},
      );
      expect(titlesIn(listing), ['Anders', 'Mette']);
      expect(listing.activeFilters, const FilterCount(1));
    });

    test('Second page', () {
      final catalog = SpeakCatalog.build(
        groups: feedGroupsOf(
          dtos: manySpeaks(),
          language: SpeakLanguage.danish,
        ),
        kindWords: testSpeakKindWords,
      );
      final first = listingOf(catalog: catalog);
      expect(first.sections.single.speaks, hasLength(40));
      expect(first.more, MoreSpeaks.available);
      expect(
        listingOf(
          catalog: catalog,
          shown: const ShownCount(80),
        ).sections.single.speaks,
        hasLength(80),
      );
      final last = listingOf(catalog: catalog, shown: const ShownCount(120));
      expect(last.sections.single.speaks, hasLength(100));
      expect(last.more, MoreSpeaks.none);
    });

    test('listings compare by value', () {
      expect(listingOf(), listingOf());
      expect(listingOf().hashCode, listingOf().hashCode);
      expect(listingOf().toString(), contains('12'));
      expect(listingOf().sections.first.toString(), contains('kokna'));
    });
  });

  group('SpeakResumes', () {
    ResumeIndex indexOf(List<(SpeakSlug, ResumePoint)> points) => points.fold(
      ResumeIndex.empty,
      (index, entry) => index.withPoint(id: speakId(entry.$1), point: entry.$2),
    );

    test('Most recent first, capped at ten', () {
      final catalog = SpeakCatalog.build(
        groups: feedGroupsOf(
          dtos: manySpeaks(count: const RowCount(12)),
          language: SpeakLanguage.danish,
        ),
        kindWords: testSpeakKindWords,
      );
      final resumes = SpeakResumes.of(
        catalog: catalog,
        index: indexOf([
          for (final index in List.generate(12, (index) => index))
            (
              SpeakSlug('many-$index'),
              aSpeakPoint(
                slug: SpeakSlug('many-$index'),
                updatedAt: Instant(DateTime.utc(2026, 1, index + 1)),
              ),
            ),
        ]),
        active: const NoActiveSpeak(),
      );
      expect(resumes.continueList, hasLength(10));
      expect(
        resumes.continueList.first.id,
        const SpeakSlug('many-11').url.id,
      );
      expect(resumes.startedCount, const SpeakCount(12));
    });

    test('the active speak comes first and counts as started', () {
      final resumes = SpeakResumes.of(
        catalog: sampleSpeakCatalog(),
        index: indexOf([(anders, aSpeakPoint())]),
        active: ActiveSpeakOf(id: speakId(sigi)),
      );
      expect(resumes.continueList.map((speak) => speak.id), [
        speakId(sigi),
        speakId(anders),
      ]);
      expect(resumes.started, {speakId(sigi), speakId(anders)});
    });

    test('short, finished and unknown points are left out', () {
      final resumes = SpeakResumes.of(
        catalog: sampleSpeakCatalog(),
        index: indexOf([
          (anders, aSpeakPoint(position: const Duration(seconds: 4))),
          (
            louise,
            aSpeakPoint(slug: louise, position: const Duration(minutes: 10)),
          ),
          (const SpeakSlug('unknown'), aSpeakPoint()),
        ]),
        active: ActiveSpeakOf(id: const SpeakSlug('unknown').url.id),
      );
      expect(resumes, SpeakResumes.none);
      expect(resumes.hashCode, SpeakResumes.none.hashCode);
    });

    test('only speak playlists are active speaks', () {
      expect(
        ActiveSpeak.of(
          player: PlayerActive(
            playlist: aBookPlaylist(),
            trackIndex: const TrackIndex(0),
            status: ActiveStatus.playing,
            position: Duration.zero,
            length: const UnknownLength(),
          ),
        ),
        const NoActiveSpeak(),
      );
      expect(
        ActiveSpeak.of(player: const PlayerIdle()),
        const NoActiveSpeak(),
      );
      expect(
        const ActiveSpeakOf(id: aSpeakUrl).hashCode,
        const ActiveSpeakOf(id: aSpeakUrl).hashCode,
      );
    });
  });

  group('SpeakRowView', () {
    PlayerActive playing({
      ActiveStatus status = ActiveStatus.playing,
      PlaylistId id = aSpeakUrl,
    }) => PlayerActive(
      playlist: aSpeakPlaylist(url: id),
      trackIndex: const TrackIndex(0),
      status: status,
      position: const Duration(minutes: 2),
      length: const KnownLength(duration: Duration(minutes: 10)),
    );

    test('the active speak shows live progress and its status', () {
      final view = SpeakRowView.of(
        playback: SpeakPlayback.of(id: aSpeakUrl, player: playing()),
        saved: const NotStarted(),
      );
      expect(view.icon, SpeakIcon.pause);
      expect(view.tone, RowTone.started);
      expect(view.progress, isA<LiveProgress>());
      expect(
        SpeakRowView.of(
          playback: SpeakPlayback.of(
            id: aSpeakUrl,
            player: playing(status: ActiveStatus.loading),
          ),
          saved: const NotStarted(),
        ).icon,
        SpeakIcon.loading,
      );
      expect(
        SpeakRowView.of(
          playback: SpeakPlayback.of(
            id: aSpeakUrl,
            player: playing(status: ActiveStatus.paused),
          ),
          saved: const NotStarted(),
        ).icon,
        SpeakIcon.play,
      );
    });

    test('other speaks show their resume point', () {
      final playback = SpeakPlayback.of(
        id: speakId(anders),
        player: playing(),
      );
      expect(playback, const NotPlayingSpeak());
      final view = SpeakRowView.of(
        playback: playback,
        saved: ResumeAt(point: aSpeakPoint()),
      );
      expect(view.icon, SpeakIcon.play);
      expect(view.tone, RowTone.started);
      expect(view.progress, isA<ResumeProgress>());
      expect(
        SpeakRowView.of(playback: playback, saved: const NotStarted()),
        const SpeakRowView(
          icon: SpeakIcon.play,
          progress: NoProgress(),
          tone: RowTone.plain,
        ),
      );
      expect(view.toString(), contains('play'));
    });

    test('playbacks compare by value', () {
      expect(
        SpeakPlayback.of(id: aSpeakUrl, player: playing()),
        SpeakPlayback.of(id: aSpeakUrl, player: playing()),
      );
      expect(
        SpeakPlayback.of(id: aSpeakUrl, player: playing()).hashCode,
        SpeakPlayback.of(id: aSpeakUrl, player: playing()).hashCode,
      );
      expect(
        const NotPlayingSpeak().hashCode,
        const NotPlayingSpeak().hashCode,
      );
    });

    test('a speak plays as one track without a known length', () {
      final speak = sampleSpeakAt(slug: sigi);
      final playlist = speakPlaylist(
        speak: speak,
        trackTitle: english.trackTitle(speak: speak),
        cover: speakCover,
      );
      expect(playlist.id, speakId(sigi));
      expect(playlist.kind, PlaylistKind.speak);
      expect(playlist.title, const PlaylistTitle('KOKNA - København'));
      expect(playlist.cover, speakCover);
      expect(playlist.tracks.single.id, TrackId(sigi.url.value));
      expect(
        playlist.tracks.single.title,
        const TrackTitle('Sigi · Main speak · KOKNA 30 · 2026'),
      );
      expect(playlist.tracks.single.label.length, const UnknownLength());
    });
  });

  group('SpeakTexts', () {
    test('Meta with edition and year', () {
      final speak = sampleSpeakAt(slug: sigi);
      expect(english.title(speak: speak).value, 'Sigi');
      expect(
        english.metaLine(speak: speak).value,
        'Main speak · KOKNA 30 · 2026',
      );
    });

    test('Edition shortened by convention label', () {
      expect(
        english.contextLine(speak: sampleSpeakAt(slug: ase)).value,
        'Konvent-camp Skanderborg · 2015',
      );
      expect(english.metaLine(speak: sampleSpeakAt(slug: ase)).value, '2015');
    });

    test('English speaks say so and kind titles are localised', () {
      final johnSpeak = sampleSpeakAt(slug: john);
      expect(
        english.metaLine(speak: johnSpeak).value,
        'Main speak · KOKNA 30 · 2026 · English',
      );
      final danish = SpeakTexts.of(language: Language.danish);
      expect(
        danish.metaLine(speak: johnSpeak).value,
        'Hovedspeak · KOKNA 30 · 2026 · Engelsk',
      );
      final mainOnly = sampleSpeakCatalog().speaks.firstWhere(
        (speak) => speak.title == const KindTitle(kind: SpeakKind.main),
      );
      expect(danish.title(speak: mainOnly).value, 'Hovedspeak');
      expect(english.metaLine(speak: mainOnly).value, '');
      expect(english.contextLine(speak: mainOnly).value, 'Viborg online møder');
      expect(
        danish.language(language: SpeakLanguage.danish).value,
        'Dansk',
      );
      expect(
        english.kind(kind: SpeakKind.closing).value,
        'Closing speak',
      );
    });

    test('titles fall back to the edition and the convention', () {
      final catalog = catalogWith([
        aSpeakEntryDto(
          name: const FeedText(''),
          location: const FeedText('KOKNA 30'),
          url: const SpeakSlug('edition').url,
        ),
        aSpeakEntryDto(
          name: const FeedText(''),
          location: const FeedText('?'),
          year: const FeedText('?'),
          url: const SpeakSlug('convention').url,
        ),
      ]);
      expect(
        catalog.speaks.map((speak) => english.title(speak: speak).value),
        ['KOKNA 30', 'KOKNA'],
      );
    });
  });
}
