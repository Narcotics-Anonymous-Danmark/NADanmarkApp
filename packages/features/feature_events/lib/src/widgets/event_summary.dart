import 'package:feature_events/src/application/event_texts.dart';
import 'package:flutter/widgets.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';

const AssetImage eventPlaceholder = AssetImage(
  'assets/img/na-logo-placeholder.png',
  package: 'feature_events',
);

final class EventSummary extends StatelessWidget {
  const EventSummary({required this.event, super.key});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NaThumbnail(
          image: switch (event.thumbnail) {
            ThumbnailAt(:final url) => NaRemoteImage(uri: url.uri),
            NoThumbnail() => const NaNoImage(),
          },
          fallback: eventPlaceholder,
        ),
        const SizedBox(width: Space.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                event.name.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.body.copyWith(color: theme.colors.ink),
              ),
              EventInfoLine(
                icon: NaIcons.calendar,
                text: NaLabel(
                  EventTexts.of(context: context).calendar(event: event).text,
                ),
              ),
              EventInfoLine(
                icon: NaIcons.mapPin,
                text: NaLabel(event.town.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class EventInfoLine extends StatelessWidget {
  const EventInfoLine({required this.icon, required this.text, super.key});

  final IconData icon;
  final NaLabel text;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colors.primary),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              text.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.caption,
            ),
          ),
        ],
      ),
    );
  }
}
