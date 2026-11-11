import 'package:feature_media_player/feature_media_player.dart';
import 'package:feature_speaks/feature_speaks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

final SpeakTexts english = SpeakTexts.of(language: Language.english);

TestContainer speaksHarness({Map<String, String> storedValues = const {}}) {
  final harness = TestContainer.build(storedValues: storedValues);
  addTearDown(harness.dispose);
  return harness;
}

Future<void> flush() async {
  for (var turn = 0; turn < 20; turn += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<CatalogState> loadedCatalog(TestContainer harness) async {
  harness.read(speaksCatalogProvider);
  await flush();
  return harness.read(speaksCatalogProvider);
}

SpeakCatalog catalogOf(TestContainer harness) =>
    harness.read(speaksCatalogProvider).catalogOrEmpty;

PlaylistId speakId(SpeakSlug slug) => slug.url.id;

ResumePoint aSpeakPoint({
  SpeakSlug slug = const SpeakSlug('kokna-27-anders'),
  Duration position = const Duration(minutes: 4, seconds: 10),
  MediaLength length = const KnownLength(duration: Duration(minutes: 10)),
  Instant? updatedAt,
}) => ResumePoint(
  trackId: TrackId(slug.url.value),
  trackIndex: const TrackIndex(0),
  position: position,
  length: length,
  updatedAt: updatedAt ?? aResumeTime,
);

Map<String, String> storedSpeakPoints(List<(SpeakSlug, ResumePoint)> points) {
  const codec = ResumeCodec();
  final index = points.fold(
    ResumeIndex.empty,
    (index, entry) => index.withPoint(id: speakId(entry.$1), point: entry.$2),
  );
  return Map.unmodifiable({
    for (final entry in points)
      PlaylistKind.speak.pointKey(id: speakId(entry.$1)).name: codec
          .encodePoint(point: entry.$2),
    PlaylistKind.speak.indexKey.name: codec.encodeIndex(index: index),
  });
}

Future<void> pumpSpeaks({
  required WidgetTester tester,
  required TestContainer harness,
  Language language = Language.english,
}) async {
  tester.view.physicalSize = const Size(420, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await pumpFeature(
    tester: tester,
    harness: harness,
    language: language,
    child: goldenFrame(
      width: 400,
      child: SizedBox(
        height: 900,
        child: ColoredBox(
          color: NaColors.light.background,
          child: const SpeaksBody(),
        ),
      ),
    ),
  );
  await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(flush);
  await tester.pumpAndSettle();
}

Future<void> typeQuery(
  WidgetTester tester,
  TestContainer harness,
  SearchInput text,
) async {
  await tester.enterText(find.byType(EditableText), text.text);
  await tester.pump();
  harness.time.advance(by: SpeakFilters.queryDelay);
  await tester.pumpAndSettle();
}

Finder rowOf(SpeakSlug slug) => find.byKey(Key('speak-row-${slug.url.value}'));

Finder inRow(SpeakSlug slug, Finder matching) =>
    find.descendant(of: rowOf(slug), matching: matching);

PlayerState playerOf(TestContainer harness) =>
    harness.read(mediaPlayerProvider);
