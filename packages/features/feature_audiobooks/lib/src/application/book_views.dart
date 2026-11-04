import 'package:feature_media_player/feature_media_player.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';

BookListening listeningTo({
  required AudiobookId book,
  required PlayerState player,
}) => switch (player) {
  PlayerActive(:final playlist, :final trackIndex, :final position)
      when playlist.kind == PlaylistKind.book &&
          playlist.id == book.playlistId =>
    ListeningLive(chapter: trackIndex, position: position),
  PlayerActive() || PlayerIdle() => const NotListening(),
};

ResumeState savedFor({
  required AudiobookId book,
  required LoadResult<ResumeLibrary> library,
}) => switch (library) {
  Loaded(:final value) => value.books.stateOf(id: book.playlistId),
  Loading() || Failed() => const NotStarted(),
};

BookProgress bookProgressOf({
  required AudiobookId book,
  required LoadResult<Audiobook> loaded,
  required LoadResult<ResumeLibrary> library,
  required PlayerState player,
}) => switch (loaded) {
  Loaded(:final value) => BookProgress.of(
    chapters: value.chapterLengths,
    saved: savedFor(book: book, library: library),
    listening: listeningTo(book: book, player: player),
  ),
  Loading() || Failed() => const NoBookProgress(),
};

@immutable
sealed class ContinueChapter {
  const ContinueChapter();
}

final class ContinueAt extends ContinueChapter {
  const ContinueAt({required this.index});

  final TrackIndex index;

  @override
  int get hashCode => Object.hash(ContinueAt, index);

  @override
  bool operator ==(Object other) => other is ContinueAt && other.index == index;
}

final class NothingToContinue extends ContinueChapter {
  const NothingToContinue();

  @override
  int get hashCode => (NothingToContinue).hashCode;

  @override
  bool operator ==(Object other) => other is NothingToContinue;
}

enum ChapterIcon { play, pause }

@immutable
final class ChapterState {
  const ChapterState({required this.progress, required this.icon});

  final TrackProgress progress;
  final ChapterIcon icon;

  @override
  int get hashCode => Object.hash(progress, icon);

  @override
  bool operator ==(Object other) =>
      other is ChapterState && other.progress == progress && other.icon == icon;
}

ContinueChapter continueChapterOf({
  required Audiobook book,
  required ResumeState saved,
  required PlayerState player,
}) => switch ((listeningTo(book: book.id, player: player), saved)) {
  (ListeningLive(:final chapter), ResumeState()) => ContinueAt(index: chapter),
  (NotListening(), ResumeAt(:final point))
      when point.trackIndex.position >= 0 &&
          point.trackIndex.position < book.chapters.length =>
    ContinueAt(index: point.trackIndex),
  (NotListening(), ResumeAt() || NotStarted()) => const NothingToContinue(),
};

ChapterState chapterStateOf({
  required Audiobook book,
  required TrackIndex index,
  required ResumeState saved,
  required PlayerState player,
}) => switch (player) {
  PlayerActive(
    :final playlist,
    :final trackIndex,
    :final position,
    :final length,
    :final status,
  )
      when playlist.kind == PlaylistKind.book &&
          playlist.id == book.id.playlistId &&
          trackIndex == index =>
    ChapterState(
      progress: TrackProgress.live(position: position, length: length),
      icon: status == ActiveStatus.playing
          ? ChapterIcon.pause
          : ChapterIcon.play,
    ),
  PlayerActive() || PlayerIdle() => ChapterState(
    progress: switch (saved) {
      ResumeAt(:final point) when point.trackIndex == index =>
        TrackProgress.ofResume(
          resume: saved,
          label: book.chapters[index.position].label.length,
        ),
      ResumeAt() || NotStarted() => const NoProgress(),
    },
    icon: ChapterIcon.play,
  ),
};
