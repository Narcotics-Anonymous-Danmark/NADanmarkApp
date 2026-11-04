import 'dart:async';

import 'package:feature_media_player/src/application/media_player.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';

final Provider<AppLifecycleListener> playerLifecycleProvider = Provider((ref) {
  final listener = AppLifecycleListener(
    onPause: () =>
        unawaited(ref.read(mediaPlayerProvider.notifier).savePlace()),
  );
  ref.onDispose(listener.dispose);
  return listener;
});
