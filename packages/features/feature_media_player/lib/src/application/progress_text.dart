import 'package:meta/meta.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

@immutable
sealed class ShownProgress {
  const ShownProgress();
}

final class HiddenProgress extends ShownProgress {
  const HiddenProgress();

  @override
  int get hashCode => (HiddenProgress).hashCode;

  @override
  bool operator ==(Object other) => other is HiddenProgress;

  @override
  String toString() => 'HiddenProgress';
}

final class VisibleProgress extends ShownProgress {
  const VisibleProgress({required this.fraction, required this.label});

  final NaFraction fraction;
  final NaLabel label;

  @override
  int get hashCode => Object.hash(fraction, label);

  @override
  bool operator ==(Object other) =>
      other is VisibleProgress &&
      other.fraction == fraction &&
      other.label == label;

  @override
  String toString() => 'VisibleProgress(${fraction.value}, ${label.value})';
}

final class ProgressTexts {
  const ProgressTexts({required this.l10n});

  static const PlaybackTimeFormat _time = PlaybackTimeFormat();
  static const String _separator = ' · ';

  final AppLocalizations l10n;

  NaLabel time({required Duration duration}) =>
      NaLabel(_time.format(duration: duration).text);

  ShownProgress track({required TrackProgress progress}) => switch (progress) {
    NoProgress() => const HiddenProgress(),
    ResumeProgress(:final position, :final fraction, :final remaining) =>
      VisibleProgress(
        fraction: NaFraction(fraction.orZero),
        label: NaLabel(
          [
            l10n.playerContinueFrom(time(duration: position).value),
            ..._left(remaining: remaining),
          ].join(_separator),
        ),
      ),
    LiveProgress(:final position, :final length, :final fraction) =>
      VisibleProgress(
        fraction: NaFraction(fraction.orZero),
        label: NaLabel(
          [
            l10n.playerNowPlaying,
            [
              time(duration: position).value,
              ..._total(length: length),
            ].join(' / '),
          ].join(_separator),
        ),
      ),
  };

  ShownProgress book({required BookProgress progress}) => switch (progress) {
    NoBookProgress() => const HiddenProgress(),
    SavedBookProgress(
      :final chapter,
      :final count,
      :final fraction,
      :final remaining,
    ) =>
      VisibleProgress(
        fraction: NaFraction(fraction.orZero),
        label: NaLabel(
          [
            _chapterOf(chapter: chapter, count: count),
            ..._left(remaining: remaining),
          ].join(_separator),
        ),
      ),
    LiveBookProgress(:final chapter, :final count, :final fraction) =>
      VisibleProgress(
        fraction: NaFraction(fraction.orZero),
        label: NaLabel(
          [
            l10n.playerNowPlaying,
            _chapterOf(chapter: chapter, count: count),
          ].join(_separator),
        ),
      ),
  };

  String _chapterOf({
    required TrackIndex chapter,
    required ChapterCount count,
  }) => l10n.bookChapterOf('${chapter.ordinal.value}', '${count.value}');

  List<String> _total({required MediaLength length}) => switch (length) {
    KnownLength(:final duration) => [time(duration: duration).value],
    UnknownLength() => const [],
  };

  List<String> _left({required MediaLength remaining}) => switch (remaining) {
    KnownLength(:final duration) => [
      l10n.playerTimeLeft(time(duration: duration).value),
    ],
    UnknownLength() => const [],
  };
}
