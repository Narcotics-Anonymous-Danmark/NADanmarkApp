@Tags(['unit'])
library;

import 'package:feature_audiobooks/feature_audiobooks.dart';
import 'package:feature_media_player/feature_media_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';
import 'package:na_testing/na_testing.dart';

final Audiobook book = anAudiobook();

PlayerActive playing({
  AudiobookId id = AudiobookId.basicText,
  TrackIndex index = const TrackIndex(2),
  ActiveStatus status = ActiveStatus.playing,
}) => PlayerActive(
  playlist: anAudiobook(id: id).playlist(cover: const NoCover()),
  trackIndex: index,
  status: status,
  position: 30.seconds,
  length: KnownLength(duration: 490.seconds),
);

void main() {
  test('covers and titles follow the book', () async {
    expect(
      AudiobookId.howAndWhy.cover,
      const AssetKey(
        'packages/feature_audiobooks/assets/covers/how-and-why.png',
      ),
    );
    final bundle = RepoAssetBundle.locate();
    for (final id in AudiobookId.values) {
      expect((await bundle.load(id.cover.path)).lengthInBytes, greaterThan(0));
      expect(id.playlistCover, BundledCover(asset: id.cover));
    }
    final l10n = lookupAppLocalizations(Language.danish.locale);
    expect(AudiobookId.values.map((id) => id.title(l10n: l10n)), [
      'Basis Tekst',
      'Det Virker: Hvordan og Hvorfor',
      'Vejledninger i Trinarbejde',
    ]);
  });

  test('live listening is only this book', () {
    expect(
      listeningTo(book: AudiobookId.basicText, player: playing()),
      isA<ListeningLive>(),
    );
    expect(
      listeningTo(
        book: AudiobookId.basicText,
        player: playing(id: AudiobookId.howAndWhy),
      ),
      isA<NotListening>(),
    );
    expect(
      listeningTo(book: AudiobookId.basicText, player: const PlayerIdle()),
      isA<NotListening>(),
    );
  });

  test('book progress needs the book and reads the library', () {
    final library = Loaded(
      value: ResumeLibrary.empty.withIndex(
        kind: PlaylistKind.book,
        index: ResumeIndex.empty.withPoint(
          id: AudiobookId.basicText.playlistId,
          point: aResumePoint(),
        ),
      ),
    );
    expect(
      bookProgressOf(
        book: AudiobookId.basicText,
        loaded: Loaded(value: book),
        library: library,
        player: const PlayerIdle(),
      ),
      isA<SavedBookProgress>(),
    );
    expect(
      bookProgressOf(
        book: AudiobookId.basicText,
        loaded: const Loading(),
        library: library,
        player: const PlayerIdle(),
      ),
      const NoBookProgress(),
    );
    expect(
      savedFor(book: AudiobookId.basicText, library: const Loading()),
      const NotStarted(),
    );
  });

  test('the continue chapter is the playing one, else a valid saved one', () {
    expect(
      continueChapterOf(
        book: book,
        saved: const NotStarted(),
        player: playing(),
      ),
      const ContinueAt(index: TrackIndex(2)),
    );
    expect(
      continueChapterOf(
        book: book,
        saved: ResumeAt(point: aResumePoint(trackIndex: const TrackIndex(3))),
        player: const PlayerIdle(),
      ),
      const ContinueAt(index: TrackIndex(3)),
    );
    expect(
      continueChapterOf(
        book: book,
        saved: ResumeAt(point: aResumePoint(trackIndex: const TrackIndex(9))),
        player: const PlayerIdle(),
      ),
      const NothingToContinue(),
    );
  });

  test('chapter states show live, saved or no progress', () {
    expect(
      chapterStateOf(
        book: book,
        index: const TrackIndex(2),
        saved: const NotStarted(),
        player: playing(),
      ).icon,
      ChapterIcon.pause,
    );
    expect(
      chapterStateOf(
        book: book,
        index: const TrackIndex(2),
        saved: const NotStarted(),
        player: playing(status: ActiveStatus.paused),
      ),
      ChapterState(
        progress: TrackProgress.live(
          position: 30.seconds,
          length: KnownLength(duration: 490.seconds),
        ),
        icon: ChapterIcon.play,
      ),
    );
    expect(
      chapterStateOf(
        book: book,
        index: const TrackIndex(4),
        saved: ResumeAt(point: aResumePoint()),
        player: const PlayerIdle(),
      ).progress,
      isA<ResumeProgress>(),
    );
    expect(
      chapterStateOf(
        book: book,
        index: const TrackIndex(1),
        saved: ResumeAt(point: aResumePoint()),
        player: playing(),
      ).progress,
      const NoProgress(),
    );
  });

  test('the loader holds the book or the failure', () async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    harness.audiobooks.serve(
      book: AudiobookId.howAndWhy,
      outcome: const Err(error: UnavailableFailure(what: 'x')),
    );
    expect(
      harness.read(audiobookProvider(AudiobookId.basicText)),
      isA<Loading<Audiobook>>(),
    );
    harness.read(audiobookProvider(AudiobookId.howAndWhy));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(
      harness.read(audiobookProvider(AudiobookId.basicText)),
      Loaded(value: anAudiobook()),
    );
    expect(
      harness.read(audiobookProvider(AudiobookId.howAndWhy)),
      isA<Failed<Audiobook>>(),
    );
  });
}
