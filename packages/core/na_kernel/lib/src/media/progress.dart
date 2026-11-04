import 'package:meta/meta.dart';
import 'package:na_kernel/src/media/media_values.dart';
import 'package:na_kernel/src/media/resume_point.dart';

@immutable
sealed class ProgressFraction {
  const ProgressFraction();

  static ProgressFraction of({
    required Duration part,
    required MediaLength whole,
  }) => switch (whole) {
    KnownLength(:final duration) => KnownFraction(
      value: (part.inMilliseconds / duration.inMilliseconds).clamp(0, 1),
    ),
    UnknownLength() => const UnknownFraction(),
  };

  double get orZero => switch (this) {
    KnownFraction(:final value) => value,
    UnknownFraction() => 0,
  };
}

final class KnownFraction extends ProgressFraction {
  const KnownFraction({required this.value});

  final double value;

  @override
  int get hashCode => Object.hash(KnownFraction, value);

  @override
  bool operator ==(Object other) =>
      other is KnownFraction && other.value == value;

  @override
  String toString() => 'KnownFraction($value)';
}

final class UnknownFraction extends ProgressFraction {
  const UnknownFraction();

  @override
  int get hashCode => (UnknownFraction).hashCode;

  @override
  bool operator ==(Object other) => other is UnknownFraction;

  @override
  String toString() => 'UnknownFraction';
}

@immutable
sealed class TrackProgress {
  const TrackProgress();

  static TrackProgress ofResume({
    required ResumeState resume,
    required MediaLength label,
  }) => switch (resume) {
    NotStarted() => const NoProgress(),
    ResumeAt(:final point) when point.position < MediaRules.minimumProgress =>
      const NoProgress(),
    ResumeAt(:final point) => _resumed(
      position: point.position,
      length: switch (point.length) {
        KnownLength() => point.length,
        UnknownLength() => label,
      },
    ),
  };

  static TrackProgress _resumed({
    required Duration position,
    required MediaLength length,
  }) {
    final fraction = ProgressFraction.of(part: position, whole: length);
    if (fraction.orZero > MediaRules.almostFinished) {
      return const NoProgress();
    }
    return ResumeProgress(
      position: position,
      fraction: fraction,
      remaining: switch (length) {
        KnownLength(:final duration) => MediaLength.of(
          duration: duration - position,
        ),
        UnknownLength() => const UnknownLength(),
      },
    );
  }

  static TrackProgress live({
    required Duration position,
    required MediaLength length,
  }) => LiveProgress(
    position: position,
    length: length,
    fraction: switch (length) {
      KnownLength() => ProgressFraction.of(part: position, whole: length),
      UnknownLength() => const KnownFraction(value: 0),
    },
  );
}

final class NoProgress extends TrackProgress {
  const NoProgress();

  @override
  int get hashCode => (NoProgress).hashCode;

  @override
  bool operator ==(Object other) => other is NoProgress;

  @override
  String toString() => 'NoProgress';
}

final class ResumeProgress extends TrackProgress {
  const ResumeProgress({
    required this.position,
    required this.fraction,
    required this.remaining,
  });

  final Duration position;
  final ProgressFraction fraction;
  final MediaLength remaining;

  @override
  int get hashCode => Object.hash(position, fraction, remaining);

  @override
  bool operator ==(Object other) =>
      other is ResumeProgress &&
      other.position == position &&
      other.fraction == fraction &&
      other.remaining == remaining;

  @override
  String toString() =>
      'ResumeProgress(${position.inSeconds} s, $fraction, $remaining)';
}

final class LiveProgress extends TrackProgress {
  const LiveProgress({
    required this.position,
    required this.length,
    required this.fraction,
  });

  final Duration position;
  final MediaLength length;
  final ProgressFraction fraction;

  @override
  int get hashCode => Object.hash(position, length, fraction);

  @override
  bool operator ==(Object other) =>
      other is LiveProgress &&
      other.position == position &&
      other.length == length &&
      other.fraction == fraction;

