import 'package:feature_meetings/src/widgets/meeting_texts.dart';
import 'package:flutter/widgets.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class FormatChips extends StatelessWidget {
  const FormatChips({
    required this.meetingId,
    required this.meetingName,
    required this.formats,
    super.key,
  });

  final MeetingId meetingId;
  final String meetingName;
  final List<MeetingFormat> formats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.meetingFormatsOpen,
      child: GestureDetector(
        key: Key('meeting-formats-${meetingId.value}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => showNaPopover(
          context: context,
          popoverKey: const Key('formats-popover'),
          closeKey: const Key('formats-popover-close'),
          title: l10n.meetingFormats,
          closeLabel: l10n.close,
          child: FormatsPopoverBody(meetingName: meetingName, formats: formats),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: formats
                  .map(
                    (format) => NaChip(
                      key: Key('format-chip-${format.key.value}'),
                      label: format.name.value,
                      tone: toneOf(category: format.category),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }
}

final class FormatsPopoverBody extends StatelessWidget {
  const FormatsPopoverBody({
    required this.meetingName,
    required this.formats,
    super.key,
  });

  final String meetingName;
  final List<MeetingFormat> formats;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            meetingName,
            style: theme.typography.heading.copyWith(color: theme.colors.ink),
          ),
          ...formats.map((format) => FormatRowView(format: format)),
        ],
      ),
    );
  }
}

final class FormatRowView extends StatelessWidget {
  const FormatRowView({required this.format, super.key});

  final MeetingFormat format;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Padding(
      key: Key('format-row-${format.key.value}'),
      padding: const EdgeInsets.only(top: Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NaBadge(
            label: format.key.value,
            tone: toneOf(category: format.category),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  format.name.value,
                  style: theme.typography.body.copyWith(
                    color: theme.colors.ink,
                  ),
                ),
                ...switch (format.description) {
                  Described(:final text) => [
                    Text(text.value, style: theme.typography.caption),
                  ],
                  NoDescription() => const <Widget>[],
                },
              ],
            ),
          ),
        ],
      ),
    );
  }
}
