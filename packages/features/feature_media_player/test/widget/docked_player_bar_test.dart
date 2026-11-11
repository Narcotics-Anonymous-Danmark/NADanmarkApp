@Tags(['widget'])
library;

import 'package:feature_media_player/feature_media_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/harness.dart';

Future<PlayerHarness> pumpBar({
  required WidgetTester tester,
  Language language = Language.english,
  EngineStart start = EngineStart.whenPlayed,
  MediaLength length = const UnknownLength(),
}) async {
  final harness = playerHarness(start: start);
  harness.engine.reportedLength = length;
  await pumpFeature(
    tester: tester,
    harness: harness.container,
    language: language,
    child: goldenFrame(
      child: const SizedBox(
        height: DockedPlayerBar.height,
        child: DockedPlayerBar(),
      ),
    ),
  );
  return harness;
}

Future<void> startPlaying({
  required WidgetTester tester,
  required PlayerHarness harness,
  MediaPlaylist? playlist,
}) async {
  await tester.runAsync(
    () => harness.player.play(
      playlist: playlist ?? aBookPlaylist(),
      request: const ContinueListening(),
    ),
  );
  await tester.pump();
}

String textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data ?? '';

NaAvailability availabilityOf(WidgetTester tester, Key key) =>
    tester.widget<NaMediaButton>(find.byKey(key)).availability;