  @override
  String toString() => 'LiveProgress(${position.inSeconds} s, $length)';
}

@immutable
sealed class BookListening {
  const BookListening();
}

final class ListeningLive extends BookListening {
  const ListeningLive({required this.chapter, required this.position});

  final TrackIndex chapter;
  final Duration position;
}

final class NotListening extends BookListening {
  const NotListening();
}

@immutable
sealed class BookProgress {
  const BookProgress();

  static BookProgress of({
    required List<MediaLength> chapters,
    required ResumeState saved,
    required BookListening listening,
  }) => switch ((listening, saved)) {
    (ListeningLive(:final chapter, :final position), ResumeState()) => _at(
      chapters: chapters,
      chapter: chapter,
      position: position,
      live: _Live.yes,
    ),
    (NotListening(), ResumeAt(:final point)) => _at(
      chapters: chapters,
      chapter: point.trackIndex,
      position: point.position,
      live: _Live.no,
    ),
    (NotListening(), NotStarted()) => const NoBookProgress(),
  };

  static BookProgress _at({
    required List<MediaLength> chapters,
    required TrackIndex chapter,
    required Duration position,
    required _Live live,
  }) {
    if (chapter.position < 0 ||
        chapter.position >= chapters.length ||
        (chapter.position == 0 && position < MediaRules.minimumProgress)) {
      return const NoBookProgress();
    }
    final total = MediaLength.of(
      duration: chapters.fold(Duration.zero, (sum, item) => sum + item.orZero),
    );
    final before = chapters
        .take(chapter.position)
        .fold(Duration.zero, (sum, item) => sum + item.orZero);
    final elapsed = switch (total) {
      KnownLength(:final duration) when before + position > duration =>
        duration,
      KnownLength() || UnknownLength() => before + position,
    };
    final fraction = ProgressFraction.of(part: elapsed, whole: total);
    final count = ChapterCount(chapters.length);
    return switch (live) {
      _Live.yes => LiveBookProgress(
        chapter: chapter,
        count: count,
        fraction: fraction,
      ),
      _Live.no => SavedBookProgress(
        chapter: chapter,
        count: count,
        fraction: fraction,
        remaining: switch (total) {
          KnownLength(:final duration) => MediaLength.of(
            duration: duration - elapsed,
          ),
          UnknownLength() => const UnknownLength(),
        },
      ),
    };
  }
}

enum _Live { yes, no }

final class NoBookProgress extends BookProgress {
  const NoBookProgress();

  @override
  int get hashCode => (NoBookProgress).hashCode;

  @override
  bool operator ==(Object other) => other is NoBookProgress;

  @override
  String toString() => 'NoBookProgress';
}

final class SavedBookProgress extends BookProgress {
  const SavedBookProgress({
    required this.chapter,
    required this.count,
    required this.fraction,
    required this.remaining,
  });

  final TrackIndex chapter;
  final ChapterCount count;
  final ProgressFraction fraction;
  final MediaLength remaining;

  @override
  int get hashCode => Object.hash(chapter, count, fraction, remaining);

  @override
  bool operator ==(Object other) =>
      other is SavedBookProgress &&
      other.chapter == chapter &&
      other.count == count &&
      other.fraction == fraction &&
      other.remaining == remaining;

  @override
  String toString() =>
      'SavedBookProgress(${chapter.position}/${count.value}, $fraction, '
      '$remaining)';
}

final class LiveBookProgress extends BookProgress {
  const LiveBookProgress({
    required this.chapter,
    required this.count,
    required this.fraction,
  });

  final TrackIndex chapter;
  final ChapterCount count;
  final ProgressFraction fraction;

  @override
  int get hashCode => Object.hash(chapter, count, fraction);

  @override
  bool operator ==(Object other) =>
      other is LiveBookProgress &&
      other.chapter == chapter &&
      other.count == count &&
      other.fraction == fraction;

  @override
  String toString() =>
      'LiveBookProgress(${chapter.position}/${count.value}, $fraction)';
}
