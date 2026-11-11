import 'dart:async';

import 'package:feature_media_player/feature_media_player.dart';
import 'package:feature_speaks/src/application/speak_row_view.dart';
import 'package:feature_speaks/src/application/speak_texts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

const PlaylistCover speakCover = BundledCover(
  asset: AssetKey('packages/feature_speaks/assets/covers/na-logo.png'),
);

enum SpeakLine { meta, context }

final class SpeakRow extends ConsumerWidget {
  const SpeakRow({required this.speak, required this.line, super.key});

  final Speak speak;
  final SpeakLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = NaTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final texts = SpeakTexts(l10n: l10n);
    final view = SpeakRowView.of(
      playback: ref.watch(
        mediaPlayerProvider.select(
          (player) => SpeakPlayback.of(id: speak.id, player: player),
        ),
      ),
      saved: ref.watch(
        resumePointsProvider.select(
          (library) => switch (library) {
            Loaded(:final value) => value.speaks.stateOf(id: speak.id),
            Loading() || Failed() => const NotStarted(),
          },
        ),
      ),
    );
    return Semantics(
      button: true,
      hint: switch (view.icon) {
        SpeakIcon.play || SpeakIcon.loading => l10n.playerPlay,
        SpeakIcon.pause => l10n.playerPause,
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(
          ref
              .read(mediaPlayerProvider.notifier)
              .play(
                playlist: speakPlaylist(
                  speak: speak,
                  trackTitle: texts.trackTitle(speak: speak),
                  cover: speakCover,
                ),
                request: const ContinueListening(),
              ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: switch (view.tone) {
              RowTone.started => theme.colors.onPrimary,
              RowTone.plain => theme.colors.surface,
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
                  SpeakRowIcon(icon: view.icon, tone: view.tone),
                  const SizedBox(width: Space.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          texts.title(speak: speak).value,
                          style: theme.typography.body.copyWith(
                            color: theme.colors.ink,
                          ),
                        ),
                        Text(
                          switch (line) {
                            SpeakLine.meta => texts.metaLine(speak: speak),
                            SpeakLine.context => texts.contextLine(
                              speak: speak,
                            ),
                          }.value,
                          style: theme.typography.caption,
                        ),
                        ProgressLine(
                          progress: ProgressTexts(
                            l10n: l10n,
                          ).track(progress: view.progress),
                        ),
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

final class SpeakRowIcon extends StatelessWidget {
  const SpeakRowIcon({required this.icon, required this.tone, super.key});

  final SpeakIcon icon;
  final RowTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return SizedBox.square(
      key: Key('speak-icon-${icon.name}'),
      dimension: 28,
      child: switch (icon) {
        SpeakIcon.loading => NaSpinner(
          label: NaLabel(AppLocalizations.of(context).playerLoading),
          size: 28,
        ),
        SpeakIcon.play || SpeakIcon.pause => Icon(
          switch (icon) {
            SpeakIcon.pause => NaIcons.pause,
            SpeakIcon.play || SpeakIcon.loading => NaIcons.play,
          },
          size: 28,
          color: switch (tone) {
            RowTone.started => theme.colors.primary,
            RowTone.plain => theme.colors.inkMuted,
          },
        ),
      },
    );
  }
}

final class SpeakSectionHeader extends StatelessWidget {
  const SpeakSectionHeader({required this.label, super.key});

  final NaLabel label;

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
          child: Text(label.value, style: theme.typography.label),
        ),
      ),
    );
  }
}

final class ContinueRow extends ConsumerWidget {
  const ContinueRow({required this.speak, super.key});

  final Speak speak;

  @override
  Widget build(BuildContext context, WidgetRef ref) => NaSwipeActions(
    actionLabel: NaLabel(AppLocalizations.of(context).speakForget),
    onAction: () => unawaited(
      ref
          .read(resumePointsProvider.notifier)
          .clear(kind: PlaylistKind.speak, id: speak.id),
    ),
    child: SpeakRow(speak: speak, line: SpeakLine.context),
  );
}