void main() {
  setUpAll(loadNaFonts);

  testWidgets('book loading shows the spinner and chapter buttons', (
    tester,
  ) async {
    final harness = await pumpBar(tester: tester, start: EngineStart.onCue);
    await startPlaying(tester: tester, harness: harness);
    expect(find.byKey(const Key('player-spinner')), findsOneWidget);
    expect(textOf(tester, const Key('docked-player-track')), 'Chapter 1');
    expect(textOf(tester, const Key('docked-player-playlist')), 'Basis Tekst');
    expect(
      availabilityOf(tester, const Key('player-previous')),
      NaAvailability.disabled,
    );
    expect(
      availabilityOf(tester, const Key('player-next')),
      NaAvailability.enabled,
    );
    expect(textOf(tester, const Key('na-scrubber-length')), '8:10');
    await expectGolden(finder: goldenTarget, name: 'docked_book_loading');
  });

  testWidgets('book playing pauses, skips and closes', (tester) async {
    final harness = await pumpBar(
      tester: tester,
      length: KnownLength(duration: 300.seconds),
    );
    await startPlaying(tester: tester, harness: harness);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    await expectGolden(finder: goldenTarget, name: 'docked_book_playing');
    await expectAccessible(tester);
    await tester.tap(find.byKey(const Key('player-forward')));
    await tester.runAsync(flush);
    await tester.pump();
    expect(textOf(tester, const Key('na-scrubber-position')), '0:30');
    await tester.tap(find.byKey(const Key('player-rewind')));
    await tester.runAsync(flush);
    await tester.pump();
    expect(textOf(tester, const Key('na-scrubber-position')), '0:15');
    await tester.tap(find.byKey(const Key('player-play')));
    await tester.runAsync(flush);
    await tester.pump();
    expect(harness.active.status, ActiveStatus.paused);
    expect(find.bySemanticsLabel('Play'), findsOneWidget);
    await tester.tap(find.byKey(const Key('player-next')));
    await tester.runAsync(flush);
    await tester.pump();
    expect(textOf(tester, const Key('docked-player-track')), 'Chapter 2');
    await tester.tap(find.byKey(const Key('player-previous')));
    await tester.runAsync(flush);
    await tester.pump();
    expect(textOf(tester, const Key('docked-player-track')), 'Chapter 1');
    await tester.tap(find.byKey(const Key('player-close')));
    await tester.runAsync(flush);
    await tester.pump();
    expect(harness.state, const PlayerIdle());
  });

  testWidgets('speak hides chapter buttons', (tester) async {
    final harness = await pumpBar(tester: tester, language: Language.danish);
    await startPlaying(
      tester: tester,
      harness: harness,
      playlist: aSpeakPlaylist(),
    );
    await tester.runAsync(harness.player.pause);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('player-previous')), findsNothing);
    expect(find.byKey(const Key('player-next')), findsNothing);
    expect(textOf(tester, const Key('na-scrubber-length')), '--:--');
    expect(find.bySemanticsLabel('Ukendt varighed'), findsOneWidget);
    await expectGolden(finder: goldenTarget, name: 'docked_speak_paused');
    await expectAccessible(tester);
  });

  testWidgets('a speak shows the engine length and can be scrubbed', (
    tester,
  ) async {
    final harness = await pumpBar(
      tester: tester,
      length: KnownLength(duration: 600.seconds),
    );
    await startPlaying(
      tester: tester,
      harness: harness,
      playlist: aSpeakPlaylist(),
    );
    await tester.pumpAndSettle();
    expect(textOf(tester, const Key('na-scrubber-length')), '10:00');
    final track = tester.getRect(find.byKey(const Key('na-scrubber-track')));
    final gesture = await tester.startGesture(
      Offset(track.left + 8, track.center.dy),
    );
    await gesture.moveTo(
      Offset(track.left + 8 + (track.width - 16) / 2, track.center.dy),
    );
    await gesture.up();
    await tester.runAsync(flush);
    await tester.pump();
    expect(harness.engine.seeks, [300.seconds]);
    expect(textOf(tester, const Key('na-scrubber-position')), '5:00');
  });

  testWidgets('drag preview then commit', (tester) async {
    final harness = await pumpBar(
      tester: tester,
      length: KnownLength(duration: 300.seconds),
    );
    await startPlaying(tester: tester, harness: harness);
    await tester.pumpAndSettle();
    final track = tester.getRect(find.byKey(const Key('na-scrubber-track')));
    const radius = 8.0;
    Offset at(double fraction) => Offset(
      track.left + radius + (track.width - radius * 2) * fraction,
      track.center.dy,
    );
    final gesture = await tester.startGesture(at(0.1));
    await gesture.moveTo(at(0.4));
    await gesture.moveTo(at(2 / 3));
    await tester.pump();
    expect(textOf(tester, const Key('na-scrubber-position')), '3:20');
    expect(harness.engine.seeks, isEmpty);
    await gesture.up();
    await tester.runAsync(flush);
    await tester.pump();
    expect(harness.engine.seeks, [200.seconds]);
    expect(textOf(tester, const Key('na-scrubber-position')), '3:20');
  });

  testWidgets('tapping the track and the slider actions seek', (tester) async {
    final harness = await pumpBar(
      tester: tester,
      length: KnownLength(duration: 300.seconds),
    );
    await startPlaying(tester: tester, harness: harness);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('na-scrubber-track')));
    await tester.runAsync(flush);
    await tester.pump();
    expect(harness.engine.seeks.single, 150.seconds);
    final handle = tester.ensureSemantics();
    tester.semantics.increase(find.semantics.byLabel('Playback position'));
    await tester.runAsync(flush);
    await tester.pump();
    tester.semantics.decrease(find.semantics.byLabel('Playback position'));
    await tester.runAsync(flush);
    await tester.pump();
    handle.dispose();
    expect(harness.engine.seeks, [150.seconds, 180.seconds, 165.seconds]);
  });

  testWidgets('progress line shows the bar and the label', (tester) async {
    final harness = playerHarness();
    await pumpFeature(
      tester: tester,
      harness: harness.container,
      child: goldenFrame(
        child: const Column(
          children: [
            ProgressLine(
              progress: VisibleProgress(
                fraction: NaFraction(0.25),
                label: NaLabel('Continue from 1:05 · 8:55 left'),
              ),
            ),
            ProgressLine(progress: HiddenProgress()),
          ],
        ),
      ),
    );
    expect(find.text('Continue from 1:05 · 8:55 left'), findsOneWidget);
    expect(find.byType(NaProgressBar), findsOneWidget);
  });
}
