@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/media.dart';

void expectValue<T>(T Function() build, {required String text}) {
  final first = build();
  final second = build();
  expect(first, second);
  expect(first.hashCode, second.hashCode);
  expect(first.toString(), contains(text));
}

const SavedBookProgress Function({
  required TrackIndex chapter,
  required ChapterCount count,
  required ProgressFraction fraction,
  required MediaLength remaining,
})
savedBook = SavedBookProgress.new;
const LiveBookProgress Function({
  required TrackIndex chapter,
  required ChapterCount count,
  required ProgressFraction fraction,
})
liveBook = LiveBookProgress.new;

void main() {
  test('media values compare by value and describe themselves', () {
    expectValue(() => lengthOf(5.seconds), text: '5 s');
    expectValue(UnknownLength.new, text: 'UnknownLength');
    expectValue(
      () => const BundledCover(asset: AssetKey('covers/a.png')),
      text: 'covers/a.png',
    );
    expectValue(NoCover.new, text: 'NoCover');
    expectValue(aTrack, text: '01. Track');
    expectValue(PlayerIdle.new, text: 'PlayerIdle');
    expectValue(aPoint, text: 'ResumePoint(4 @ 120 s');
    expectValue(NotStarted.new, text: 'NotStarted');
    expectValue(() => ResumeAt(point: aPoint()), text: 'ResumeAt');
    expectValue(
      () => TrackStart(index: const TrackIndex(2), position: 3.seconds),
      text: 'TrackStart(2 @ 3 s)',
    );
    expectValue(
      () => const KnownFraction(value: 0.5),
      text: 'KnownFraction(0.5)',
    );
    expectValue(UnknownFraction.new, text: 'UnknownFraction');
    expectValue(NoProgress.new, text: 'NoProgress');
    expectValue(
      () => ResumeProgress(
        position: 5.seconds,
        fraction: const UnknownFraction(),
        remaining: const UnknownLength(),
      ),
      text: 'ResumeProgress(5 s',
    );
    expectValue(
      () => LiveProgress(
        position: 5.seconds,
        length: const UnknownLength(),
        fraction: const UnknownFraction(),
      ),
      text: 'LiveProgress(5 s',
    );
    expectValue(NoBookProgress.new, text: 'NoBookProgress');
    expectValue(
      () => savedBook(
        chapter: const TrackIndex(1),
        count: const ChapterCount(3),
        fraction: const UnknownFraction(),
        remaining: const UnknownLength(),
      ),
      text: 'SavedBookProgress(1/3',
    );
    expectValue(
      () => liveBook(
        chapter: const TrackIndex(1),
        count: const ChapterCount(3),
        fraction: const UnknownFraction(),
      ),
      text: 'LiveBookProgress(1/3',
    );
    expectValue(
      () => ResumeIndex.empty.withPoint(
        id: const PlaylistId('a'),
        point: aPoint(),
      ),
      text: 'ResumeIndex',
    );
    expect(const UnknownFraction().orZero, 0);
    expect(const TrackIndex(2).next, const TrackIndex(3));
    expect(const TrackIndex(2).previous, const TrackIndex(1));
    expect(const TrackIndex(2).ordinal, const ChapterCount(3));
    expect(lengthOf(5.seconds), isNot(const UnknownLength()));
  });

  test('resume DTOs and legacy entries compare by value', () {
    ResumePointDto dto() =>
        const ResumePointDto(trackId: 'a', trackIndex: 1, position: 2);
    expect(dto(), dto());
    expect(dto().hashCode, dto().hashCode);
    expect(dto(), isNot(const ResumePointDto(trackId: 'b')));
    LegacyResumeEntry entry() => LegacyResumeEntry(
      kind: PlaylistKind.book,
      id: const PlaylistId('basic-text'),
      point: aPoint(),
    );
    expect(entry(), entry());
    expect(entry().hashCode, entry().hashCode);
    expect(entry().toString(), contains('mediaResume.book.basic-text'));
  });
}
