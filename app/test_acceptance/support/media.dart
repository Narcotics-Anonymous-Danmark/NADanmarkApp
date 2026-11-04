import 'dart:io';

import 'package:adapter_assets/adapter_assets.dart';
import 'package:feature_media_player/feature_media_player.dart';
import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import 'pump_app.dart';

const RoutePath audiobooksPath = RoutePath('/audiobooks');
const RoutePath readingsPath = RoutePath('/grc');
const PlaylistId basicText = PlaylistId('basic-text');
const PlaylistId howAndWhy = PlaylistId('how-and-why');

Future<AppHarness> pumpAt({
  required WidgetTester tester,
  required RoutePath location,
  Map<String, String> storedValues = const {},
}) => pumpApp(
  tester: tester,
  initialLocation: location.value,
  container: realJftContainer(storedValues: {...inEnglish, ...storedValues}),
);

const Map<String, String> inEnglish = {'language': 'en'};

Future<void> drain(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (var turn = 0; turn < 30; turn += 1) {
      await Future<void>.delayed(Duration.zero);
    }
  });
  await tester.pump();
  await tester.pump();
}

Future<void> openBook(WidgetTester tester, PlaylistId book) async {
  await tester.tap(find.byKey(Key('audiobook-row-${book.value}')));
  await settle(tester);
}

Future<void> tapChapter(WidgetTester tester, TrackIndex index) async {
  final row = find.byKey(Key('book-chapter-${index.position}'));
  await tester.scrollUntilVisible(
    row,
    200,
    scrollable: inPage(find.byType(Scrollable)).first,
  );
  await tester.tap(row);
  await drain(tester);
}

Future<void> advance(AppHarness app, WidgetTester tester, Duration by) async {
  app.time.advance(by: by);
  await drain(tester);
}

String dockedText(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data ?? '';

PlayerState playerOf(AppHarness app) => app.container.read(mediaPlayerProvider);

PlayerActive activeOf(AppHarness app) => switch (playerOf(app)) {
  final PlayerActive active => active,
  PlayerIdle() => throw StateError('the player is idle'),
};

ResumeState storedPoint(
  AppHarness app, {
  PlaylistKind kind = PlaylistKind.book,
  PlaylistId id = basicText,
}) => switch (app.storage.snapshot[kind.pointKey(id: id).name]) {
  final String text => switch (const ResumeCodec().decodePoint(
    text: text,
    fallbackTime: app.time.now,
  )) {
    Ok(value: final point) => ResumeAt(point: point),
    Err() => const NotStarted(),
  },
  null => const NotStarted(),
};

ResumeIndex storedIndex(
  AppHarness app, {
  PlaylistKind kind = PlaylistKind.book,
}) => switch (app.storage.snapshot[kind.indexKey.name]) {
  final String text => const ResumeCodec().decodeIndex(
    text: text,
    fallbackTime: app.time.now,
  ),
  null => ResumeIndex.empty,
};

Duration storedPosition(
  AppHarness app, {
  PlaylistKind kind = PlaylistKind.book,
  PlaylistId id = basicText,
}) => switch (storedPoint(app, kind: kind, id: id)) {
  ResumeAt(:final point) => point.position,
  NotStarted() => throw StateError('no resume point for ${id.value}'),
};

Audiobook bundledBook(AudiobookId id) => switch (AssetAudiobooks.decode(
  book: id,
  text: File(
    '${RepoAssetBundle.locate().repoRoot.path}/packages/adapters/'
    'adapter_assets/assets/books/${id.playlistId.value}.json',
  ).readAsStringSync(),
)) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('$error'),
};

Map<String, String> savedAt({
  AudiobookId book = AudiobookId.basicText,
  TrackIndex index = const TrackIndex(4),
  Duration position = const Duration(seconds: 120),
}) => aStoredResumePoint(
  id: book.playlistId,
  point: ResumePoint(
    trackId: bundledBook(book).chapters[index.position].track.id,
    trackIndex: index,
    position: position,
    length: const UnknownLength(),
    updatedAt: aResumeTime,
  ),
);

Future<void> startSpeak(WidgetTester tester, AppHarness app) async {
  await tester.runAsync(
    () => app.container
        .read(mediaPlayerProvider.notifier)
        .play(playlist: aSpeakPlaylist(), request: const ContinueListening()),
  );
  await drain(tester);
}
