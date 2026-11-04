import 'dart:async';

import 'package:feature_media_player/src/application/media_player.dart';
import 'package:feature_media_player/src/application/progress_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class DockedPlayerBar extends ConsumerWidget {
  const DockedPlayerBar({super.key});

  static const double height = 160;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = NaTheme.of(context);
    return DecoratedBox(
      key: const Key('docked-player'),
      decoration: BoxDecoration(
        color: theme.colors.surface,
        border: Border(top: BorderSide(color: theme.colors.border)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: Space.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: DockedTitles()),
                DockedCloseButton(),
              ],
            ),
            DockedScrubber(),
            DockedControls(),
          ],
        ),
      ),
    );
  }
}

final class DockedTitles extends ConsumerWidget {
  const DockedTitles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    mediaPlayerProvider.select<_TitlesView>(
      (state) => switch (state) {
        PlayerActive(:final track, :final playlist) => _Titles(
          track: track.title,
          playlist: playlist.title,
        ),
        PlayerIdle() => const _NoTitles(),
      },
    ),
  )) {
    _NoTitles() => const SizedBox.shrink(),
    _Titles(:final track, :final playlist) => DockedTitleLines(
      track: track,
      playlist: playlist,
    ),
  };
}

final class DockedTitleLines extends StatelessWidget {
  const DockedTitleLines({
    required this.track,
    required this.playlist,
    super.key,
  });

  final TrackTitle track;
  final PlaylistTitle playlist;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.text,
          key: const Key('docked-player-track'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.typography.label.copyWith(
            color: theme.colors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          playlist.text,
          key: const Key('docked-player-playlist'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.typography.caption,
        ),
      ],
    );
  }
}

final class DockedCloseButton extends ConsumerWidget {
  const DockedCloseButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => NaMediaButton(
    key: const Key('player-close'),
    icon: NaIcons.dismiss,
    label: NaLabel(AppLocalizations.of(context).playerClose),
    size: NaMediaButtonSize.regular,
    availability: NaAvailability.enabled,
    onPressed: () => unawaited(ref.read(mediaPlayerProvider.notifier).stop()),
  );
}

final class DockedScrubber extends ConsumerWidget {
  const DockedScrubber({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final texts = ProgressTexts(l10n: l10n);
    return switch (ref.watch(
      mediaPlayerProvider.select<_TimelineView>(
        (state) => switch (state) {
          PlayerActive(:final position, :final length, :final track) =>
            _Timeline(position: position, length: length, track: track.id),
          PlayerIdle() => const _NoTimeline(),
        },
      ),
    )) {
      _NoTimeline() => const SizedBox(height: NaScrubber.height),
      _Timeline(:final position, :final length, :final track) => NaScrubber(
        key: ValueKey(track),
        position: position,
        length: length,
        label: NaLabel(l10n.playerSeek),
        unknownLength: NaLabel(l10n.playerUnknownTime),
        timeText: (time) => texts.time(duration: time),
        onCommit: (target) => unawaited(
          ref.read(mediaPlayerProvider.notifier).seekTo(position: target),
        ),
      ),
    };
  }
}

final class DockedControls extends ConsumerWidget {
  const DockedControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    mediaPlayerProvider.select<_ControlsView>(
      (state) => switch (state) {
        PlayerActive(:final status, :final playlist, :final trackIndex) =>
          _Controls(
            status: status,
            kind: playlist.kind,
            previous: playlist.previousOf(index: trackIndex),
            next: playlist.nextOf(index: trackIndex),
          ),
        PlayerIdle() => const _NoControls(),
      },
    ),
  )) {
    _NoControls() => const SizedBox.shrink(),
    _Controls(:final status, :final kind, :final previous, :final next) =>
      DockedButtons(status: status, kind: kind, previous: previous, next: next),
  };
}

final class DockedButtons extends ConsumerWidget {
  const DockedButtons({
    required this.status,
    required this.kind,
    required this.previous,
    required this.next,
    super.key,
  });

