@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/media.dart';

void main() {
  group('Playlist model', () {
    test('duration label parsing', () {
      expect(const DurationLabel('8:10').length, lengthOf(490.seconds));
      expect(const DurationLabel('1:02:03').length, lengthOf(3723.seconds));
      expect(const DurationLabel('13:53:58').length, lengthOf(50038.seconds));
      expect(const DurationLabel('abc').length, const UnknownLength());
      expect(const DurationLabel('').length, const UnknownLength());
      expect(const DurationLabel('1:2:3:4').length, const UnknownLength());
      expect(const DurationLabel('0:00').length, const UnknownLength());
    });

    test('tracks are found by index and by id', () {
      final book = aBook(chapters: const ChapterCount(3));
      expect(
        book.trackAt(index: const TrackIndex(2)),
        isA<FoundTrack>().having(
          (found) => found.track,
          'track',
          book.tracks[2],
        ),
      );
      expect(book.trackAt(index: const TrackIndex(3)), isA<NoTrackAt>());
      expect(book.trackAt(index: const TrackIndex(-1)), isA<NoTrackAt>());
      expect(
        book.trackWithId(id: book.tracks[1].id),
        isA<FoundTrack>().having(
          (found) => found.index,
          'index',
          const TrackIndex(1),
        ),
      );
      expect(
        book.trackWithId(id: const TrackId('gone')),
        isA<NoTrackAt>(),
      );
    });

    test('previous and next exist only inside the playlist', () {
      final book = aBook(chapters: const ChapterCount(3));
      expect(
        book.previousOf(index: const TrackIndex(0)),
        Neighbour.unavailable,
      );
      expect(book.previousOf(index: const TrackIndex(1)), Neighbour.available);
      expect(book.nextOf(index: const TrackIndex(1)), Neighbour.available);
      expect(book.nextOf(index: const TrackIndex(2)), Neighbour.unavailable);
    });

    test('playlists compare by value', () {
      expect(aBook(), aBook());
      expect(aBook().hashCode, aBook().hashCode);
      expect(aBook(), isNot(aBook(chapters: const ChapterCount(2))));
      expect(aBook().toString(), 'MediaPlaylist(book basic-text)');
    });

    test('lengths keep whole seconds and treat zero as unknown', () {
      expect(
        MediaLength.of(duration: const Duration(milliseconds: 490900)),
        lengthOf(490.seconds),
      );
      expect(MediaLength.of(duration: Duration.zero), const UnknownLength());
      expect(const UnknownLength().orZero, Duration.zero);
    });
  });

  group('Play semantics', () {
    TrackStart start({
      required ResumeState resume,
      StartRequest request = const ContinueListening(),
    }) => TrackStart.resolve(
      playlist: aBook(),
      resume: resume,
      request: request,
    );

    test('continue a book', () {
      expect(
        start(resume: ResumeAt(point: aPoint())),
        TrackStart(index: const TrackIndex(4), position: 120.seconds),
      );
    });

    test('explicit other chapter starts at zero', () {
      expect(
        start(
          resume: ResumeAt(point: aPoint()),
          request: const StartTrack(index: TrackIndex(6)),
        ),
        const TrackStart(index: TrackIndex(6), position: Duration.zero),
      );
    });

    test('explicit resume chapter keeps the position', () {
      expect(
        start(
          resume: ResumeAt(point: aPoint()),
          request: const StartTrack(index: TrackIndex(4)),
        ),
        TrackStart(index: const TrackIndex(4), position: 120.seconds),
      );
    });

    test('tiny resume position is dropped', () {
      expect(
        start(
          resume: ResumeAt(point: aPoint(position: 2.seconds)),
        ),
        const TrackStart(index: TrackIndex(4), position: Duration.zero),
      );
    });

    test('stale resume track is found by id', () {
      expect(
        start(
          resume: ResumeAt(
            point: aPoint(
              trackIndex: const TrackIndex(3),
              trackId: chapterId(const TrackIndex(5)),
            ),
          ),
        ),
        TrackStart(index: const TrackIndex(5), position: 120.seconds),
      );
    });

    test('a resume track that no longer exists starts the playlist', () {
      expect(
        start(
          resume: ResumeAt(
            point: aPoint(
              trackIndex: const TrackIndex(3),
              trackId: const TrackId('https://gone.dk/x.mp3'),
            ),
          ),
        ),
        const TrackStart(index: TrackIndex(0), position: Duration.zero),
      );
    });

    test('no resume point starts at the first track', () {
      expect(
        start(resume: const NotStarted()),
        const TrackStart(index: TrackIndex(0), position: Duration.zero),
      );
    });
  });

  group('Player state', () {
    PlayerActive active({MediaLength length = const UnknownLength()}) =>
        PlayerActive(
          playlist: aBook(),
          trackIndex: const TrackIndex(1),
          status: ActiveStatus.playing,
          position: 100.seconds,
          length: length,
        );

    test('seek is clamped', () {
      expect(
        active(length: lengthOf(300.seconds)).clampSeek(target: 400.seconds),
        299.seconds,
      );
      expect(active().clampSeek(target: (-5).seconds), Duration.zero);
      expect(active().clampSeek(target: 400.seconds), 400.seconds);
    });

    test('copies change one field', () {
      final state = active();
      expect(
        state.withStatus(status: ActiveStatus.paused).status,
        ActiveStatus.paused,
      );
      expect(state.withPosition(position: 5.seconds).position, 5.seconds);
      expect(
        state.withLength(length: lengthOf(9.seconds)).length,
        lengthOf(9.seconds),
      );
      expect(state.track, aBook().tracks[1]);
      expect(state, active());
      expect(state.hashCode, active().hashCode);
      expect(const PlayerIdle(), const PlayerIdle());
      expect(state.toString(), contains('basic-text #1 playing 100 s'));
    });
  });

  group('Progress labels shared by lists', () {
    test('continue label', () {
      expect(
        TrackProgress.ofResume(
          resume: ResumeAt(point: aPoint(position: 65.seconds)),
          label: const UnknownLength(),
        ),
        ResumeProgress(
          position: 65.seconds,
          fraction: const KnownFraction(value: 65 / 600),
          remaining: lengthOf(535.seconds),
        ),
      );
    });

    test('the label duration is used when the point has none', () {
      expect(
        TrackProgress.ofResume(
          resume: ResumeAt(
            point: aPoint(position: 95.seconds, length: const UnknownLength()),
          ),
          label: lengthOf(490.seconds),
        ),
        ResumeProgress(
          position: 95.seconds,
          fraction: const KnownFraction(value: 95 / 490),
          remaining: lengthOf(395.seconds),
        ),
      );
    });

    test('no length at all keeps the position only', () {
      expect(
        TrackProgress.ofResume(
          resume: ResumeAt(
            point: aPoint(position: 95.seconds, length: const UnknownLength()),
          ),
          label: const UnknownLength(),
        ),
        ResumeProgress(
          position: 95.seconds,
          fraction: const UnknownFraction(),
          remaining: const UnknownLength(),
        ),
      );
    });

    test('below five seconds or almost finished shows nothing', () {
      expect(
        TrackProgress.ofResume(
          resume: ResumeAt(point: aPoint(position: 4.seconds)),
          label: const UnknownLength(),
        ),
        const NoProgress(),
      );
      expect(
        TrackProgress.ofResume(
          resume: ResumeAt(point: aPoint(position: 598.seconds)),
          label: const UnknownLength(),
        ),
        const NoProgress(),
      );
      expect(
        TrackProgress.ofResume(
          resume: const NotStarted(),
          label: const UnknownLength(),
        ),
        const NoProgress(),
      );
    });

    test('live progress', () {
      expect(
        TrackProgress.live(position: 30.seconds, length: lengthOf(120.seconds)),
        LiveProgress(
          position: 30.seconds,
          length: lengthOf(120.seconds),
          fraction: const KnownFraction(value: 0.25),
        ),
      );
      expect(
        TrackProgress.live(position: 30.seconds, length: const UnknownLength()),
        LiveProgress(
          position: 30.seconds,
          length: const UnknownLength(),
          fraction: const KnownFraction(value: 0),
        ),
      );
    });
  });

  group('Book progress', () {
    final chapters = [
      lengthOf(400.seconds),
      lengthOf(400.seconds),
      lengthOf(500.seconds),
      lengthOf(500.seconds),
      lengthOf(600.seconds),
      lengthOf(600.seconds),
    ];
    const total = 3000;

    test('saved progress label', () {
      expect(
        BookProgress.of(
          chapters: chapters,
          saved: ResumeAt(point: aPoint()),
          listening: const NotListening(),
        ),
        SavedBookProgress(
          chapter: const TrackIndex(4),
          count: const ChapterCount(6),
          fraction: const KnownFraction(value: 1920 / total),
          remaining: lengthOf((total - 1920).seconds),
        ),
      );
    });

    test('fresh book has no progress', () {
      expect(
        BookProgress.of(
          chapters: chapters,
          saved: ResumeAt(
            point: aPoint(trackIndex: const TrackIndex(0), position: 2.seconds),
          ),
          listening: const NotListening(),
        ),
        const NoBookProgress(),
      );
      expect(
        BookProgress.of(
          chapters: chapters,
          saved: const NotStarted(),
          listening: const NotListening(),
        ),
        const NoBookProgress(),
      );
    });

    test('live progress while playing', () {
      expect(
        BookProgress.of(
          chapters: chapters,
          saved: const NotStarted(),
          listening: ListeningLive(
            chapter: const TrackIndex(2),
            position: 0.seconds,
          ),
        ),
        const LiveBookProgress(
          chapter: TrackIndex(2),
          count: ChapterCount(6),
          fraction: KnownFraction(value: 800 / total),
        ),
      );
    });

    test('chapters out of range or an empty book show nothing', () {
      expect(
        BookProgress.of(
          chapters: chapters,
          saved: ResumeAt(point: aPoint(trackIndex: const TrackIndex(6))),
          listening: const NotListening(),
        ),
        const NoBookProgress(),
      );
      expect(
        BookProgress.of(
          chapters: const [],
          saved: ResumeAt(point: aPoint()),
          listening: const NotListening(),
        ),
        const NoBookProgress(),
      );
    });

    test('elapsed time is capped at the total', () {
      expect(
        BookProgress.of(
          chapters: chapters,
          saved: ResumeAt(
            point: aPoint(
              trackIndex: const TrackIndex(5),
              position: 900.seconds,
            ),
          ),
          listening: const NotListening(),
        ),
        const SavedBookProgress(
          chapter: TrackIndex(5),
          count: ChapterCount(6),
          fraction: KnownFraction(value: 1),
          remaining: UnknownLength(),
        ),
      );
    });
  });

  group('Resume points', () {
    test('positions are floored to whole seconds', () {
      final point = ResumePoint(
        trackId: const TrackId('t'),
        trackIndex: const TrackIndex(0),
        position: const Duration(milliseconds: 12999),
        length: const UnknownLength(),
        updatedAt: Instant(DateTime.utc(2026)),
      );
      expect(point.position, 12.seconds);
    });

    test('keys follow the legacy scheme', () {
      expect(
        PlaylistKind.book.pointKey(id: const PlaylistId('basic-text')),
        const StorageKey('mediaResume.book.basic-text'),
      );
      expect(
        PlaylistKind.speak.pointKey(id: const PlaylistId('https://x.dk/a.mp3')),
        const StorageKey('mediaResume.speak.https://x.dk/a.mp3'),
      );
      expect(
        PlaylistKind.speak.indexKey,
        const StorageKey('mediaResume.index.speak'),
      );
    });

    test('the index adds, replaces and removes points', () {
      const id = PlaylistId('how-and-why');
      final index = ResumeIndex.empty.withPoint(id: id, point: aPoint());
      expect(index.stateOf(id: id), ResumeAt(point: aPoint()));
      expect(index.without(id: id).stateOf(id: id), const NotStarted());
      expect(
        index
            .withPoint(
              id: id,
              point: aPoint(position: 9.seconds),
            )
            .points[id],
        aPoint(position: 9.seconds),
      );
      expect(index, ResumeIndex.empty.withPoint(id: id, point: aPoint()));
      expect(
        index.hashCode,
        ResumeIndex.empty.withPoint(id: id, point: aPoint()).hashCode,
      );
    });
  });
}
