@Tags(['unit'])
library;

import 'package:feature_media_player/feature_media_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/harness.dart';

const PlaylistId howAndWhy = PlaylistId('how-and-why');

void main() {
  test('the library loads both indexes from storage', () async {
    final harness = playerHarness(
      storedValues: aStoredResumePoint(point: aResumePoint(), id: howAndWhy),
    );
    expect(
      harness.container.read(resumePointsProvider),
      isA<Loading<ResumeLibrary>>(),
    );
    await flush();
    expect(
      harness.container.read(resumePointsProvider),
      Loaded(
        value: ResumeLibrary.empty.withIndex(
          kind: PlaylistKind.book,
          index: ResumeIndex.empty.withPoint(
            id: howAndWhy,
            point: aResumePoint(),
          ),
        ),
      ),
    );
  });

  test('clearing removes both', () async {
    final harness = playerHarness(
      storedValues: aStoredResumePoint(point: aResumePoint(), id: howAndWhy),
    );
    final points = harness.container.read(resumePointsProvider.notifier);
    await points.clear(kind: PlaylistKind.book, id: howAndWhy);
    expect(
      harness.storage.snapshot.containsKey('mediaResume.book.how-and-why'),
      isFalse,
    );
    expect(harness.index().points.containsKey(howAndWhy), isFalse);
    expect(
      harness.container.read(resumePointsProvider),
      const Loaded(value: ResumeLibrary.empty),
    );
  });

  test('clearing a point that is not indexed leaves the index alone', () async {
    final harness = playerHarness();
    final points = harness.container.read(resumePointsProvider.notifier);
    await points.clear(kind: PlaylistKind.speak, id: aSpeakUrl);
    expect(harness.storage.writes, isEmpty);
    expect(
      harness.storage.removals.single.name,
      'mediaResume.speak.${aSpeakUrl.value}',
    );
  });

  test('saving updates the point, the index and the library', () async {
    final harness = playerHarness();
    final points = harness.container.read(resumePointsProvider.notifier);
    await points.save(
      kind: PlaylistKind.speak,
      id: aSpeakUrl,
      point: aResumePoint(trackIndex: const TrackIndex(0)),
    );
    expect(
      await points.pointFor(kind: PlaylistKind.speak, id: aSpeakUrl),
      ResumeAt(point: aResumePoint(trackIndex: const TrackIndex(0))),
    );
    expect(
      harness.container.read(resumePointsProvider),
      isA<Loaded<ResumeLibrary>>().having(
        (loaded) => loaded.value.speaks.stateOf(id: aSpeakUrl),
        'speak',
        ResumeAt(point: aResumePoint(trackIndex: const TrackIndex(0))),
      ),
    );
    expect(
      await points.pointFor(kind: PlaylistKind.book, id: howAndWhy),
      const NotStarted(),
    );
  });

  test('an unreadable index reads as empty', () async {
    final harness = playerHarness(
      storedValues: const {'mediaResume.index.book': 'oops'},
    );
    harness.container.read(resumePointsProvider);
    await flush();
    expect(
      harness.container.read(resumePointsProvider),
      const Loaded(value: ResumeLibrary.empty),
    );
  });

  test('libraries compare by value', () {
    expect(ResumeLibrary.empty, ResumeLibrary.empty);
    expect(ResumeLibrary.empty.hashCode, ResumeLibrary.empty.hashCode);
    expect(ResumeLibrary.empty.of(kind: PlaylistKind.speak), ResumeIndex.empty);
    expect(ResumeLibrary.empty.toString(), contains('ResumeLibrary'));
  });
}
