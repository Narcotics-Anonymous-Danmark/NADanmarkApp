import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';

extension type const EventSlug(String value) {
  String get page => 'https://nadanmark.test/event/$value/';

  EventPageUrl get pageUrl => EventPageUrl(Uri.parse(page));
}

extension type const WireText(String value) {}

const CalendarMapper _mapper = CalendarMapper();

CalendarEventDto aCalendarEventDto({
  EventSlug slug = const EventSlug('konvent'),
  WireText name = const WireText('Konvent'),
  WireText date = const WireText('2026-12-05'),
  WireText time = const WireText('19:30:00'),
  WireText town = const WireText('Aarhus'),
  WireText thumbnail = const WireText(''),
}) => CalendarEventDto(
  eventName: name.value,
  eventStartDate: date.value,
  eventStartTime: time.value,
  locationTown: town.value,
  thumbnail: thumbnail.value,
  url: slug.page,
);

CalendarEvent aCalendarEvent({
  EventSlug slug = const EventSlug('konvent'),
  WireText name = const WireText('Konvent'),
  WireText date = const WireText('2026-12-05'),
  WireText time = const WireText('19:30:00'),
  WireText town = const WireText('Aarhus'),
  WireText thumbnail = const WireText(''),
}) => calendarEventsOf(
  dtos: [
    aCalendarEventDto(
      slug: slug,
      name: name,
      date: date,
      time: time,
      town: town,
      thumbnail: thumbnail,
    ),
  ],
).single;

List<CalendarEvent> calendarEventsOf({required List<CalendarEventDto> dtos}) =>
    switch (_mapper.events(
      json: dtos.map((dto) => dto.toJson()).toList(),
    )) {
      Ok(:final value) => value,
      Err(:final error) => throw StateError('$error'),
    };

final List<CalendarEventDto> sampleCalendar = List.unmodifiable([
  aCalendarEventDto(
    slug: const EventSlug('kokna-31'),
    name: const WireText('KOKNA 31'),
    date: const WireText('2026-12-05'),
    time: const WireText('10:00:00'),
    town: const WireText('København'),
    thumbnail: const WireText('https://images.test/kokna-31.jpg'),
  ),
  aCalendarEventDto(
    slug: const EventSlug('julemode-aarhus'),
    name: const WireText('Julemøde i Aarhus'),
    date: const WireText('2026-12-24'),
    time: const WireText('19:30:00'),
    town: const WireText('Aarhus'),
  ),
  aCalendarEventDto(
    slug: const EventSlug('nytaar-odense'),
    name: const WireText('Nytårsfest'),
    date: const WireText('2026-12-31'),
    time: const WireText(''),
    town: const WireText('Odense'),
  ),
  aCalendarEventDto(
    slug: const EventSlug('servicekonference'),
    name: const WireText('Servicekonference'),
    date: const WireText('2027-02-13'),
    time: const WireText('09:00:00'),
    town: const WireText('Vejle'),
  ),
  aCalendarEventDto(
    slug: const EventSlug('camp-2027'),
    name: const WireText('NA Camp 2027'),
    date: const WireText('2027-07-02'),
    time: const WireText(''),
    town: const WireText('Silkeborg'),
  ),
]);
