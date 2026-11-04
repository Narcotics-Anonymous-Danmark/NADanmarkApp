@Tags(['unit'])
library;

import 'package:adapter_assets/adapter_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';
import 'package:riverpod/riverpod.dart';

final class EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      throw FlutterError('Unable to load asset: "$key"');
}

T valueOf<T>(Outcome<T, Failure> outcome) => switch (outcome) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('$error'),
};

Duration totalOf(Audiobook book) => book.chapterLengths.fold(
  Duration.zero,
  (sum, length) => sum + length.orZero,
);

void main() {
  final bundle = RepoAssetBundle.locate();

  group('AssetAudiobooks', () {
    test('chapter counts', () async {
      final books = AssetAudiobooks(bundle: bundle);
      final counts = [
        for (final id in AudiobookId.values)
          valueOf(await books.load(book: id)).chapters.length,
      ];
      expect(counts, [97, 39, 13]);
    });

    test('totals match the chapters', () async {
      final books = AssetAudiobooks(bundle: bundle);
      for (final id in AudiobookId.values) {
        final book = valueOf(await books.load(book: id));
        expect(totalOf(book), id.total.length.orZero, reason: id.name);
      }
    });

    test('chapters keep their titles, URLs and labels', () async {
      final book = valueOf(
        await AssetAudiobooks(bundle: bundle).load(book: AudiobookId.basicText),
      );
      expect(book.title, const PlaylistTitle('Basis Tekst'));
      expect(
        book.chapters.first.title,
        const TrackTitle('01. Vores Symbol + Forord Til Sjette Udgave'),
      );
      expect(book.chapters.first.label, const DurationLabel('8:10'));
      expect(
        book.chapters.every(
          (chapter) =>
              chapter.url.uri.isScheme('https') &&
              chapter.url.uri.host == 'www.nadanmark.dk',
        ),
        isTrue,
      );
      final playlist = book.playlist(cover: const NoCover());
      expect(playlist.id, const PlaylistId('basic-text'));
      expect(playlist.kind, PlaylistKind.book);
      expect(
        playlist.tracks.first.id.value,
        book.chapters.first.url.uri.toString(),
      );
    });

    test('a missing asset is unavailable', () async {
      expect(
        await AssetAudiobooks(
          bundle: EmptyBundle(),
        ).load(book: AudiobookId.howAndWhy),
        isA<Err<Audiobook, Failure>>().having(
          (err) => err.error,
          'error',
          isA<UnavailableFailure>(),
        ),
      );
    });

    test('malformed books are decode failures', () {
      for (final text in [
        'not json',
        '[]',
        '{"bookTitle":"X","chapters":[]}',
        '{"chapters":[{"title":"a","url":"https://x.dk/a.mp3"}]}',
        '{"bookTitle":"X","chapters":[{"title":"a","url":"not a url"}]}',
        '{"bookTitle":"X","chapters":[{"title":"","url":"https://x.dk/a.mp3"}]}',
        '{"bookTitle":"X","chapters":"oops"}',
      ]) {
        expect(
          AssetAudiobooks.decode(book: AudiobookId.basicText, text: text),
          isA<Err<Audiobook, Failure>>(),
          reason: text,
        );
      }
    });

    test('a chapter without a duration has an unknown length', () {
      final book = valueOf(
        AssetAudiobooks.decode(
          book: AudiobookId.basicText,
          text:
              '{"bookTitle":"X","chapters":[{"title":"a","url":"https://x.dk/a.mp3"}]}',
        ),
      );
      expect(book.chapters.single.label.length, const UnknownLength());
    });
  });

  group('AssetReadings', () {
    test('seven readings with their colours', () async {
      final readings = valueOf(await AssetReadings(bundle: bundle).load());
      expect(readings.readings.map((reading) => reading.title.text), [
        'Hvem er en addict?',
        "Hvad er NA's program?",
        'Hvorfor er vi her?',
        'Sådan virker det',
        "NA's Tolv Traditioner",
        'Vi kommer i bedring',
        'Bare for i dag',
      ]);
      expect(readings.readings.map((reading) => reading.colour.argb), [
        0xFF9AD9E8,
        0xFFF8E937,
        0xFFF0E4AF,
        0xFFFFFFFF,
        0xFFE0DAD8,
        0xFF55CC80,
        0xFFD7B7D6,
      ]);
      expect(
        readings.readings[1].heading,
        const ReadingHeading('Hvad er Narcotics Anonymous’ program?'),
      );
    });

    test(
      'steps and traditions are numbered and step 3 is emphasised',
      () async {
        final readings = valueOf(await AssetReadings(bundle: bundle).load());
        List<ReadingLine> numbered(Reading reading) =>
            reading.blocks.whereType<NumberedList>().single.items;
        expect(numbered(readings.readings[3]), hasLength(12));
        expect(numbered(readings.readings[4]), hasLength(12));
        expect(
          numbered(readings.readings[3])[2].spans
              .where((span) => span.emphasis == Emphasis.emphasised)
              .single
              .text,
          const ReadingText('som vi opfattede Ham'),
        );
        expect(
          numbered(readings.readings[3])[2].plainText,
          endsWith('omsorgen fra Gud, som vi opfattede Ham.'),
        );
        expect(
          readings.readings[6].blocks.whereType<HangingParagraph>(),
          hasLength(5),
        );
      },
    );

    test('a missing asset is unavailable', () async {
      expect(
        await AssetReadings(bundle: EmptyBundle()).load(),
        isA<Err<ReadingCollection, Failure>>().having(
          (err) => err.error,
          'error',
          isA<UnavailableFailure>(),
        ),
      );
    });

    test('malformed readings are decode failures', () {
      const block = '{"kind":"paragraph","spans":[{"text":"a"}]}';
      const white = '"title":"a","heading":"a","background":"#FFFFFF"';
      const flagged =
          '{"kind":"paragraph","spans":[{"text":"a","emphasis":"yes"}]}';
      for (final text in [
        'not json',
        '[]',
        '[{"title":"a","heading":"a","background":"red","blocks":[$block]}]',
        '[{"title":"a","heading":"a","background":"#FFFFFF","blocks":[]}]',
        '[{"title":"","heading":"a","background":"#FFFFFF","blocks":[$block]}]',
        '[{$white,"blocks":[{"kind":"poem"}]}]',
        '[{$white,"blocks":[{"kind":"numbered","items":[]}]}]',
        '[{$white,"blocks":[{"kind":"hanging","spans":[]}]}]',
        '[{$white,"blocks":[$flagged]}]',
      ]) {
        expect(
          AssetReadings.decode(text: text),
          isA<Err<ReadingCollection, Failure>>(),
          reason: text,
        );
      }
    });
  });

  test('the overrides bind both ports', () {
    final container = ProviderContainer(
      overrides: assetsOverrides(bundle: bundle),
    );
    addTearDown(container.dispose);
    expect(container.read(audiobooksPortProvider), isA<AssetAudiobooks>());
    expect(container.read(readingsPortProvider), isA<AssetReadings>());
  });
}
