import 'package:feature_media_player/feature_media_player.dart';
import 'package:flutter/widgets.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:riverpod/riverpod.dart';

sealed class DockedPlayer {
  const DockedPlayer();

  double get height;
}

final class NoPlayer extends DockedPlayer {
  const NoPlayer();

  @override
  double get height => 0;
}

final class PlayerDocked extends DockedPlayer {
  const PlayerDocked({required this.player, required double height})
    : _height = height;

  final Widget player;
  final double _height;

  @override
  double get height => _height;
}

enum _Playing { active, idle }

final Provider<DockedPlayer> dockedPlayerProvider = Provider(
  (ref) => switch (ref.watch(
    mediaPlayerProvider.select(
      (state) => switch (state) {
        PlayerActive() => _Playing.active,
        PlayerIdle() => _Playing.idle,
      },
    ),
  )) {
    _Playing.active => const PlayerDocked(
      player: DockedPlayerBar(),
      height: DockedPlayerBar.height,
    ),
    _Playing.idle => const NoPlayer(),
  },
);
