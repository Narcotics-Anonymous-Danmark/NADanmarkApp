@Tags(['unit'])
library;

import 'package:feature_media_player/feature_media_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

import '../support/harness.dart';

const PlaylistId basicText = PlaylistId('basic-text');
const PlaylistId howAndWhy = PlaylistId('how-and-why');

Map<String, String> resumeAt({
  TrackIndex index = const TrackIndex(4),
  Duration position = const Duration(seconds: 120),
}) => aStoredResumePoint(
  point: aResumePoint(trackIndex: index, position: position),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Single global player and status', () {
    test('idle at start', () {
      final harness = playerHarness();
      expect(harness.state, const PlayerIdle());
    });
  });

  group('Play semantics', () {
    test('continue a book', () async {
      final harness = playerHarness(storedValues: resumeAt());
      await harness.start();
      expect(harness.active.trackIndex, const TrackIndex(4));
      expect(harness.engine.loads.single.startAt, 120.seconds);
      expect(
        harness.engine.loads.single.item.url.uri.toString(),
        chapterTrackId(index: const TrackIndex(4)).value,
      );
    });

    test('explicit other chapter starts at zero', () async {
      final harness = playerHarness(storedValues: resumeAt());
      await harness.start(request: const StartTrack(index: TrackIndex(2)));
      expect(harness.active.trackIndex, const TrackIndex(2));
      expect(harness.engine.loads.single.startAt, Duration.zero);
    });

    test('tiny resume position is dropped', () async {
      final harness = playerHarness(
        storedValues: resumeAt(position: 2.seconds),
      );
      await harness.start();
      expect(harness.engine.loads.single.startAt, Duration.zero);
    });

    test('stale resume track is found by id', () async {
      final harness = playerHarness(
        storedValues: aStoredResumePoint(
          point: ResumePoint(
            trackId: chapterTrackId(index: const TrackIndex(3)),
            trackIndex: const TrackIndex(1),
            position: 60.seconds,
            length: const UnknownLength(),
            updatedAt: aResumeTime,
          ),
        ),
      );
      await harness.start();
      expect(harness.active.trackIndex, const TrackIndex(3));
      expect(harness.engine.loads.single.startAt, 60.seconds);
    });

    test('the active playlist toggles instead of restarting', () async {
      final harness = playerHarness();
      await harness.start();
      await harness.start();
      expect(harness.active.status, ActiveStatus.paused);
      await harness.start(request: const StartTrack(index: TrackIndex(0)));
      expect(harness.active.status, ActiveStatus.playing);
      expect(harness.engine.loads, hasLength(1));
    });

    test('switching playlists keeps the place of the first', () async {
      final harness = playerHarness();
      await harness.start();
      await harness.advance(42.seconds);
      await harness.start(playlist: aBookPlaylist(id: howAndWhy));
      expect(harness.storedPosition(), 42.seconds);
      expect(harness.active.playlist.id, howAndWhy);
    });

    test('an empty playlist does nothing', () async {
      final harness = playerHarness();
      await harness.start(
        playlist: aBookPlaylist(chapters: const ChapterCount(0)),
      );
      expect(harness.state, const PlayerIdle());
    });
  });

  group('Track start and status transitions', () {
    test('loading then playing', () async {
      final harness = playerHarness(
        storedValues: resumeAt(),
        start: EngineStart.onCue,
      );
      await harness.start();
      expect(harness.active.status, ActiveStatus.loading);
      expect(harness.engine.loads.single.startAt, 120.seconds);
      harness.engine.run();
      await flush();
      expect(harness.active.status, ActiveStatus.playing);
    });

    test('engine length replaces the label', () async {
      final harness = playerHarness();
      harness.engine.reportedLength = KnownLength(duration: 491.seconds);
      await harness.start();
      expect(harness.active.length, KnownLength(duration: 491.seconds));
    });

    test('the label length is used until the engine knows better', () async {
      final harness = playerHarness(start: EngineStart.onCue);
      await harness.start();
      expect(harness.active.length, KnownLength(duration: 490.seconds));
    });

    test('events from a released item are ignored', () async {
      final harness = playerHarness();
      await harness.start();
      final stale = harness.engine.token;
      await harness.player.next();
      await flush();
      harness.engine.emit(event: EngineEnded(token: stale));
      await flush();
      expect(harness.active.trackIndex, const TrackIndex(1));
    });

    test('closing while a track loads does not start it', () async {
      final harness = playerHarness();
      harness.engine.gate = LoadGate.held;
      final starting = harness.player.play(
        playlist: aBookPlaylist(),
        request: const ContinueListening(),
      );
      await flush();
      expect(harness.active.status, ActiveStatus.loading);
      await harness.player.stop();
      harness.engine.openLoads();
      await starting;
      await flush();
      expect(harness.state, const PlayerIdle());
      expect(harness.engine.plays, const CallCount(0));
    });

    test('positions while paused are ignored', () async {
      final harness = playerHarness();
      await harness.start();
      await harness.player.pause();
      harness.engine.emit(
        event: EnginePosition(
          token: harness.engine.token,
          position: 90.seconds,
        ),
      );
      await flush();
      expect(harness.active.position, Duration.zero);
    });
  });

  group('Controls', () {
    test('skip forward', () async {
      final harness = playerHarness();
      await harness.start();
      await harness.player.seekTo(position: 100.seconds);
      await harness.player.seekBy(delta: MediaRules.skipForward);
      expect(harness.active.position, 130.seconds);
      expect(harness.engine.seeks.last, 130.seconds);
    });

    test('skip backward stops at zero', () async {
      final harness = playerHarness();
      await harness.start();
      await harness.player.seekBy(delta: -MediaRules.skipBackward);
      expect(harness.active.position, Duration.zero);
    });

    test('seek is clamped', () async {
      final harness = playerHarness();
      harness.engine.reportedLength = KnownLength(duration: 300.seconds);
      await harness.start();
      await harness.player.seekTo(position: 400.seconds);
      expect(harness.active.position, 299.seconds);
      expect(harness.storedPosition(), 299.seconds);
    });

    test('stop keeps the resume point', () async {
      final harness = playerHarness();
      final speak = aSpeakPlaylist();
      await harness.start(playlist: speak);
      await harness.advance(250.seconds);
      await harness.player.stop();
      await flush();
      expect(harness.state, const PlayerIdle());
      expect(
        harness.storedPosition(kind: PlaylistKind.speak, id: speak.id),
        250.seconds,
      );
      expect(harness.engine.releases.value, greaterThanOrEqualTo(2));
      expect(harness.session.visibility, SessionVisibility.hidden);
    });

    test('pause and resume', () async {
      final harness = playerHarness();
      await harness.start();
      await harness.advance(7.seconds);
      await harness.player.pause();
      await flush();
      expect(harness.active.status, ActiveStatus.paused);
      expect(harness.storedPosition(), 7.seconds);
      await harness.player.resume();
      expect(harness.active.status, ActiveStatus.playing);
      await harness.player.resume();
      expect(harness.engine.plays, const CallCount(2));
    });

    test('previous and next stay inside the book', () async {
      final harness = playerHarness();
      await harness.start();
      await harness.player.previous();
      expect(harness.engine.loads, hasLength(1));
      await harness.player.next();
      expect(harness.active.trackIndex, const TrackIndex(1));
      expect(harness.engine.loads.last.startAt, Duration.zero);
      await harness.player.previous();
      expect(harness.active.trackIndex, const TrackIndex(0));
      await harness.start(request: const StartTrack(index: TrackIndex(4)));
      await harness.player.next();
      expect(harness.active.trackIndex, const TrackIndex(4));
    });

    test('controls do nothing while idle', () async {
      final harness = playerHarness();
      await harness.player.pause();
      await harness.player.resume();
      await harness.player.toggle();
      await harness.player.next();
      await harness.player.previous();
      await harness.player.seekTo(position: 5.seconds);
      await harness.player.seekBy(delta: 5.seconds);
      await harness.player.savePlace();
      expect(harness.state, const PlayerIdle());
      expect(harness.storage.writes, isEmpty);
    });
  });

  group('Auto-advance and end of playlist', () {
    test('chapter ends and the next starts', () async {
      final harness = playerHarness(
        storedValues: resumeAt(index: const TrackIndex(2)),
      );
      await harness.start();
      harness.engine.finish();
      await flush();
      expect(harness.active.trackIndex, const TrackIndex(3));
      expect(harness.engine.loads.last.startAt, Duration.zero);
    });

    test('book finishes', () async {
      final harness = playerHarness(
        storedValues: resumeAt(index: const TrackIndex(4)),
      );
      await harness.start();
      harness.engine.finish();
      await flush();
      expect(harness.state, const PlayerIdle());
      expect(harness.stored(), const NotStarted());
      expect(harness.index().points, isEmpty);
    });

    test('error stops and keeps the place', () async {
      final harness = playerHarness();
      await harness.start();
      await harness.advance(40.seconds);
      harness.engine.fail(detail: const EngineFailureDetail('404'));
      await flush();
      expect(harness.state, const PlayerIdle());
      expect(harness.storedPosition(), 40.seconds);
    });
  });

  group('Resume points', () {
    test('periodic save cadence', () async {
      final harness = playerHarness();
      await harness.start();
      await harness.advance(12.seconds);
      final pointKey = PlaylistKind.book.pointKey(id: basicText);
      expect(
        harness.storage.writes.where((key) => key == pointKey),
        hasLength(3),
      );
      expect(harness.storedPosition(), 10.seconds);
    });

    test('index mirrors the point', () async {
      final harness = playerHarness();
      final speak = aSpeakPlaylist();
      await harness.start(playlist: speak);
      await harness.advance(6.seconds);
      expect(
        harness.index(kind: PlaylistKind.speak).stateOf(id: speak.id),
        harness.stored(kind: PlaylistKind.speak, id: speak.id),
      );
    });

    test('malformed point is ignored', () async {
      final harness = playerHarness(
        storedValues: {
          'mediaResume.book.basic-text': '{"trackIndex":"x","position":12}',
        },
      );
      await harness.start();
      expect(harness.active.trackIndex, const TrackIndex(0));
      expect(harness.engine.loads.single.startAt, Duration.zero);
    });

    test('background saves the place', () async {
      final harness = playerHarness();
      harness.container.read(playerLifecycleProvider);
      await harness.start();
      await harness.advance(42.seconds);
      final binding = TestWidgetsFlutterBinding.instance
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await flush();
      expect(harness.storedPosition(), 42.seconds);
      binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
  });

  group('Background playback and lock-screen controls', () {
    test('lock-screen pause', () async {
      final harness = playerHarness();
      await harness.start();
      await harness.advance(9.seconds);
      harness.session.press(command: const RemotePause());
      await flush();
      expect(harness.active.status, ActiveStatus.paused);
      expect(harness.storedPosition(), 9.seconds);
      expect(
        harness.session.lastPlayback,
        SessionPlayback(status: ActiveStatus.paused, position: 9.seconds),
      );
    });

    test('headset toggle', () async {
      final harness = playerHarness();
      await harness.start();
      harness.session.press(command: const RemoteToggle());
      await flush();
      expect(harness.active.status, ActiveStatus.paused);
      harness.session.press(command: const RemotePlay());
      await flush();
      expect(harness.active.status, ActiveStatus.playing);
    });

    test('remote commands map to the controls', () async {
      final harness = playerHarness();
      await harness.start();
      harness.session.press(
        command: const RemoteSeek(position: Duration(seconds: 60)),
      );
      await flush();
      harness.session.press(command: const RemoteSkipForward());
      await flush();
      expect(harness.active.position, 90.seconds);
      harness.session.press(command: const RemoteSkipBackward());
      await flush();
      expect(harness.active.position, 75.seconds);
      harness.session.press(command: const RemoteNext());
      await flush();
      expect(harness.active.trackIndex, const TrackIndex(1));
      harness.session.press(command: const RemotePrevious());
      await flush();
      expect(harness.active.trackIndex, const TrackIndex(0));
      harness.session.press(command: const RemoteStop());
      await flush();
      expect(harness.state, const PlayerIdle());
    });

    test('lock-screen metadata for a book', () async {
      final harness = playerHarness();
      const cover = BundledCover(asset: AssetKey('covers/basic-text.png'));
      await harness.start(playlist: aBookPlaylist(cover: cover));
      expect(
        harness.session.lastTrack,
        SessionTrack(
          id: chapterTrackId(index: const TrackIndex(0)),
          title: const TrackTitle('Chapter 1'),
          album: const PlaylistTitle('Basis Tekst'),
          cover: cover,
          length: KnownLength(duration: 490.seconds),
          kind: PlaylistKind.book,
          previous: Neighbour.unavailable,
          next: Neighbour.available,
        ),
      );
      expect(harness.session.visibility, SessionVisibility.shown);
    });

    test('a speak has no chapter navigation', () async {
      final harness = playerHarness();
      await harness.start(playlist: aSpeakPlaylist());
      expect(harness.session.lastTrack.previous, Neighbour.unavailable);
      expect(harness.session.lastTrack.next, Neighbour.unavailable);
      expect(harness.session.lastTrack.length, const UnknownLength());
    });

    test('elapsed time is published at least every 5 s', () async {
      final harness = playerHarness();
      await harness.start();
      final before = harness.session.playbacks.length;
      await harness.advance(11.seconds);
      expect(harness.session.playbacks.length - before, 2);
      expect(harness.session.lastPlayback.status, ActiveStatus.playing);
    });

    test('permission asked once', () async {
      final harness = playerHarness();
      await harness.start();
      await harness.player.next();
      await flush();
      expect(harness.container.notifications.promptCalls, const CallCount(1));
    });
  });
}
