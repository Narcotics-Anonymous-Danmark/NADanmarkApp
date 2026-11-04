import 'dart:async';

import 'package:feature_audiobooks/src/application/audiobook_catalog.dart';
import 'package:feature_audiobooks/src/application/book_views.dart';
import 'package:feature_audiobooks/src/widgets/book_cover.dart';
import 'package:feature_media_player/feature_media_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class BookBody extends ConsumerWidget {
  const BookBody({required this.book, super.key});

  final AudiobookId book;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(audiobookProvider(book))) {
        Loading() => const BookHeader.loading(),
        Failed() => ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            BookCoverHeader(book: book),
            NaErrorState(
              message: AppLocalizations.of(context).audiobooksLoadFailed,
            ),
          ],
        ),
        Loaded(:final value) => ChapterList(book: value),
      };
}

final class BookHeader extends StatelessWidget {
  const BookHeader.loading({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class BookCoverHeader extends StatelessWidget {
  const BookCoverHeader({required this.book, super.key});

  final AudiobookId book;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.lg),
    child: Center(
      child: BookCover(key: const Key('book-cover'), book: book, size: 150),
    ),
  );
}

final class ChapterList extends ConsumerWidget {
  const ChapterList({required this.book, super.key});

  final Audiobook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final player = ref.watch(mediaPlayerProvider);
    final saved = savedFor(
      book: book.id,
      library: ref.watch(resumePointsProvider),
    );
    final lead = <Widget>[
      BookCoverHeader(book: book.id),
      ...switch (continueChapterOf(book: book, saved: saved, player: player)) {
        ContinueAt(:final index) => [
          BookSectionHeader(
            key: const Key('book-continue-header'),
            label: l10n.playerContinueListening,
          ),
          ChapterRow(
            key: Key('book-continue-${index.position}'),
            book: book,
            index: index,
          ),
          BookSectionHeader(
            key: const Key('book-chapters-header'),
            label: l10n.chapters,
          ),
        ],
        NothingToContinue() => const <Widget>[],
      },
    ];
    return ListView.builder(
      itemCount: lead.length + book.chapters.length,
      itemBuilder: (context, position) => position < lead.length
          ? lead[position]
          : ChapterRow(
              key: Key('book-chapter-${position - lead.length}'),
              book: book,
              index: TrackIndex(position - lead.length),
            ),
    );
  }
}

final class BookSectionHeader extends StatelessWidget {
  const BookSectionHeader({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Semantics(
      header: true,
      child: ColoredBox(
        color: theme.colors.background,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.md,
            Space.lg,
            Space.sm,
          ),
          child: Text(label, style: theme.typography.label),
        ),
      ),
    );
  }
}

final class ChapterRow extends ConsumerWidget {
  const ChapterRow({required this.book, required this.index, super.key});

  final Audiobook book;
  final TrackIndex index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = NaTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final chapter = book.chapters[index.position];
    final state = chapterStateOf(
      book: book,
      index: index,
      saved: savedFor(book: book.id, library: ref.watch(resumePointsProvider)),
      player: ref.watch(mediaPlayerProvider),
    );
    final progress = ProgressTexts(l10n: l10n).track(progress: state.progress);
    final highlighted = switch (progress) {
      VisibleProgress() => NaSelection.selected,
      HiddenProgress() => NaSelection.unselected,
    };
    return Semantics(
      button: true,
      hint: switch (state.icon) {
        ChapterIcon.play => l10n.playerPlay,
        ChapterIcon.pause => l10n.playerPause,
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(
          ref
              .read(mediaPlayerProvider.notifier)
              .play(
                playlist: book.playlist(cover: book.id.playlistCover),
                request: StartTrack(index: index),
              ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: switch (highlighted) {
              NaSelection.selected => theme.colors.onPrimary,
              NaSelection.unselected => theme.colors.surface,
            },
            border: Border(bottom: BorderSide(color: theme.colors.background)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.md,
              ),
              child: Row(
                children: [
                  Icon(
                    switch (state.icon) {
                      ChapterIcon.play => NaIcons.play,
                      ChapterIcon.pause => NaIcons.pause,
                    },
                    key: Key('chapter-icon-${state.icon.name}'),
                    size: 28,
                    color: switch (highlighted) {
                      NaSelection.selected => theme.colors.primary,
                      NaSelection.unselected => theme.colors.inkMuted,
                    },
                  ),
                  const SizedBox(width: Space.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          chapter.title.text,
                          style: theme.typography.body.copyWith(
                            color: theme.colors.ink,
                          ),
                        ),
                        Text(
                          chapter.label.text,
                          style: theme.typography.caption,
                        ),
                        ProgressLine(progress: progress),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
