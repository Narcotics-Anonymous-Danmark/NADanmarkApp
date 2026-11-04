@Tags(['unit'])
library;

import 'dart:io';

import 'package:adapter_audio/adapter_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

const AssetKey basicTextCover = AssetKey(
  'packages/feature_audiobooks/assets/covers/basic-text.png',
);

SessionTrack aSessionTrack({
  PlaylistCover cover = const NoCover(),
  Neighbour previous = Neighbour.unavailable,
  Neighbour next = Neighbour.available,
  MediaLength length = const KnownLength(duration: Duration(seconds: 490)),
}) => SessionTrack(
  id: const TrackId('https://audio.test/1.mp3'),
  title: const TrackTitle('01. Vores Symbol'),
  album: const PlaylistTitle('Basis Tekst'),
  cover: cover,
  length: length,
  kind: PlaylistKind.book,
  previous: previous,
  next: next,
);

const SessionPlayback playing = SessionPlayback(
  status: ActiveStatus.playing,
  position: Duration(seconds: 12),
);

Directory tempDirectory() {
  final directory = Directory.systemTemp.createTempSync('na_artwork');
  addTearDown(() => directory.deleteSync(recursive: true));
  return directory;
}

AudioServiceSession sessionWith({required Directory directory}) {
  final session = AudioServiceSession(
    artwork: ArtworkFiles(
      bundle: RepoAssetBundle.locate(),
      directory: () async => directory,
    ),
  );
  addTearDown(session.close);
  return session;
}

void main() {
  test('show publishes the track, the cover file and the controls', () async {
    final directory = tempDirectory();
    final session = sessionWith(directory: directory);
    await session.show(
      track: aSessionTrack(cover: const BundledCover(asset: basicTextCover)),
      playback: playing,
    );
    final item = session.mediaItem.value;
    expect(item?.title, '01. Vores Symbol');
    expect(item?.album, 'Basis Tekst');
    expect(item?.duration, const Duration(seconds: 490));
    expect(item?.artUri, Uri.file('${directory.path}/artwork/basic-text.png'));
    expect(File.fromUri(item?.artUri ?? Uri()).existsSync(), isTrue);
    final state = session.playbackState.value;
    expect(state.controls, [
      MediaControl.rewind,
      MediaControl.pause,
      MediaControl.fastForward,
      MediaControl.skipToNext,
      MediaControl.stop,
    ]);
    expect(state.androidCompactActionIndices, [0, 1, 2]);
    expect(state.playing, isTrue);
    expect(state.updatePosition, const Duration(seconds: 12));
    expect(state.processingState, AudioProcessingState.ready);
  });

  test('update keeps the track and hide clears the session', () async {
    final session = sessionWith(directory: tempDirectory());
    await session.update(playback: playing);
    expect(session.mediaItem.value, isNull);
    await session.show(
      track: aSessionTrack(
        previous: Neighbour.available,
        length: const UnknownLength(),
      ),
      playback: playing,
    );
    expect(session.mediaItem.value?.duration, isNull);
    expect(session.mediaItem.value?.artUri, isNull);
    await session.update(
      playback: const SessionPlayback(
        status: ActiveStatus.paused,
        position: Duration(seconds: 40),
      ),
    );
    final paused = session.playbackState.value;
    expect(paused.controls[2], MediaControl.play);
    expect(paused.controls.first, MediaControl.skipToPrevious);
    expect(paused.androidCompactActionIndices, [1, 2, 3]);
    expect(paused.playing, isFalse);
    await session.hide();
    expect(session.mediaItem.value, isNull);
    expect(
      session.playbackState.value.processingState,
      AudioProcessingState.idle,
    );
  });

  test('a loading track shows as loading', () {
    expect(
      AudioServiceSession.stateOf(
        track: aSessionTrack(),
        playback: const SessionPlayback(
          status: ActiveStatus.loading,
          position: Duration.zero,
        ),
      ).processingState,
      AudioProcessingState.loading,
    );
  });

  test('remote buttons become commands', () async {
    final session = sessionWith(directory: tempDirectory());
    final commands = <RemoteCommand>[];
    session.commands.listen(commands.add);
    await session.play();
    await session.pause();
    await session.skipToNext();
    await session.skipToPrevious();
    await session.fastForward();
    await session.rewind();
    await session.seek(const Duration(seconds: 61));
    await session.click();
    await session.click(MediaButton.next);
    await session.click(MediaButton.previous);
    await session.stop();
    await Future<void>.delayed(Duration.zero);
    expect(commands.map((command) => command.runtimeType), [
      RemotePlay,
      RemotePause,
      RemoteNext,
      RemotePrevious,
      RemoteSkipForward,
      RemoteSkipBackward,
      RemoteSeek,
      RemoteToggle,
      RemoteNext,
      RemotePrevious,
      RemoteStop,
    ]);
    expect(
      commands.whereType<RemoteSeek>().single.position,
      const Duration(seconds: 61),
    );
  });

  group('ArtworkFiles', () {
    test('a cover is copied once and reused', () async {
      final directory = tempDirectory();
      final artwork = ArtworkFiles(
        bundle: RepoAssetBundle.locate(),
        directory: () async => directory,
      );
      const cover = BundledCover(asset: basicTextCover);
      final first = await artwork.uriFor(cover: cover);
      File.fromUri(first ?? Uri()).deleteSync();
      expect(await artwork.uriFor(cover: cover), first);
      expect(await artwork.uriFor(cover: const NoCover()), isNull);
    });

    test('a missing asset or folder gives no artwork', () async {
      final artwork = ArtworkFiles(
        bundle: RepoAssetBundle.locate(),
        directory: () async => Directory('/proc/na-artwork-denied'),
      );
      expect(
        await artwork.uriFor(
          cover: const BundledCover(asset: AssetKey('packages/x/missing.png')),
        ),
        isNull,
      );
      expect(
        await artwork.uriFor(cover: const BundledCover(asset: basicTextCover)),
        isNull,
      );
    });
  });
}
