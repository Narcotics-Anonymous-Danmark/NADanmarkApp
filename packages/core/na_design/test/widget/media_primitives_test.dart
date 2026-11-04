@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/framed.dart';

NaLabel timeText(Duration time) => NaLabel(
  '${time.inMinutes}:${(time.inSeconds % 60).toString().padLeft(2, '0')}',
);

final class Commits {
  final List<Duration> values = [];
}

Future<Commits> pumpScrubber(
  WidgetTester tester, {
  Duration position = const Duration(seconds: 30),
  MediaLength length = const KnownLength(duration: Duration(seconds: 300)),
}) async {
  final commits = Commits();
  await pumpFramed(
    tester,
    NaScrubber(
      position: position,
      length: length,
      label: const NaLabel('Playback position'),
      unknownLength: const NaLabel('Unknown duration'),
      timeText: timeText,
      onCommit: commits.values.add,
    ),
  );
  return commits;
}

String textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data ?? '';

Offset trackAt(WidgetTester tester, double fraction) {
  final track = tester.getRect(find.byKey(const Key('na-scrubber-track')));
  return Offset(
    track.left + 8 + (track.width - 16) * fraction,
    track.center.dy,
  );
}

void main() {
  setUpAll(loadNaFonts);

  group('NaScrubber', () {
    testWidgets('shows the position and the length', (tester) async {
      await pumpScrubber(tester);
      expect(textOf(tester, const Key('na-scrubber-position')), '0:30');
      expect(textOf(tester, const Key('na-scrubber-length')), '5:00');
      await expectGolden(finder: goldenTarget, name: 'scrubber');
      await expectAccessible(tester);
    });

    testWidgets('a drag previews and commits once on release', (tester) async {
      final commits = await pumpScrubber(tester);
      final gesture = await tester.startGesture(trackAt(tester, 0.2));
      await gesture.moveTo(trackAt(tester, 0.4));
      await gesture.moveTo(trackAt(tester, 0.5));
      await tester.pump();
      expect(textOf(tester, const Key('na-scrubber-position')), '2:30');
      expect(commits.values, isEmpty);
      await gesture.up();
      await tester.pump();
      expect(commits.values, [const Duration(seconds: 150)]);
    });

    testWidgets('slider actions step forward 30 and back 15 seconds', (
      tester,
    ) async {
      final commits = await pumpScrubber(tester);
      final handle = tester.ensureSemantics();
      tester.semantics.increase(find.semantics.byLabel('Playback position'));
      tester.semantics.decrease(find.semantics.byLabel('Playback position'));
      handle.dispose();
      expect(commits.values, [
        const Duration(seconds: 60),
        const Duration(seconds: 15),
      ]);
    });

    testWidgets('steps stop at the ends', (tester) async {
      final commits = await pumpScrubber(
        tester,
        position: const Duration(seconds: 290),
      );
      final handle = tester.ensureSemantics();
      tester.semantics.increase(find.semantics.byLabel('Playback position'));
      handle.dispose();
      expect(commits.values, [const Duration(seconds: 300)]);
      final early = await pumpScrubber(
        tester,
        position: const Duration(seconds: 5),
      );
      final again = tester.ensureSemantics();
      tester.semantics.decrease(find.semantics.byLabel('Playback position'));
      again.dispose();
      expect(early.values, [Duration.zero]);
    });

    testWidgets('an unknown length disables the slider', (tester) async {
      final commits = await pumpScrubber(tester, length: const UnknownLength());
      expect(textOf(tester, const Key('na-scrubber-length')), '--:--');
      await tester.tap(find.byKey(const Key('na-scrubber-track')));
      await tester.pump();
      expect(commits.values, isEmpty);
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Unknown duration'), findsOneWidget);
      handle.dispose();
      await expectGolden(finder: goldenTarget, name: 'scrubber_unknown');
    });
  });

  testWidgets('progress bars clamp their fraction', (tester) async {
    await pumpFramed(
      tester,
      const Column(
        children: [
          NaProgressBar(fraction: NaFraction(0.25)),
          SizedBox(height: 8),
          NaProgressBar(fraction: NaFraction(1.5)),
        ],
      ),
    );
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('.*')), findsWidgets);
    expect(
      tester.getSemantics(find.byType(NaProgressBar).first).value,
      '25 %',
    );
    expect(
      tester.getSemantics(find.byType(NaProgressBar).last).value,
      '100 %',
    );
    handle.dispose();
    await expectGolden(finder: goldenTarget, name: 'progress_bars');
  });

  testWidgets('media buttons tap only when enabled', (tester) async {
    final taps = <String>[];
    await pumpFramed(
      tester,
      Row(
        children: [
          NaMediaButton(
            key: const Key('enabled'),
            icon: NaIcons.playFilled,
            label: const NaLabel('Play'),
            size: NaMediaButtonSize.large,
            availability: NaAvailability.enabled,
            onPressed: () => taps.add('play'),
          ),
          NaMediaButton(
            key: const Key('disabled'),
            icon: NaIcons.skipBack,
            label: const NaLabel('Previous chapter'),
            size: NaMediaButtonSize.regular,
            availability: NaAvailability.disabled,
            onPressed: () => taps.add('previous'),
          ),
          const NaSpinner(label: NaLabel('Loading'), size: 36),
        ],
      ),
    );
    await tester.tap(find.byKey(const Key('enabled')));
    await tester.tap(find.byKey(const Key('disabled')));
    expect(taps, ['play']);
    await tester.pump(const Duration(milliseconds: 450));
    await expectGolden(finder: goldenTarget, name: 'media_buttons');
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    handle.dispose();
  });
}
