@Tags(['acceptance'])
library;

import 'package:feature_media_player/feature_media_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

import '../support/media.dart';
import '../support/pump_app.dart';

const RoutePathText basicTextPath = RoutePathText('/basic-text');

extension type const RoutePathText(String value) {}

Future<AppHarness> pumpBook({
  required WidgetTester tester,
  RoutePathText path = basicTextPath,
  Map<String, String> storedValues = const {},
  EngineStart start = EngineStart.whenPlayed,
  MediaLength length = const UnknownLength(),
}) async {
  final container = realJftContainer(
    storedValues: {...inEnglish, ...storedValues},
  );
  container.engine
    ..start = start
    ..reportedLength = length;
  final app = await pumpApp(
    tester: tester,
    initialLocation: path.value,
    container: container,
  );
  addTearDown(app.dispose);
  return app;
}

Finder get docked => find.byKey(const Key('docked-player'));

void main() {
  group('Requirement: Playlist model', () {
    testWidgets('Duration label parsing', (tester) async {
      final app = await pumpBook(tester: tester, start: EngineStart.onCue);
      await tapChapter(tester, const TrackIndex(0));
      expect(dockedText(tester, const Key('na-scrubber-length')), '8:10');
      expect(
        activeOf(app).length,
        const KnownLength(duration: Duration(seconds: 490)),
      );
    });
  });

  group('Requirement: Single global player and status', () {
    testWidgets('Idle at start', (tester) async {
      final app = await pumpBook(tester: tester);
      expect(playerOf(app), const PlayerIdle());
      expect(docked, findsNothing);
    });

    testWidgets('Docked player follows playback across pages', (tester) async {
      final app = await pumpBook(tester: tester);
      await tapChapter(tester, const TrackIndex(1));
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('menu-settings')));
      await settle(tester);
      expect(find.byKey(const Key('settings-language')), findsOneWidget);
      expect(
        dockedText(tester, const Key('docked-player-track')),
        '02. Forord til Foerste Udgave',
      );
      expect(app.engine.playback, EnginePlayback.playing);
    });
  });

  group('Requirement: Track start and status transitions', () {
    testWidgets('Loading then playing', (tester) async {
      final app = await pumpBook(
        tester: tester,
        start: EngineStart.onCue,
        storedValues: savedAt(position: const Duration(seconds: 120)),
      );
      await tapChapter(tester, const TrackIndex(4));
      expect(activeOf(app).status, ActiveStatus.loading);
      expect(find.byKey(const Key('player-spinner')), findsOneWidget);
      expect(app.engine.loads.single.startAt, const Duration(seconds: 120));
      app.engine.run();
      await drain(tester);
      expect(activeOf(app).status, ActiveStatus.playing);
      expect(find.byKey(const Key('player-spinner')), findsNothing);
    });

    testWidgets('Engine length replaces the label', (tester) async {
      final app = await pumpBook(
        tester: tester,
        length: const KnownLength(duration: Duration(seconds: 491)),
      );
      await tapChapter(tester, const TrackIndex(0));
      expect(
        activeOf(app).length,
        const KnownLength(duration: Duration(seconds: 491)),
      );
      expect(dockedText(tester, const Key('na-scrubber-length')), '8:11');
    });
  });

  group('Requirement: Resume points', () {
    testWidgets('Periodic save cadence', (tester) async {
      final app = await pumpBook(tester: tester);
      await tapChapter(tester, const TrackIndex(0));
      await advance(app, tester, const Duration(seconds: 12));
      final key = PlaylistKind.book.pointKey(id: basicText);
      expect(
        app.storage.writes.where((written) => written == key),
        hasLength(3),
      );
      expect(storedPosition(app), const Duration(seconds: 10));
    });

    testWidgets('Index mirrors the point', (tester) async {
      final app = await pumpBook(tester: tester);
      await startSpeak(tester, app);
      await advance(app, tester, const Duration(seconds: 6));
      expect(
        storedIndex(app, kind: PlaylistKind.speak).stateOf(id: aSpeakUrl),
        storedPoint(app, kind: PlaylistKind.speak, id: aSpeakUrl),
      );
      expect(
        storedPoint(app, kind: PlaylistKind.speak, id: aSpeakUrl),
        isA<ResumeAt>(),
      );
    });

    testWidgets('Clearing removes both', (tester) async {
      final app = await pumpBook(
        tester: tester,
        path: const RoutePathText('/how-and-why'),
        storedValues: aStoredResumePoint(
          id: howAndWhy,
          point: aResumePoint(trackIndex: const TrackIndex(1)),
        ),
      );
      final last = bundledBook(AudiobookId.howAndWhy).chapters.length - 1;
      await tapChapter(tester, TrackIndex(last));
      app.engine.finish();
      await drain(tester);
      expect(playerOf(app), const PlayerIdle());
      expect(storedPoint(app, id: howAndWhy), const NotStarted());
      expect(storedIndex(app).points.containsKey(howAndWhy), isFalse);
    });

    testWidgets('Malformed point is ignored', (tester) async {
      final app = await pumpBook(
        tester: tester,
        storedValues: const {
          'mediaResume.book.basic-text': '{"trackIndex":"x","position":12}',
        },
      );
      expect(find.byKey(const Key('book-continue-header')), findsNothing);
      await tester.runAsync(
        () => app.container
            .read(mediaPlayerProvider.notifier)
            .play(
              playlist: bundledBook(AudiobookId.basicText).playlist(
                cover: const NoCover(),
              ),
              request: const ContinueListening(),
            ),
      );
      await drain(tester);
      expect(activeOf(app).trackIndex, const TrackIndex(0));
      expect(app.engine.loads.single.startAt, Duration.zero);
    });

    testWidgets('Background saves the place', (tester) async {
      final app = await pumpBook(tester: tester);
      await tapChapter(tester, const TrackIndex(0));
      await advance(app, tester, const Duration(seconds: 42));
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await drain(tester);
      expect(storedPosition(app), const Duration(seconds: 42));
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
  });

  group('Requirement: Docked player UI', () {
    testWidgets('Book shows chapter buttons', (tester) async {
      await pumpBook(tester: tester);
      await tapChapter(tester, const TrackIndex(0));
      expect(find.byKey(const Key('player-previous')), findsOneWidget);
      expect(find.byKey(const Key('player-next')), findsOneWidget);
      expect(
        tester
            .widget<NaMediaButton>(find.byKey(const Key('player-previous')))
            .availability,
        NaAvailability.disabled,
      );
      expect(
        tester
            .widget<NaMediaButton>(find.byKey(const Key('player-previous')))
            .label,
        const NaLabel('Previous chapter'),
      );
    });

    testWidgets('Speak hides chapter buttons', (tester) async {
      final app = await pumpBook(tester: tester);
      await startSpeak(tester, app);
      expect(docked, findsOneWidget);
      expect(find.byKey(const Key('player-previous')), findsNothing);
      expect(find.byKey(const Key('player-next')), findsNothing);
    });

    testWidgets('Drag preview then commit', (tester) async {
      final app = await pumpBook(
        tester: tester,
        length: const KnownLength(duration: Duration(seconds: 300)),
      );
      await tapChapter(tester, const TrackIndex(0));
      final track = tester.getRect(find.byKey(const Key('na-scrubber-track')));
      Offset at(double fraction) => Offset(
        track.left + 8 + (track.width - 16) * fraction,
        track.center.dy,
      );
      final gesture = await tester.startGesture(at(0.2));
      await gesture.moveTo(at(0.5));
      await gesture.moveTo(at(2 / 3));
      await tester.pump();
      expect(dockedText(tester, const Key('na-scrubber-position')), '3:20');
      expect(app.engine.seeks, isEmpty);
      await gesture.up();
      await drain(tester);
      expect(app.engine.seeks, [const Duration(seconds: 200)]);
    });

    testWidgets('Unknown length', (tester) async {
      final app = await pumpBook(tester: tester, start: EngineStart.onCue);
      await startSpeak(tester, app);
      expect(dockedText(tester, const Key('na-scrubber-length')), '--:--');
      expect(
        tester.getSemantics(find.byKey(const Key('na-scrubber-track'))),
        isNot(matchesSemantics(hasIncreaseAction: true)),
      );
    });
  });

  group('Requirement: Background playback and lock-screen controls', () {
    testWidgets('Lock-screen pause', (tester) async {
      final app = await pumpBook(tester: tester);
      await tapChapter(tester, const TrackIndex(0));
      await advance(app, tester, const Duration(seconds: 9));
      app.session.press(command: const RemotePause());
      await drain(tester);
      expect(activeOf(app).status, ActiveStatus.paused);
      expect(storedPosition(app), const Duration(seconds: 9));
      expect(
        tester
            .widget<NaMediaButton>(find.byKey(const Key('player-play')))
            .label,
        const NaLabel('Play'),
      );
    });

    testWidgets('Headset toggle', (tester) async {
      final app = await pumpBook(tester: tester);
      await tapChapter(tester, const TrackIndex(0));
      app.session.press(command: const RemoteToggle());
      await drain(tester);
      expect(activeOf(app).status, ActiveStatus.paused);
    });

    testWidgets('Lock-screen metadata for a book', (tester) async {
      final app = await pumpBook(tester: tester);
      await tapChapter(tester, const TrackIndex(0));
      final track = app.session.lastTrack;
      expect(
        track.title,
        const TrackTitle('01. Vores Symbol + Forord Til Sjette Udgave'),
      );
      expect(track.album, const PlaylistTitle('Basis Tekst'));
      expect(
        track.cover,
        const BundledCover(
          asset: AssetKey(
            'packages/feature_audiobooks/assets/covers/basic-text.png',
          ),
        ),
      );
      expect(track.previous, Neighbour.unavailable);
      expect(track.next, Neighbour.available);
    });

    testWidgets('Permission asked once', (tester) async {
      final app = await pumpBook(tester: tester);
      await tapChapter(tester, const TrackIndex(0));
      await tapChapter(tester, const TrackIndex(1));
      expect(app.notifications.promptCalls, const CallCount(1));
    });
  });
}
