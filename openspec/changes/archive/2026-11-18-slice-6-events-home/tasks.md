# Tasks

## 1. Kernel (D2)

- [x] 1.1 Add `na_kernel/lib/src/calendar/` (`CalendarEvent`, values, `EventStart`, `EventThumbnail`), `BusyActivity.loadingEvents` and `LocalTime.parseClock` (now shared with the BMLT mapper)
- [x] 1.2 Add `CalendarEventDto` and `CalendarMapper` (`./bin/na gen json`); verify lenient scalars, skipped rows, times, thumbnails, `{}` and non-list bodies

## 2. Ports, builders and mimics (D4, D7)

- [x] 2.1 Add `EventsFeedPort` and its unbound provider; add `ExternalLinksPort.openInApp`
- [x] 2.2 Extend `WordPressMimic` with the calendar route (`calendar` reply field, `holdCalendar`, `calendarRequests`, recorded content type); rename `SpeaksFeedBinding` to `WordPressBinding`; add `EventsFeedMimic` bound in `TestContainer`, event builders and a sample calendar; verify with mimic unit tests

## 3. Adapters

- [x] 3.1 Add `DioEventsFeed` and the `calendar` endpoint to `adapter_wordpress`; verify against `WordPressMimic`
- [x] 3.2 Implement `openInApp` in `adapter_links` with `LaunchMode.inAppBrowserView`

## 4. Feature (D3, D6)

- [x] 4.1 Create `feature_events` with `EventsLoader` and `EventTexts`; verify session cache, retry, busy span and calendar lines
- [x] 4.2 Add `NaThumbnail` to `na_design`; verify widget tests (its goldens are the event row and card goldens)
- [x] 4.3 Build `EventsBody`, `EventRow` and `EventsHomeCards`; verify widget tests for loading, error, empty, loaded and home states

## 5. App wiring

- [x] 5.1 Add the ARB keys in da and en; the loading-bar text in `feature_shell`
- [x] 5.2 Wire the `/events` route, the Home events cards and the events overrides
- [x] 5.3 Acceptance tests for every events scenario and the Home dashboard scenarios
- [x] 5.4 Update `docs/LEGACY_PARITY.md`; verify `./bin/na check arb`

## 6. Goldens, end to end and definition of done

- [x] 6.1 Goldens and `expectAccessible` for the list, error, empty and the Home card
- [x] 6.2 Patrol test `app/integration_test/events_test.dart`; verified on the `android-35` emulator
- [x] 6.3 Run `./bin/na check && ./bin/na test unit widget acceptance --coverage && ./bin/na coverage --merge --html --check`

## Workflow follow-up

- On archive, add the deltas listed at the end of `specs/events/spec.md`.
- Archive with `/opsx:archive slice-6-events-home` after the PR is merged.

## 7. Screenshots

- [x] 7.1 Capture da/en Android screenshots (events list, Home with event cards) into `docs/screenshots/events/`; captured on the `android-35` emulator with the sample calendar (`WordPressMimic`)
