import 'package:flutter/widgets.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

extension type const EventLine(String text) {}

final class EventTexts {
  EventTexts({required this.language})
    : _dates = LocalDateFormat(language: language);

  factory EventTexts.of({required BuildContext context}) => EventTexts(
    language: Language.fromCode(
      code: Localizations.localeOf(context).languageCode,
    ),
  );

  final Language language;
  final LocalDateFormat _dates;

  EventLine calendar({required CalendarEvent event}) {
    final date = _dates
        .format(date: event.date, pattern: DatePattern.dayDotShortMonthYear)
        .text;
    return EventLine(switch (event.start) {
      StartsAt(:final time) => '$date ${time.hhmm}',
      NoStartTime() => date,
    });
  }
}
