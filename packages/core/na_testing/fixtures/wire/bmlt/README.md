Recorded from https://www.nadanmark.dk/main_server/client_interface/json/ on 2026-09-23.

- denmark_meetings.json: three rows of ?switcher=GetSearchResults&sort_keys=weekday_tinyint,start_time (contact fields, admin notes and the virtual link replaced by placeholders)
- denmark_municipalities.json: ?switcher=GetSearchResults&data_field_key=location_municipality&sort_keys=location_municipality
- formats_da.json: ?switcher=GetFormats&lang_enum=da
- formats_en.json: ?switcher=GetFormats&lang_enum=en

Refresh deliberately; builders and mimics default to these shapes.

`lib/src/generated/recorded_bmlt.dart` mirrors these files as Dart constants so builders and mimics also work on a device. `test/unit/bmlt_mimics_test.dart` fails when the two drift; regenerate the mirror whenever a file here changes.
