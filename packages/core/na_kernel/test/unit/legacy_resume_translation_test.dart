@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/media.dart';

const LegacyResumeTranslator translator = LegacyResumeTranslator();
final Instant importTime = Instant(DateTime.utc(2026, 11, 4, 9));
const String speakUrl = 'https://x.dk/a.mp3';

LegacyResumeTranslation translated(WireObject dump) => translator.translate(
  dump: LegacyStoreDumpDto.fromJson(dump),
  importedAt: importTime,
);

const WireObject basicTextPoint = {
  'trackId': 'u4',
  'trackIndex': 4,
  'position': 120,
  'duration': 600,
  'updatedAt': '2026-05-01T10:00:00.000Z',
};

const WireObject speakPoint = {
  'trackId': speakUrl,
  'trackIndex': 0,
  'position': 250,
  'updatedAt': '2026-05-02T10:00:00.000Z',
};

void main() {
  test('resume points and index', () {
    final result = translated({
      'mediaResume.book.basic-text': basicTextPoint,
      'mediaResume.speak.$speakUrl': speakPoint,
      'language': 'da',
    });
    final book = aPoint(
      trackId: const TrackId('u4'),
      updatedAt: Instant(DateTime.utc(2026, 5, 1, 10)),
    );
    final speak = aPoint(
      trackId: const TrackId(speakUrl),
      trackIndex: const TrackIndex(0),
      position: 250.seconds,
      length: const UnknownLength(),
      updatedAt: Instant(DateTime.utc(2026, 5, 2, 10)),
    );
    expect(result.entries, [
      LegacyResumeEntry(
        kind: PlaylistKind.book,
        id: const PlaylistId('basic-text'),
        point: book,
      ),
      LegacyResumeEntry(
        kind: PlaylistKind.speak,
        id: const PlaylistId(speakUrl),
        point: speak,
      ),
    ]);
    expect(
      result.indexOf(kind: PlaylistKind.book),
      ResumeIndex.empty.withPoint(
        id: const PlaylistId('basic-text'),
        point: book,
      ),
    );
    expect(
      result.indexOf(kind: PlaylistKind.speak),
      ResumeIndex.empty.withPoint(id: const PlaylistId(speakUrl), point: speak),
    );
    expect(result.importedKeys, const [
      StorageKey('mediaResume.book.basic-text'),
      StorageKey('mediaResume.speak.$speakUrl'),
    ]);
    expect(result.skippedKeys, isEmpty);
  });

  test('stale legacy index is not trusted', () {
    final result = translated({
      'mediaResume.index.book': {'how-and-why': basicTextPoint},
    });
    expect(result.entries, isEmpty);
    expect(result.importedKeys, isEmpty);
    expect(result.skippedKeys, isEmpty);
    expect(result.indexOf(kind: PlaylistKind.book), ResumeIndex.empty);
  });

  test('malformed points are skipped', () {
    final result = translated({
      'mediaResume.book.how-and-why': {'trackIndex': 'two', 'position': 5},
      'mediaResume.book.': basicTextPoint,
      'mediaResume.speak.$speakUrl': 'not json',
    });
    expect(result.entries, isEmpty);
    expect(result.skippedKeys, const [
      StorageKey('mediaResume.book.how-and-why'),
      StorageKey('mediaResume.book.'),
      StorageKey('mediaResume.speak.$speakUrl'),
    ]);
  });

  test('points stored as JSON text are read and the time falls back', () {
    final result = translated({
      'mediaResume.book.how-and-why':
          '{"trackId":"u2","trackIndex":2,"position":30}',
    });
    expect(result.entries.single.point.updatedAt, importTime);
    expect(result.entries.single.point.trackIndex, const TrackIndex(2));
  });

  test('a dump without resume keys translates to nothing', () {
    final result = translated({'language': 'en'});
    expect(result, translated({}));
    expect(result.entries, isEmpty);
    expect(result.toString(), contains('LegacyResumeTranslation'));
    expect(result.hashCode, translated({}).hashCode);
  });

  test('the dump keeps the resume entries in its JSON', () {
    final dump = LegacyStoreDumpDto.fromJson(const {
      'mediaResume.book.basic-text': basicTextPoint,
    });
    expect(dump.toJson()['mediaResume'], {
      'mediaResume.book.basic-text': basicTextPoint,
    });
    expect(
      dump,
      LegacyStoreDumpDto.fromJson(const {
        'mediaResume.book.basic-text': basicTextPoint,
      }),
    );
  });
}
