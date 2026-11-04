import 'package:meta/meta.dart';

extension type const PlaylistId(String value) {}

extension type const TrackId(String value) {}

extension type const TrackTitle(String text) {}

extension type const PlaylistTitle(String text) {}

extension type const AudioUrl(Uri uri) {}

extension type const AssetKey(String path) {}

extension type const ChapterCount(int value) {}

extension type const TrackIndex(int position) {
  TrackIndex get next => TrackIndex(position + 1);

  TrackIndex get previous => TrackIndex(position - 1);

  ChapterCount get ordinal => ChapterCount(position + 1);
}

extension type const DurationLabel(String text) {
  MediaLength get length {
    final parts = text.trim().split(':');
    if (parts.length < 2 || parts.length > 3) {
      return const UnknownLength();
    }
    final numbers = parts.map(int.tryParse).toList();
    if (numbers.any((number) => number == null)) {
      return const UnknownLength();
    }
    return MediaLength.of(
      duration: Duration(
        seconds: numbers.whereType<int>().fold(
          0,
          (total, part) => total * 60 + part,
        ),
      ),
    );
  }
}

enum PlaylistKind {
  book(code: 'book'),
  speak(code: 'speak')
  ;

  const PlaylistKind({required this.code});

  final String code;
}

@immutable
sealed class MediaLength {
  const MediaLength();

  static MediaLength of({required Duration duration}) =>
      duration > Duration.zero
      ? KnownLength(duration: Duration(seconds: duration.inSeconds))
      : const UnknownLength();

  Duration get orZero => switch (this) {
    KnownLength(:final duration) => duration,
    UnknownLength() => Duration.zero,
  };
}

final class KnownLength extends MediaLength {
  const KnownLength({required this.duration});

  final Duration duration;

  @override
  int get hashCode => Object.hash(KnownLength, duration);

  @override
  bool operator ==(Object other) =>
      other is KnownLength && other.duration == duration;

  @override
  String toString() => 'KnownLength(${duration.inSeconds} s)';
}

final class UnknownLength extends MediaLength {
  const UnknownLength();

  @override
  int get hashCode => (UnknownLength).hashCode;

  @override
  bool operator ==(Object other) => other is UnknownLength;

  @override
  String toString() => 'UnknownLength';
}

@immutable
sealed class PlaylistCover {
  const PlaylistCover();
}

final class BundledCover extends PlaylistCover {
  const BundledCover({required this.asset});

  final AssetKey asset;

  @override
  int get hashCode => Object.hash(BundledCover, asset);

  @override
  bool operator ==(Object other) =>
      other is BundledCover && other.asset == asset;

  @override
  String toString() => 'BundledCover(${asset.path})';
}

final class NoCover extends PlaylistCover {
  const NoCover();

  @override
  int get hashCode => (NoCover).hashCode;

  @override
  bool operator ==(Object other) => other is NoCover;

  @override
  String toString() => 'NoCover';
}

abstract final class MediaRules {
  static const Duration minimumResume = Duration(seconds: 3);
  static const Duration minimumProgress = Duration(seconds: 5);
  static const Duration skipBackward = Duration(seconds: 15);
  static const Duration skipForward = Duration(seconds: 30);
  static const Duration saveEvery = Duration(seconds: 5);
  static const double almostFinished = 0.995;
}
