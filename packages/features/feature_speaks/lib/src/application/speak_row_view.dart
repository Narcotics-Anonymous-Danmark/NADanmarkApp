import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';

@immutable
sealed class SpeakPlayback {
  const SpeakPlayback();

  static SpeakPlayback of({
    required PlaylistId id,
    required PlayerState player,
  }) => switch (player) {
    PlayerActive(:final playlist, :final status, :final position, :final length)
        when playlist.kind == PlaylistKind.speak && playlist.id == id =>
      PlayingSpeak(status: status, position: position, length: length),
    PlayerActive() || PlayerIdle() => const NotPlayingSpeak(),
  };
}

final class PlayingSpeak extends SpeakPlayback {
  const PlayingSpeak({
    required this.status,
    required this.position,
    required this.length,
  });

  final ActiveStatus status;
  final Duration position;
  final MediaLength length;

  @override
  int get hashCode => Object.hash(status, position, length);

  @override
  bool operator ==(Object other) =>
      other is PlayingSpeak &&
      other.status == status &&
      other.position == position &&
      other.length == length;
}

final class NotPlayingSpeak extends SpeakPlayback {
  const NotPlayingSpeak();

  @override
  int get hashCode => (NotPlayingSpeak).hashCode;

  @override
  bool operator ==(Object other) => other is NotPlayingSpeak;
}

enum SpeakIcon { play, pause, loading }

enum RowTone { started, plain }

@immutable
final class SpeakRowView {
  const SpeakRowView({
    required this.icon,
    required this.progress,
    required this.tone,
  });

  factory SpeakRowView.of({
    required SpeakPlayback playback,
    required ResumeState saved,
  }) => switch (playback) {
    PlayingSpeak(:final status, :final position, :final length) => SpeakRowView(
      icon: switch (status) {
        ActiveStatus.loading => SpeakIcon.loading,
        ActiveStatus.playing => SpeakIcon.pause,
        ActiveStatus.paused => SpeakIcon.play,
      },
      progress: TrackProgress.live(position: position, length: length),
      tone: RowTone.started,
    ),
    NotPlayingSpeak() => switch (TrackProgress.ofResume(
      resume: saved,
      label: const UnknownLength(),
    )) {
      NoProgress() => const SpeakRowView(
        icon: SpeakIcon.play,
        progress: NoProgress(),
        tone: RowTone.plain,
      ),
      final TrackProgress progress => SpeakRowView(
        icon: SpeakIcon.play,
        progress: progress,
        tone: RowTone.started,
      ),
    },
  };

  final SpeakIcon icon;
  final TrackProgress progress;
  final RowTone tone;

  @override
  int get hashCode => Object.hash(icon, progress, tone);

  @override
  bool operator ==(Object other) =>
      other is SpeakRowView &&
      other.icon == icon &&
      other.progress == progress &&
      other.tone == tone;

  @override
  String toString() => 'SpeakRowView(${icon.name}, $progress, ${tone.name})';
}

MediaPlaylist speakPlaylist({
  required Speak speak,
  required TrackTitle trackTitle,
  required PlaylistCover cover,
}) => MediaPlaylist(
  id: speak.id,
  kind: PlaylistKind.speak,
  title: PlaylistTitle(speak.groupTitle.text),
  cover: cover,
  tracks: List.unmodifiable([
    MediaTrack(
      id: TrackId(speak.id.value),
      title: trackTitle,
      url: speak.url,
      label: const DurationLabel(''),
    ),
  ]),
);
