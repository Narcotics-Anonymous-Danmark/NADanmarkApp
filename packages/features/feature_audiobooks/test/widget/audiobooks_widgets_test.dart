@Tags(['widget'])
library;

import 'package:feature_audiobooks/feature_audiobooks.dart';
import 'package:feature_media_player/feature_media_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/harness.dart';

Map<String, String> savedAt({
  AudiobookId book = AudiobookId.basicText,
  TrackIndex index = const TrackIndex(4),
}) => aStoredResumePoint(
  id: book.playlistId,
  point: aResumePoint(trackIndex: index),
);

Finder inRow(AudiobookId book, Finder matching) => find.descendant(
  of: find.byKey(Key('audiobook-row-${book.playlistId.value}')),
  matching: matching,
);

void main() {
  setUpAll(loadNaFonts);

  group('AudiobooksBody', () {
    testWidgets('list shows three books with durations and saved progress', (
      tester,
    ) async {
      final harness = booksHarness(storedValues: savedAt());
      final opened = <AudiobookId>[];
      await pumpBooks(
        tester: tester,
        harness: harness,
        child: AudiobooksBody(onOpen: opened.add),
      );
      expect(find.text('13:53:58'), findsOneWidget);
      expect(find.text('06:11:37'), findsOneWidget);
      expect(find.text('05:03:49'), findsOneWidget);
      expect(
        inRow(AudiobookId.basicText, find.text('Chapter 5 of 5 · 6:10 left')),
        findsOneWidget,
      );
      expect(
        inRow(AudiobookId.howAndWhy, find.textContaining('Chapter')),
        findsNothing,
      );
      await expectGolden(finder: goldenTarget, name: 'audiobooks_list');
      await expectAccessible(tester);
      await tester.tap(
        find.byKey(const Key('audiobook-row-step-working-guides')),
      );
      expect(opened, [AudiobookId.stepWorkingGuides]);
    });

    testWidgets('live progress while playing', (tester) async {
      final harness = booksHarness();
      await pumpBooks(
        tester: tester,
        harness: harness,
        child: AudiobooksBody(onOpen: (book) {}),
      );
      await playIn(
        tester: tester,
        harness: harness,
        playlist: anAudiobook(
          id: AudiobookId.howAndWhy,
        ).playlist(cover: const NoCover()),
        index: const TrackIndex(2),
      );
      expect(
        inRow(AudiobookId.howAndWhy, find.text('Now playing · Chapter 3 of 5')),
        findsOneWidget,
      );
    });
  });

  group('BookBody', () {
    testWidgets('continue row shows the resume chapter', (tester) async {
      final harness = booksHarness(
        storedValues: savedAt(index: const TrackIndex(3)),
      );
      await pumpBooks(
        tester: tester,
        harness: harness,
        child: const BookBody(book: AudiobookId.basicText),
      );
      expect(find.byKey(const Key('book-continue-header')), findsOneWidget);
      expect(find.byKey(const Key('book-continue-3')), findsOneWidget);
      expect(find.byKey(const Key('book-chapters-header')), findsOneWidget);
      expect(find.text('Continue from 2:00 · 8:00 left'), findsNWidgets(2));
      expect(find.byKey(const Key('book-cover')), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'book_continue');
      await expectAccessible(tester);
    });

    testWidgets('no continue row for a new book', (tester) async {
      final harness = booksHarness();
      await pumpBooks(
        tester: tester,
        harness: harness,
        child: const BookBody(book: AudiobookId.howAndWhy),
      );
      expect(find.byKey(const Key('book-continue-header')), findsNothing);
      expect(find.byKey(const Key('book-chapter-0')), findsOneWidget);
    });

    testWidgets('tap starts the chapter and tapping it again pauses', (
      tester,
    ) async {
      final harness = booksHarness();
      await pumpBooks(
        tester: tester,
        harness: harness,
        child: const BookBody(book: AudiobookId.basicText),
      );
      await tester.tap(find.byKey(const Key('book-chapter-2')));
      await settleTaps(tester);
      final player = harness.read(mediaPlayerProvider);
      expect(
        player,
        isA<PlayerActive>()
            .having((active) => active.trackIndex, 'index', const TrackIndex(2))
            .having(
              (active) => active.playlist.cover,
              'cover',
              AudiobookId.basicText.playlistCover,
            ),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('book-chapter-2')),
          matching: find.byKey(const Key('chapter-icon-pause')),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('book-continue-2')), findsOneWidget);
      await tester.tap(find.byKey(const Key('book-chapter-2')));
      await settleTaps(tester);
      expect(
        harness.read(mediaPlayerProvider),
        isA<PlayerActive>().having(
          (active) => active.status,
          'status',
          ActiveStatus.paused,
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('book-chapter-2')),
          matching: find.byKey(const Key('chapter-icon-play')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a book that cannot be read shows an error', (tester) async {
      final harness = booksHarness();
      harness.audiobooks.serve(
        book: AudiobookId.stepWorkingGuides,
        outcome: const Err(error: UnavailableFailure(what: 'missing')),
      );
      await pumpBooks(
        tester: tester,
        harness: harness,
        child: const BookBody(book: AudiobookId.stepWorkingGuides),
      );
      expect(find.text('The book could not be loaded.'), findsOneWidget);
      expect(find.byKey(const Key('book-cover')), findsOneWidget);
    });
  });
}
