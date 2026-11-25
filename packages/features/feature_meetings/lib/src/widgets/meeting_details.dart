import 'package:feature_meetings/src/application/meeting_details_controller.dart';
import 'package:feature_meetings/src/widgets/meeting_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

Future<void> showMeetingDetails({
  required BuildContext context,
  required MeetingIds meetings,
}) {
  final l10n = AppLocalizations.of(context);
  return showNaPopover(
    context: context,
    popoverKey: const Key('meeting-details'),
    closeKey: const Key('meeting-details-close'),
    title: l10n.meetingDetails,
    closeLabel: l10n.close,
    child: MeetingDetailsBody(meetings: meetings),
  );
}

final class MeetingDetailsBody extends ConsumerWidget {
  const MeetingDetailsBody({required this.meetings, super.key});

  final MeetingIds meetings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(Space.md),
      child: switch (ref.watch(meetingDetailsProvider(meetings))) {
        Loading() => Center(
          child: NaSpinner(label: NaLabel(l10n.findingMtgs), size: 32),
        ),
        Failed() => MeetingDetailsFailed(
          onRetry: () =>
              ref.read(meetingDetailsProvider(meetings).notifier).retry(),
        ),
        Loaded(:final value) => Column(
          key: const Key('meeting-details-cards'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final meeting in value)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: MeetingCard(meeting: meeting),
              ),
          ],
        ),
      },
    );
  }
}

final class MeetingDetailsFailed extends StatelessWidget {
  const MeetingDetailsFailed({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NaErrorState(message: l10n.meetingsLoadFailed),
        NaButton(
          key: const Key('meeting-details-retry'),
          label: l10n.tryAgain,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
