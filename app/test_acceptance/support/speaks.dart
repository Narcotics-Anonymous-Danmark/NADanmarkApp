import 'package:feature_shell/feature_shell.dart';
import 'package:feature_speaks/feature_speaks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import 'media.dart';
import 'pump_app.dart';

typedef SpeaksApp = ({AppHarness app, WordPressMimic wordpress});

const RoutePath speaksPath = RoutePath('/speaks');

Future<SpeaksApp> pumpSpeaksPage({
  required WidgetTester tester,
  WordPressMimic? wordpress,
  Map<String, String> storedValues = const {},
}) async {
  final mimic = wordpress ?? WordPressMimic();
  final app = await pumpApp(
    tester: tester,
    initialLocation: speaksPath.value,
    container: realJftContainer(
      storedValues: {...inEnglish, ...storedValues},
      wordpress: mimic,
    ),
  );
  addTearDown(app.dispose);
  await drain(tester);
  await settle(tester);
  return (app: app, wordpress: mimic);
}

WordPressMimic feedOf({
  List<SpeakGroupDto> danish = const [],
  List<SpeakGroupDto> english = const [],
}) => WordPressMimic()
  ..serve(
    language: SpeakLanguage.danish,
    reply: SpeakGroups(groups: danish),
  )
  ..serve(
    language: SpeakLanguage.english,
    reply: SpeakGroups(groups: english),
  );

SpeakGroupDto groupOf({
  required FeedText title,
  required List<SpeakEntryDto> speaks,
}) => SpeakGroupDto(title: title.value, speaks: speaks);

SpeakEntryDto entryOf({
  required SpeakSlug slug,
  FeedText name = const FeedText('Anna'),
  FeedText location = const FeedText('KOKNA 30'),
  FeedText year = const FeedText('2026'),
}) => sampleSpeak(slug: slug, name: name, location: location, year: year);

Finder speakRow(SpeakSlug slug) =>
    find.byKey(Key('speak-row-${slug.url.value}'));

Finder continueRow(SpeakSlug slug) =>
    find.byKey(Key('speak-continue-${slug.url.value}'));

Finder inSpeakRow(SpeakSlug slug, Finder matching) =>
    find.descendant(of: speakRow(slug), matching: matching);

Finder sectionHeader(String label) => find.descendant(
  of: find.byType(SpeakSectionHeader),
  matching: find.text(label),
);

Future<void> searchFor(
  WidgetTester tester,
  AppHarness app,
  SearchInput text,
) async {
  await tester.enterText(inPage(find.byType(EditableText)), text.text);
  await tester.pump();
  app.time.advance(by: SpeakFilters.queryDelay);
  await settle(tester);
}

Future<void> tapVisible(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await settle(tester);
}

Future<void> openFilters(WidgetTester tester) =>
    tapVisible(tester, const Key('speak-filters'));

SpeakListing listingIn(AppHarness app) =>
    app.container.read(speakListingProvider(Language.english));

List<String> listedTitles(AppHarness app) => listingIn(app).sections
    .expand((section) => section.speaks)
    .map(
      (speak) =>
          SpeakTexts.of(language: Language.english).title(speak: speak).value,
    )
    .toList();

Map<String, String> storedSpeakPoints(List<(SpeakSlug, ResumePoint)> points) {
  const codec = ResumeCodec();
  final index = points.fold(
    ResumeIndex.empty,
    (index, entry) => index.withPoint(id: entry.$1.url.id, point: entry.$2),
  );
  return Map.unmodifiable({
    for (final entry in points)
      PlaylistKind.speak.pointKey(id: entry.$1.url.id).name: codec.encodePoint(
        point: entry.$2,
      ),
    PlaylistKind.speak.indexKey.name: codec.encodeIndex(index: index),
  });
}

ResumePoint speakPointAt({
  required SpeakSlug slug,
  Duration position = const Duration(minutes: 4, seconds: 10),
  Instant? updatedAt,
}) => ResumePoint(
  trackId: TrackId(slug.url.value),
  trackIndex: const TrackIndex(0),
  position: position,
  length: const KnownLength(duration: Duration(minutes: 10)),
  updatedAt: updatedAt ?? aResumeTime,
);

double speaksOffset(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(SpeaksResults),
        matching: find.byType(Scrollable),
      ),
    )
    .position
    .pixels;

Future<void> dragList(WidgetTester tester, Offset by) async {
  await tester.drag(
    find.descendant(
      of: find.byType(SpeaksResults),
      matching: find.byType(Scrollable),
    ),
    by,
  );
  await drain(tester);
  await settle(tester);
}
