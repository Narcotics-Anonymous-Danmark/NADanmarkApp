@Tags(['acceptance'])
library;

import 'package:feature_audiobooks/feature_audiobooks.dart';
import 'package:feature_media_player/feature_media_player.dart';
import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';

import '../support/media.dart';
import '../support/pump_app.dart';

Future<AppHarness> pumpList({
  required WidgetTester tester,
  Map<String, String> storedValues = const {},
}) async {
  final app = await pumpAt(
    tester: tester,
    location: audiobooksPath,
    storedValues: storedValues,
  );
  addTearDown(app.dispose);
  return app;
}

Finder inRow(PlaylistId book, Finder matching) => find.descendant(
  of: find.byKey(Key('audiobook-row-${book.value}')),
  matching: matching,
);

void main() {
  group('Requirement: The three books', () {
    testWidgets('Chapter counts', (tester) async {
      final app = await pumpList(tester: tester);
      expect(
        AudiobookId.values.map(
          (book) => switch (app.container.read(audiobookProvider(book))) {
            Loaded(:final value) => value.chapters.length,
            Loading() || Failed() => -1,
          },
        ),
        [97, 39, 13],
      );
    });

    testWidgets('Totals match the chapters', (tester) async {
      await pumpList(tester: tester);
      expect(inRow(basicText, find.text('13:53:58')), findsOneWidget);
      expect(inRow(howAndWhy, find.text('06:11:37')), findsOneWidget);
      expect(
        inRow(const PlaylistId('step-working-guides'), find.text('05:03:49')),
        findsOneWidget,
      );
      for (final book in AudiobookId.values) {
        expect(
          bundledBook(book).chapterLengths.fold(
            Duration.zero,
            (sum, length) => sum + length.orZero,
          ),
          book.total.length.orZero,
        );
      }
    });
  });

  group('Requirement: Book page', () {
    testWidgets('Continue row shows the resume chapter', (tester) async {
      await pumpList(
        tester: tester,
        storedValues: savedAt(index: const TrackIndex(10)),
      );
      await openBook(tester, basicText);
      expect(pageText('Continue listening'), findsOneWidget);
      expect(find.byKey(const Key('book-continue-10')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('book-continue-10')),
          matching: find.text(
            bundledBook(AudiobookId.basicText).chapters[10].title.text,
          ),
        ),
        findsOneWidget,
      );
      expect(pageText('Chapters'), findsOneWidget);
      expect(find.byKey(const Key('book-chapter-0')), findsOneWidget);
    });

    testWidgets('No continue row for a new book', (tester) async {
      await pumpList(tester: tester);
      await openBook(tester, howAndWhy);
      expect(pageText('Continue listening'), findsNothing);
      expect(find.byKey(const Key('book-chapter-0')), findsOneWidget);
    });

    testWidgets('Book that cannot be read', (tester) async {
      final app = await pumpAt(
        tester: tester,
        location: const RoutePath('/home'),
      );
      addTearDown(app.dispose);
      app.container.audiobooks.serve(
        book: AudiobookId.stepWorkingGuides,
        outcome: const Err(error: UnavailableFailure(what: 'missing')),
      );
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('menu-audiobooks')));
      await settle(tester);
      await openBook(tester, const PlaylistId('step-working-guides'));
      expect(pageText('The book could not be loaded.'), findsOneWidget);
    });
  });

  group('Requirement: Back behaviour', () {
    testWidgets('System back returns to the list', (tester) async {
      final app = await pumpAt(
        tester: tester,
        location: const RoutePath('/step-working-guides'),
      );
      addTearDown(app.dispose);
      await pressBack(tester);
      expect(find.byKey(const Key('audiobook-row-basic-text')), findsOneWidget);
    });

    testWidgets('Header back keeps playing', (tester) async {
      final app = await pumpAt(
        tester: tester,
        location: const RoutePath('/how-and-why'),
      );
      addTearDown(app.dispose);
      await tapChapter(tester, const TrackIndex(1));
      await tester.tap(find.byKey(const Key('back-button')));
      await settle(tester);
      expect(
        find.byKey(const Key('audiobook-row-how-and-why')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('docked-player')), findsOneWidget);
      expect(activeOf(app).status, ActiveStatus.playing);
    });
  });

  group('Requirement: Refresh on return', () {
    testWidgets('Progress updates after listening', (tester) async {
      final app = await pumpList(tester: tester);
      await openBook(tester, basicText);
      await tapChapter(tester, const TrackIndex(0));
      await advance(app, tester, const Duration(seconds: 50));
      await tester.runAsync(
        () => app.container.read(mediaPlayerProvider.notifier).stop(),
      );
      await drain(tester);
      await tester.tap(find.byKey(const Key('back-button')));
      await settle(tester);
      expect(
        inRow(basicText, find.textContaining('Chapter 1 of 97 · ')),
        findsOneWidget,
      );
      expect(inRow(basicText, find.textContaining(' left')), findsOneWidget);
    });

    testWidgets('Finishing a book removes its progress', (tester) async {
      final last =
          bundledBook(AudiobookId.stepWorkingGuides).chapters.length - 1;
      final app = await pumpList(
        tester: tester,
        storedValues: savedAt(
          book: AudiobookId.stepWorkingGuides,
          index: TrackIndex(last),
        ),
      );
      expect(
        inRow(
          const PlaylistId('step-working-guides'),
          find.textContaining('Chapter 13 of 13'),
        ),
        findsOneWidget,
      );
      await openBook(tester, const PlaylistId('step-working-guides'));
      await tapChapter(tester, TrackIndex(last));
      app.engine.finish();
      await drain(tester);
      await tester.tap(find.byKey(const Key('back-button')));
      await settle(tester);
      expect(
        inRow(
          const PlaylistId('step-working-guides'),
          find.textContaining('Chapter'),
        ),
        findsNothing,
      );
    });
  });
}
