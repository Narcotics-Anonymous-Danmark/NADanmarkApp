import 'package:feature_media_player/feature_media_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

final class PlayerHarness {
  PlayerHarness({required this.container});

  final TestContainer container;

  MediaPlayer get player => container.read(mediaPlayerProvider.notifier);

  PlayerState get state => container.read(mediaPlayerProvider);

  PlayerActive get active => switch (state) {
    final PlayerActive active => active,
    PlayerIdle() => throw StateError('the player is idle'),
  };

  AudioEngineMimic get engine => container.engine;

  MediaSessionMimic get session => container.session;

  KeyValueStoreMimic get storage => container.storage;

  TestTime get time => container.time;

  ResumeState stored({
    PlaylistKind kind = PlaylistKind.book,
    PlaylistId id = const PlaylistId('basic-text'),
  }) => switch (storage.snapshot[kind.pointKey(id: id).name]) {
    final String text => switch (const ResumeCodec().decodePoint(
      text: text,
      fallbackTime: time.now,
    )) {
      Ok(value: final point) => ResumeAt(point: point),
      Err() => const NotStarted(),
    },
    null => const NotStarted(),
  };

  ResumeIndex index({PlaylistKind kind = PlaylistKind.book}) =>
      switch (storage.snapshot[kind.indexKey.name]) {
        final String text => const ResumeCodec().decodeIndex(
          text: text,
          fallbackTime: time.now,
        ),
        null => ResumeIndex.empty,
      };

  Duration storedPosition({
    PlaylistKind kind = PlaylistKind.book,
    PlaylistId id = const PlaylistId('basic-text'),
  }) => switch (stored(kind: kind, id: id)) {
    ResumeAt(:final point) => point.position,
    NotStarted() => throw StateError('no resume point for ${id.value}'),
  };

  Future<void> start({
    MediaPlaylist? playlist,
    StartRequest request = const ContinueListening(),
  }) async {
    await player.play(playlist: playlist ?? aBookPlaylist(), request: request);
    await flush();
  }

  Future<void> advance(Duration by) async {
    time.advance(by: by);
    await flush();
  }
}

PlayerHarness playerHarness({
  Map<String, String> storedValues = const {},
  EngineStart start = EngineStart.whenPlayed,
}) {
  final container = TestContainer.build(storedValues: storedValues);
  addTearDown(container.dispose);
  container.engine.start = start;
  container.read(mediaPlayerProvider);
  return PlayerHarness(container: container);
}

Future<void> flush() async {
  for (var turn = 0; turn < 20; turn += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}
