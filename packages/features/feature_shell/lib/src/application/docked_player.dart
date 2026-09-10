import 'package:flutter/widgets.dart';
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

final Provider<DockedPlayer> dockedPlayerProvider = Provider(
  (ref) => const NoPlayer(),
);
