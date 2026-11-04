import 'package:adapter_audio/src/artwork_files.dart';
import 'package:adapter_audio/src/audio_service_session.dart';
import 'package:adapter_audio/src/just_audio_engine.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:na_ports/na_ports.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/misc.dart';

List<Override> audioOverrides({
  required AudioEnginePort engine,
  required MediaSessionPort session,
}) => [
  audioEnginePortProvider.overrideWithValue(engine),
  mediaSessionPortProvider.overrideWithValue(session),
];

const AudioServiceConfig naAudioServiceConfig = AudioServiceConfig(
  androidNotificationChannelId: 'dk.nadanmark.app.audio',
  androidNotificationChannelName: 'NA Danmark',
  androidNotificationIcon: 'drawable/ic_notification',
  androidNotificationOngoing: true,
  fastForwardInterval: Duration(seconds: 30),
  rewindInterval: Duration(seconds: 15),
);

Future<List<Override>> startAudio({required AssetBundle bundle}) async {
  final audioSession = await AudioSession.instance;
  await audioSession.configure(const AudioSessionConfiguration.speech());
  final session = await AudioService.init(
    builder: () => AudioServiceSession(
      artwork: ArtworkFiles(
        bundle: bundle,
        directory: getApplicationCacheDirectory,
      ),
    ),
    config: naAudioServiceConfig,
  );
  return audioOverrides(
    engine: JustAudioEngine(
      player: AudioPlayer(),
      positionEvery: const Duration(seconds: 1),
    ),
    session: session,
  );
}