  final ActiveStatus status;
  final PlaylistKind kind;
  final Neighbour previous;
  final Neighbour next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final player = ref.read(mediaPlayerProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (kind == PlaylistKind.book)
          NaMediaButton(
            key: const Key('player-previous'),
            icon: NaIcons.skipBack,
            label: NaLabel(l10n.playerPrevious),
            size: NaMediaButtonSize.regular,
            availability: _availability(neighbour: previous),
            onPressed: () => unawaited(player.previous()),
          ),
        NaMediaButton(
          key: const Key('player-rewind'),
          icon: NaIcons.rewind,
          label: NaLabel(l10n.playerRewind),
          size: NaMediaButtonSize.regular,
          availability: NaAvailability.enabled,
          onPressed: () =>
              unawaited(player.seekBy(delta: -MediaRules.skipBackward)),
        ),
        PlayPauseButton(status: status),
        NaMediaButton(
          key: const Key('player-forward'),
          icon: NaIcons.fastForward,
          label: NaLabel(l10n.playerForward),
          size: NaMediaButtonSize.regular,
          availability: NaAvailability.enabled,
          onPressed: () =>
              unawaited(player.seekBy(delta: MediaRules.skipForward)),
        ),
        if (kind == PlaylistKind.book)
          NaMediaButton(
            key: const Key('player-next'),
            icon: NaIcons.skipForward,
            label: NaLabel(l10n.playerNext),
            size: NaMediaButtonSize.regular,
            availability: _availability(neighbour: next),
            onPressed: () => unawaited(player.next()),
          ),
      ],
    );
  }

  static NaAvailability _availability({required Neighbour neighbour}) =>
      switch (neighbour) {
        Neighbour.available => NaAvailability.enabled,
        Neighbour.unavailable => NaAvailability.disabled,
      };
}

final class PlayPauseButton extends ConsumerWidget {
  const PlayPauseButton({required this.status, super.key});

  final ActiveStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final player = ref.read(mediaPlayerProvider.notifier);
    return switch (status) {
      ActiveStatus.loading => GestureDetector(
        key: const Key('player-play'),
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(player.toggle()),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: NaSpinner(
              key: const Key('player-spinner'),
              label: NaLabel(l10n.playerLoading),
              size: 36,
            ),
          ),
        ),
      ),
      ActiveStatus.playing => NaMediaButton(
        key: const Key('player-play'),
        icon: NaIcons.pauseFilled,
        label: NaLabel(l10n.playerPause),
        size: NaMediaButtonSize.large,
        availability: NaAvailability.enabled,
        onPressed: () => unawaited(player.toggle()),
      ),
      ActiveStatus.paused => NaMediaButton(
        key: const Key('player-play'),
        icon: NaIcons.playFilled,
        label: NaLabel(l10n.playerPlay),
        size: NaMediaButtonSize.large,
        availability: NaAvailability.enabled,
        onPressed: () => unawaited(player.toggle()),
      ),
    };
  }
}

@immutable
sealed class _TitlesView {
  const _TitlesView();
}

final class _NoTitles extends _TitlesView {
  const _NoTitles();

  @override
  int get hashCode => (_NoTitles).hashCode;

  @override
  bool operator ==(Object other) => other is _NoTitles;
}

final class _Titles extends _TitlesView {
  const _Titles({required this.track, required this.playlist});

  final TrackTitle track;
  final PlaylistTitle playlist;

  @override
  int get hashCode => Object.hash(track, playlist);

  @override
  bool operator ==(Object other) =>
      other is _Titles && other.track == track && other.playlist == playlist;
}

@immutable
sealed class _TimelineView {
  const _TimelineView();
}

final class _NoTimeline extends _TimelineView {
  const _NoTimeline();

  @override
  int get hashCode => (_NoTimeline).hashCode;

  @override
  bool operator ==(Object other) => other is _NoTimeline;
}

final class _Timeline extends _TimelineView {
  const _Timeline({
    required this.position,
    required this.length,
    required this.track,
  });

  final Duration position;
  final MediaLength length;
  final TrackId track;

  @override
  int get hashCode => Object.hash(position, length, track);

  @override
  bool operator ==(Object other) =>
      other is _Timeline &&
      other.position == position &&
      other.length == length &&
      other.track == track;
}

@immutable
sealed class _ControlsView {
  const _ControlsView();
}

final class _NoControls extends _ControlsView {
  const _NoControls();

  @override
  int get hashCode => (_NoControls).hashCode;

  @override
  bool operator ==(Object other) => other is _NoControls;
}

final class _Controls extends _ControlsView {
  const _Controls({
    required this.status,
    required this.kind,
    required this.previous,
    required this.next,
  });

  final ActiveStatus status;
  final PlaylistKind kind;
  final Neighbour previous;
  final Neighbour next;

  @override
  int get hashCode => Object.hash(status, kind, previous, next);

  @override
  bool operator ==(Object other) =>
      other is _Controls &&
      other.status == status &&
      other.kind == kind &&
      other.previous == previous &&
      other.next == next;
}
