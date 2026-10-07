import 'dart:async';

import 'package:feature_meetings/src/application/meeting_formats_controller.dart';
import 'package:feature_meetings/src/widgets/meeting_formats.dart';
import 'package:feature_meetings/src/widgets/meeting_texts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';
import 'package:na_ports/na_ports.dart';

final class MeetingCard extends ConsumerWidget {
  const MeetingCard({required this.meeting, super.key});

  final Meeting meeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = NaTheme.of(context);
    final index = ref.watch(
      formatIndexProvider(languageOf(context: context)),
    );
    final formats = switch (index) {
      Loaded(:final value) => value.formatsOf(
        codes: meeting.formatCodes,
        origin: meeting.origin,
      ),
      Loading() || Failed() => const <MeetingFormat>[],
    };
    return NaCard(
      key: Key('meeting-card-${meeting.id.value}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MeetingBadge(meeting: meeting),
          ...switch (meeting.closure) {
            TemporaryClosure.temporarilyClosed => [
              ClosedChip(meetingId: meeting.id),
            ],
            TemporaryClosure.open => const <Widget>[],
          },
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Text(
              meeting.name.value,
              style: theme.typography.display.copyWith(
                color: theme.colors.ink,
              ),
            ),
          ),
          if (formats.isNotEmpty)
            FormatChips(
              meetingId: meeting.id,
              meetingName: meeting.name.value,
              formats: formats,
            ),
          LocationLines(meeting: meeting),
          ...switch (meeting.comment) {
            Comment(:final text) => [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.sm),
                child: NaNote(text: text.value),
              ),
            ],
            NoComment() => const <Widget>[],
          },
          ContactLines(meeting: meeting),
          MeetingActions(meeting: meeting),
        ],
      ),
    );
  }
}

final class MeetingBadge extends StatelessWidget {
  const MeetingBadge({required this.meeting, super.key});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = NaTheme.of(context);
    final times = meeting.times;
    return Text(
      l10n.meetingBadge(
        l10n.weekdayName(weekday: meeting.weekday),
        times.start.hhmm,
        times.end.hhmm,
      ),
      key: Key('meeting-badge-${meeting.id.value}'),
      style: theme.typography.label.copyWith(color: theme.colors.ink),
    );
  }
}

final class ClosedChip extends StatelessWidget {
  const ClosedChip({required this.meetingId, super.key});

  final MeetingId meetingId;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.sm),
    child: NaChip(
      key: Key('meeting-closed-${meetingId.value}'),
      label: AppLocalizations.of(context).tempClosed,
      tone: NaChipTone.danger,
    ),
  );
}

final class LocationLines extends StatelessWidget {
  const LocationLines({required this.meeting, super.key});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final style = NaTheme.of(context).typography.body;
    return Column(
      key: Key('meeting-location-${meeting.id.value}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: meeting.locationLines
          .map((line) => Text(line.text, style: style))
          .toList(growable: false),
    );
  }
}

final class ContactLines extends StatelessWidget {
  const ContactLines({required this.meeting, super.key});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = NaTheme.of(context).typography.body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...meeting.contactLines.map((line) => Text(line.text, style: style)),
        ...meeting.transitLines.map(
          (line) => Text(
            switch (line.kind) {
              TransitKind.train => l10n.meetingTrainLines(line.lines.value),
              TransitKind.bus => l10n.meetingBusLines(line.lines.value),
            },
            style: style,
          ),
        ),
      ],
    );
  }
}

final class MeetingActions extends ConsumerWidget {
  const MeetingActions({required this.meeting, super.key});

  final Meeting meeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = meeting.id.value;
    void open(Uri uri) =>
        unawaited(ref.read(externalLinksPortProvider).open(uri: uri));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: meeting.actions
          .map(
            (action) => switch (action) {
              OpenDirections(:final uri) => NaActionButton(
                key: Key('meeting-directions-$id'),
                icon: NaIcons.mapPin,
                label: l10n.map,
                onPressed: () => open(uri),
              ),
              JoinVirtualMeeting(:final uri) => NaActionButton(
                key: Key('meeting-virtual-$id'),
                icon: NaIcons.cloud,
                label: l10n.virtualLink,
                onPressed: () => open(uri),
              ),
              CallDialIn(:final uri) => NaActionButton(
                key: Key('meeting-dial-in-$id'),
                icon: NaIcons.phone,
                label: l10n.phoneMeeting,
                onPressed: () => open(uri),
              ),
            },
          )
          .toList(growable: false),
    );
  }
}
