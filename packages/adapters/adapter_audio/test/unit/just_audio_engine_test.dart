@Tags(['unit'])
library;

import 'dart:async';

import 'package:adapter_audio/adapter_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class PlatformMimic extends JustAudioPlatform {
  final List<PlayerMimic> players = [];

  PlayerMimic get player => players.last;

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    final player = PlayerMimic(request.id);
    players.add(player);
    return player;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async => DisposePlayerResponse();

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async => DisposeAllPlayersResponse();
}

enum LoadAnswer { ready, refuse }

final class PlayerMimic extends AudioPlayerPlatform {
  PlayerMimic(super.id);

  final StreamController<PlaybackEventMessage> _events =
      StreamController<PlaybackEventMessage>.broadcast();
  Duration length = const Duration(seconds: 300);
  LoadAnswer answer = LoadAnswer.ready;
  final List<LoadRequest> loads = [];
  final List<Duration?> seeks = [];
  int plays = 0;
  int pauses = 0;

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _events.stream;

  void emit({
    required ProcessingStateMessage state,
    Duration position = Duration.zero,
    int? errorCode,
    String? errorMessage,
  }) => _events.add(
    PlaybackEventMessage(
      processingState: state,
      updateTime: DateTime.now(),
      updatePosition: position,
      bufferedPosition: position,
      duration: length,
      icyMetadata: null,
      currentIndex: 0,
      androidAudioSessionId: null,
      errorCode: errorCode,
      errorMessage: errorMessage,
    ),
  );

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    loads.add(request);
    switch (answer) {
      case LoadAnswer.refuse:
        throw PlatformException(code: '404', message: 'not found');
      case LoadAnswer.ready:
        emit(
          state: ProcessingStateMessage.ready,
          position: request.initialPosition ?? Duration.zero,
        );
        return LoadResponse(duration: length);
    }
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    plays += 1;
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    pauses += 1;
    return PauseResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    seeks.add(request.position);
    emit(
      state: ProcessingStateMessage.ready,
      position: request.position ?? Duration.zero,
    );
    return SeekResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async =>
      SetPitchResponse();

  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
    SetSkipSilenceRequest request,
  ) async => SetSkipSilenceResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse();

  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
    SetShuffleOrderRequest request,
  ) async => SetShuffleOrderResponse();

  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
  setAutomaticallyWaitsToMinimizeStalling(
    SetAutomaticallyWaitsToMinimizeStallingRequest request,
  ) async => SetAutomaticallyWaitsToMinimizeStallingResponse();

  @override
  Future<SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse>
  setCanUseNetworkResourcesForLiveStreamingWhilePaused(
    SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest request,
  ) async => SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse();

  @override
  Future<SetPreferredPeakBitRateResponse> setPreferredPeakBitRate(
    SetPreferredPeakBitRateRequest request,
  ) async => SetPreferredPeakBitRateResponse();

  @override
  Future<SetAllowsExternalPlaybackResponse> setAllowsExternalPlayback(
    SetAllowsExternalPlaybackRequest request,
  ) async => SetAllowsExternalPlaybackResponse();

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
    SetAndroidAudioAttributesRequest request,
  ) async => SetAndroidAudioAttributesResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await _events.close();
    return DisposeResponse();
  }
}

final EngineItem item = EngineItem(
  url: AudioUrl(Uri.parse('https://audio.test/chapter-1.mp3')),
  title: const TrackTitle('Chapter 1'),
);

({JustAudioEngine engine, PlatformMimic platform, List<EngineEvent> events})
engineSetup() {
  final platform = PlatformMimic();
  JustAudioPlatform.instance = platform;
  final engine = JustAudioEngine(
    player: AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
      androidApplyAudioAttributes: false,
    ),
    positionEvery: const Duration(milliseconds: 20),
  );
  final events = <EngineEvent>[];
  engine.events.listen(events.add);
  addTearDown(engine.dispose);
  return (engine: engine, platform: platform, events: events);
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 80));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a loaded item starts at its position, runs once and reports', () async {
    final setup = engineSetup();
    final token = await setup.engine.load(item: item, startAt: 120.s);
    expect(setup.platform.player.loads.single.initialPosition, 120.s);
    await setup.engine.play();
    await settle();
    expect(setup.events.whereType<EngineRunning>(), hasLength(1));
    expect(
      setup.events.whereType<EngineLength>().first.length,
      const Duration(seconds: 300),
    );
    expect(setup.events.whereType<EnginePosition>(), isNotEmpty);
    expect(setup.events.every((event) => event.token == token), isTrue);
    await setup.engine.seek(position: 200.s);
    await setup.engine.pause();
    await setup.engine.play();
    await settle();
    expect(setup.platform.player.seeks, contains(200.s));
    expect(setup.platform.player.pauses, 1);
    expect(setup.events.whereType<EngineRunning>(), hasLength(1));
    setup.platform.player.emit(
      state: ProcessingStateMessage.completed,
      position: 300.s,
    );
    await settle();
    expect(setup.events.last, isA<EngineEnded>());
  });

  test('a refused load fails with its token', () async {
    final setup = engineSetup();
    await setup.engine.load(item: item, startAt: Duration.zero);
    setup.platform.player.answer = LoadAnswer.refuse;
    final token = await setup.engine.load(item: item, startAt: Duration.zero);
    await settle();
    expect(
      setup.events.whereType<EngineFailed>().single,
      isA<EngineFailed>()
          .having((failed) => failed.token, 'token', token)
          .having((failed) => failed.detail.text, 'detail', contains('404')),
    );
    await setup.engine.play();
    expect(setup.platform.player.plays, 0);
  });

  test('a playback error fails the item', () async {
    final setup = engineSetup();
    await setup.engine.load(item: item, startAt: Duration.zero);
    await setup.engine.play();
    await settle();
    setup.platform.player.emit(
      state: ProcessingStateMessage.idle,
      errorCode: 7,
      errorMessage: 'source error',
    );
    await settle();
    expect(
      setup.events.whereType<EngineFailed>().single.detail.text,
      '7: source error',
    );
  });

  test('a released item reports nothing more', () async {
    final setup = engineSetup();
    await setup.engine.load(item: item, startAt: Duration.zero);
    await setup.engine.play();
    await settle();
    await setup.engine.release();
    final before = setup.events.length;
    setup.platform.player.emit(state: ProcessingStateMessage.completed);
    await settle();
    expect(setup.events.skip(before).whereType<EngineEnded>(), isEmpty);
  });

  test('the overrides bind both ports', () {
    final setup = engineSetup();
    final overrides = audioOverrides(
      engine: setup.engine,
      session: AudioServiceSession(
        artwork: ArtworkFiles(
          bundle: rootBundle,
          directory: () async => throw UnimplementedError(),
        ),
      ),
    );
    expect(overrides, hasLength(2));
    expect(naAudioServiceConfig.rewindInterval, 15.s);
    expect(naAudioServiceConfig.fastForwardInterval, 30.s);
  });
}

extension on int {
  Duration get s => Duration(seconds: this);
}
