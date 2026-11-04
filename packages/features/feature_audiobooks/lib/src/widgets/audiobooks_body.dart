import 'package:feature_audiobooks/src/application/audiobook_catalog.dart';
import 'package:feature_audiobooks/src/application/book_views.dart';
import 'package:feature_audiobooks/src/widgets/book_cover.dart';
import 'package:feature_media_player/feature_media_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

typedef BookOpener = void Function(AudiobookId book);

final class AudiobooksBody extends StatelessWidget {
  const AudiobooksBody({required this.onOpen, super.key});

  final BookOpener onOpen;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: Space.sm),
    children: [
      for (final book in AudiobookId.values)
        AudiobookRow(
          key: Key('audiobook-row-${book.playlistId.value}'),
          book: book,
          onTap: () => onOpen(book),
        ),
    ],
  );
}

final class AudiobookRow extends ConsumerWidget {
  const AudiobookRow({required this.book, required this.onTap, super.key});

  final AudiobookId book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = NaTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final progress = ProgressTexts(l10n: l10n).book(
      progress: bookProgressOf(
        book: book,
        loaded: ref.watch(audiobookProvider(book)),
        library: ref.watch(resumePointsProvider),
        player: ref.watch(mediaPlayerProvider),
      ),
    );
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: switch (progress) {
              VisibleProgress() => theme.colors.onPrimary,
              HiddenProgress() => theme.colors.surface,
            },
            border: Border(bottom: BorderSide(color: theme.colors.background)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookCover(book: book, size: 64),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        book.title(l10n: l10n),
                        style: theme.typography.heading,
                      ),
                      const SizedBox(height: Space.xs),
                      BookTotal(book: book),
                      ProgressLine(progress: progress),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class BookTotal extends StatelessWidget {
  const BookTotal({required this.book, super.key});

  final AudiobookId book;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Row(
      children: [
        Icon(NaIcons.clock, size: 18, color: theme.colors.inkMuted),
        const SizedBox(width: Space.xs),
        Text(book.total.text, style: theme.typography.body),
      ],
    );
  }
}
