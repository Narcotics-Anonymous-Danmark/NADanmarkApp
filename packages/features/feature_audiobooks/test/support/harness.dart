import 'package:feature_media_player/feature_media_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

TestContainer booksHarness({Map<String, String> storedValues = const {}}) {
  final harness = TestContainer.build(storedValues: storedValues);
  addTearDown(harness.dispose);
  return harness;
}

Future<void> pumpBooks({
  required WidgetTester tester,
  required TestContainer harness,
  required Widget child,
  Language language = Language.english,
}) async {
  await pumpFeature(
    tester: tester,
    harness: harness,
    language: language,
    child: goldenFrame(
      child: SizedBox(
        height: 760,
        child: ColoredBox(color: NaColors.light.background, child: child),
      ),
    ),
  );
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> playIn({
  required WidgetTester tester,
  required TestContainer harness,
  required MediaPlaylist playlist,
  required TrackIndex index,
}) async {
  await tester.runAsync(
    () => harness
        .read(mediaPlayerProvider.notifier)
        .play(
          playlist: playlist,
          request: StartTrack(index: index),
        ),
  );
  await tester.pumpAndSettle();
}

Future<void> settleTaps(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (var turn = 0; turn < 20; turn += 1) {
      await Future<void>.delayed(Duration.zero);
    }
  });
  await tester.pumpAndSettle();
}
