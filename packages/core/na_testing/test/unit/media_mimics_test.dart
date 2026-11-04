@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';
import 'package:test/test.dart';

final EngineItem item = EngineItem(
  url: AudioUrl(Uri.parse('https://audio.test/a.mp3')),
  title: const TrackTitle('A'),
);

({AudioEngineMimic engine, TestTime time, List<EngineEvent> events})
engineWith({
  EngineStart start = EngineStart.whenPlayed,
  MediaLength length = const UnknownLength(),
}) {
  final time = TestTime.copenhagen(startAt: anInstant());
  final engine = AudioEngineMimic(
    time: time,
    start: start,
    reportedLength: length,
  );
  final events = <EngineEvent>[];
  engine.events.listen(events.add);
  addTearDown(engine.dispose);
  return (engine: engine, time: time, events: events);
}

void main() {
  group('AudioEngineMimic', () {
    test('a played item runs, reports its length and ticks', () async {
      final setup = engineWith(length: KnownLength(duration: 3.seconds));
      final token = await setup.engine.load(item: item, startAt: 1.seconds);
      await setup.engine.play();
      setup.time.advance(by: 1.seconds);
      expect(setup.events.map((event) => event.runtimeType), [
        EngineRunning,
        EngineLength,
        EnginePosition,
      ]);
      expect(setup.events.every((event) => event.token == token), isTrue);
      expect(setup.engine.position, 2.seconds);
      setup.time.advance(by: 1.seconds);
      expect(setup.events.last, isA<EngineEnded>());
      expect(setup.engine.loads.single.startAt, 1.seconds);
    });

    test('an item on cue waits until it is run', () async {
      final setup = engineWith(start: EngineStart.onCue);
      await setup.engine.load(item: item, startAt: Duration.zero);
      await setup.engine.play();
      setup.time.advance(by: 5.seconds);
      expect(setup.events, isEmpty);
      setup.engine.run();
      expect(setup.events.single, isA<EngineRunning>());
    });

    test('pause, seek, release and failure are recorded', () async {
      final setup = engineWith();
      await setup.engine.load(item: item, startAt: Duration.zero);
      await setup.engine.play();
      await setup.engine.pause();
      setup.time.advance(by: 3.seconds);
      expect(setup.events.whereType<EnginePosition>(), isEmpty);
      await setup.engine.play();
      await setup.engine.seek(position: 30.seconds);
      await setup.engine.release();
      setup.engine.fail(detail: const EngineFailureDetail('404'));
      setup.engine.emit(event: EngineEnded(token: setup.engine.token));
      expect(setup.engine.seeks, [30.seconds]);
      expect(setup.engine.pauses, const CallCount(1));
      expect(setup.engine.plays, const CallCount(2));
      expect(setup.engine.releases, const CallCount(1));
      expect(setup.engine.playback, EnginePlayback.stopped);
      expect(setup.events.whereType<EngineFailed>().single.detail.text, '404');
      expect(
        setup.engine.loads.single,
        EngineLoad(
          item: item,
          startAt: Duration.zero,
          token: setup.engine.token,
        ),
      );
      expect(setup.engine.loads.single.toString(), contains('a.mp3'));
      expect(setup.engine.loads.single.hashCode, isNot(0));
    });
  });

  group('MediaSessionMimic', () {
    test('records shown tracks, updates and commands', () async {
      final session = MediaSessionMimic();
      addTearDown(session.dispose);
      final commands = <RemoteCommand>[];
      session.commands.listen(commands.add);
      const track = SessionTrack(
        id: TrackId('a'),
        title: TrackTitle('A'),
        album: PlaylistTitle('B'),
        cover: NoCover(),
        length: UnknownLength(),
        kind: PlaylistKind.speak,
        previous: Neighbour.unavailable,
        next: Neighbour.unavailable,
      );
      const playback = SessionPlayback(
        status: ActiveStatus.playing,
        position: Duration.zero,
      );
      await session.show(track: track, playback: playback);
      await session.update(playback: playback);
      session.press(command: const RemotePause());
      await session.hide();
      expect(session.lastTrack, track);
      expect(session.lastPlayback, playback);
      expect(session.playbacks, hasLength(2));
      expect(commands.single, isA<RemotePause>());
      expect(session.visibility, SessionVisibility.hidden);
      expect(session.hides, const CallCount(1));
    });
  });

  group('Library mimics and builders', () {
    test('synthetic books and readings load', () async {
      final books = AudiobooksMimic.synthetic();
      final loaded = await books.load(book: AudiobookId.howAndWhy);
      expect(
        loaded,
        Ok<Audiobook, Failure>(value: anAudiobook(id: AudiobookId.howAndWhy)),
      );
      books.serve(
        book: AudiobookId.howAndWhy,
        outcome: const Err(error: UnavailableFailure(what: 'x')),
      );
      expect(
        await books.load(book: AudiobookId.howAndWhy),
        isA<Err<Audiobook, Failure>>(),
      );
      books.books = const {};
      expect(
        await books.load(book: AudiobookId.basicText),
        isA<Err<Audiobook, Failure>>(),
      );
      expect(books.loads, const CallCount(3));
      final readings = await ReadingsMimic.synthetic().load();
      expect(
        readings,
        isA<Ok<ReadingCollection, Failure>>().having(
          (ok) => ok.value.readings.length,
          'readings',
          2,
        ),
      );
      expect(
        aReadingCollection(readings: [aReading()]).readings.single.title,
        const ReadingTitle('Hvem er en addict?'),
      );
    });

    test('media builders produce playlists and stored points', () {
      expect(aBookPlaylist().tracks, hasLength(5));
      expect(aSpeakPlaylist().id, aSpeakUrl);
      expect(aSpeakPlaylist().tracks.single.id.value, aSpeakUrl.value);
      expect(aMediaTrack().label, const DurationLabel('8:10'));
      final stored = aStoredResumePoint(point: aResumePoint());
      expect(stored.keys, [
        'mediaResume.book.basic-text',
        'mediaResume.index.book',
      ]);
      expect(
        aLegacyResumeDump().mediaResume?.keys,
        ['mediaResume.book.basic-text'],
      );
      expect(
        aLegacyResumeDump(
          entries: const {'mediaResume.book.x': ResumePointDto()},
        ).mediaResume?.keys,
        ['mediaResume.book.x'],
      );
    });
  });
}
