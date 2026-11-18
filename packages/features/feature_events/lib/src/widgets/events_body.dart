import 'dart:async';

import 'package:feature_events/src/application/events_loader.dart';
import 'package:feature_events/src/widgets/event_summary.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';
import 'package:na_ports/na_ports.dart';

final class EventsBody extends ConsumerWidget {
  const EventsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(eventsProvider)) {
      Loading() => ListView(
        key: const Key('events-loading'),
        children: [for (final row in _placeholders) NaSkeletonRow(key: row)],
      ),
      Failed() => SingleChildScrollView(
        child: NaMessageBlock(
          key: const Key('events-failed'),
          title: NaLabel(l10n.eventsLoadError),
          body: NaLabel(l10n.eventsLoadErrorBody),
          action: NaMessageButton(
            label: NaLabel(l10n.eventsRetry),
            onPressed: () =>
                unawaited(ref.read(eventsProvider.notifier).retry()),
          ),
        ),
      ),
      Loaded(:final value) when value.isEmpty => SingleChildScrollView(
        child: NaMessageBlock(
          key: const Key('events-none'),
          title: NaLabel(l10n.eventsNone),
          body: NaLabel(l10n.eventsNoneBody),
          action: const NoMessageAction(),
        ),
      ),
      Loaded(:final value) => ListView.builder(
        key: const Key('events-list'),
        itemCount: value.length,
        itemBuilder: (context, index) => EventRow(
          key: Key('event-row-${value[index].page.uri}'),
          event: value[index],
        ),
      ),
    };
  }

  static final List<Key> _placeholders = List.unmodifiable(
    List.generate(6, (index) => Key('event-skeleton-$index')),
  );
}

final class EventRow extends ConsumerWidget {
  const EventRow({required this.event, super.key});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => unawaited(
        ref.read(externalLinksPortProvider).openInApp(uri: event.page.uri),
      ),
      child: NaListBlock(child: EventSummary(event: event)),
    ),
  );
}
