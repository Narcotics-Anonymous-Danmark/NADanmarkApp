import 'package:feature_events/src/application/events_loader.dart';
import 'package:feature_events/src/widgets/event_summary.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class EventsHomeCards extends ConsumerWidget {
  const EventsHomeCards({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(homeEventsProvider)) {
      Loaded(:final value) when value.isNotEmpty => NaCarousel(
        key: const Key('home-events-carousel'),
        backdrop: NaBackdrop.primary,
        pages: List.unmodifiable(
          value.indexed.map(
            (entry) => HomeEventCard(
              key: Key('home-event-card-${entry.$1}'),
              event: entry.$2,
              onTap: onTap,
            ),
          ),
        ),
        pageLabels: List.unmodifiable(
          value.indexed.map(
            (entry) =>
                NaLabel(l10n.eventCardPosition(entry.$1 + 1, value.length)),
          ),
        ),
      ),
      Loaded() || Loading() || Failed() => const SizedBox.shrink(),
    };
  }
}

final class HomeEventCard extends StatelessWidget {
  const HomeEventCard({required this.event, required this.onTap, super.key});

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: NaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            NaCardTitle(text: AppLocalizations.of(context).events),
            EventSummary(event: event),
          ],
        ),
      ),
    ),
  );
}
