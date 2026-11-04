@Tags(['unit'])
library;

import 'package:feature_media_player/feature_media_player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';
import 'package:na_testing/na_testing.dart';

ProgressTexts textsIn(String language) =>
    ProgressTexts(l10n: lookupAppLocalizations(Locale(language)));

String labelOf(ShownProgress progress) => switch (progress) {
  VisibleProgress(:final label) => label.value,
  HiddenProgress() => '',
};

void main() {
  test('continue label', () {
    final progress = textsIn('en').track(
      progress: TrackProgress.ofResume(
        resume: ResumeAt(
          point: aResumePoint(
            position: 65.seconds,
            length: KnownLength(duration: 600.seconds),
          ),
        ),
        label: const UnknownLength(),
      ),
    );
    expect(labelOf(progress), 'Continue from 1:05 · 8:55 left');
    expect(
      progress,
      const VisibleProgress(
        fraction: NaFraction(65 / 600),
        label: NaLabel('Continue from 1:05 · 8:55 left'),
      ),
    );
  });

  test('resume label in Danish', () {
    expect(
      labelOf(
        textsIn('da').track(
          progress: TrackProgress.ofResume(
            resume: ResumeAt(
              point: aResumePoint(
                position: 95.seconds,
                length: const UnknownLength(),
              ),
            ),
            label: KnownLength(duration: 490.seconds),
          ),
        ),
      ),
      'Fortsæt fra 1:35 · 6:35 tilbage',
    );
  });

  test('live labels with and without a length', () {
    final texts = textsIn('en');
    expect(
      labelOf(
        texts.track(
          progress: TrackProgress.live(
            position: 30.seconds,
            length: KnownLength(duration: 490.seconds),
          ),
        ),
      ),
      'Now playing · 0:30 / 8:10',
    );
    expect(
      labelOf(
        texts.track(
          progress: TrackProgress.live(
            position: 30.seconds,
            length: const UnknownLength(),
          ),
        ),
      ),
      'Now playing · 0:30',
    );
    expect(texts.track(progress: const NoProgress()), const HiddenProgress());
  });

  test('book labels', () {
    final texts = textsIn('en');
    expect(
      labelOf(
        texts.book(
          progress: SavedBookProgress(
            chapter: const TrackIndex(4),
            count: const ChapterCount(97),
            fraction: const KnownFraction(value: 0.1),
            remaining: KnownLength(duration: 3600.seconds),
          ),
        ),
      ),
      'Chapter 5 of 97 · 1:00:00 left',
    );
    expect(
      labelOf(
        texts.book(
          progress: const LiveBookProgress(
            chapter: TrackIndex(2),
            count: ChapterCount(39),
            fraction: UnknownFraction(),
          ),
        ),
      ),
      'Now playing · Chapter 3 of 39',
    );
    expect(
      texts.book(progress: const NoBookProgress()),
      const HiddenProgress(),
    );
    expect(const HiddenProgress().toString(), 'HiddenProgress');
    expect(const HiddenProgress().hashCode, const HiddenProgress().hashCode);
  });
}
