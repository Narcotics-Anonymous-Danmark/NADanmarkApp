# Design

## Context

Earlier slices provide:
- `adapter_wordpress` with `WordPressEndpoints`, optional Basic credentials and
  the `WordPressMimic` HTTP adapter (slice 5);
- `LoadResult`, `BusyTracker` and the global loading bar (slices 0–2);
- `NaCarousel`, `NaCard`, `NaCardTitle`, `NaMessageBlock`, `NaSkeletonRow`
  and the Home body with the cleantime and Just for today cards (slices 0, 3,
  5);
- `ExternalLinksPort` over `url_launcher` (slice 0).

What is missing: the calendar types, the port and adapter, the page, the Home
cards and a widget for remote thumbnails.

## Goals / Non-Goals

**Goals:**
- One fetch per session shared by the Events page and Home.
- Every row rule (date format, optional time, optional thumbnail) is a pure
  function, unit-tested without widgets.

**Non-Goals:**
- Recording the real feed: the endpoint needs the Basic-auth secret, so the
  fixtures are a synthetic sample with the shapes the legacy template handles
  (empty time, empty thumbnail).

## Decisions

### D1 Packages

`feature_events` is a page feature. It depends on the kernel, ports, design
and l10n only. Home is composed in `app/` (`na_router.dart`) like the
cleantime and JFT cards, so no feature imports another page feature.

### D2 Domain and mapping

`CalendarEvent { name, town, date: LocalDate, start: EventStart, thumbnail:
EventThumbnail, page: EventPageUrl }` with sealed `EventStart` (`StartsAt` /
`NoStartTime`) and `EventThumbnail` (`ThumbnailAt` / `NoThumbnail`). The
mapper keeps feed order, skips rows whose `event_start_date` is not
`yyyy-MM-dd` or whose `url` is not an absolute http(s) URL, reads the time as
`HH:mm[:ss]` (empty or unparsable becomes `NoStartTime`) and the thumbnail as
an absolute http(s) URL (else `NoThumbnail`).

### D3 Loader

`eventsProvider` is a kept-alive `NotifierProvider<EventsLoader,
LoadResult<List<CalendarEvent>>>` in the root container, so it is fetched once
per session whichever of Home and Events reads it first. `retry()` only acts
on `Failed`. Each fetch runs inside `BusyTracker` with
`BusyActivity.loadingEvents`.

### D4 In-app browser

`ExternalLinksPort.openInApp` uses `LaunchMode.inAppBrowserView`. This is the
platform's own in-app browser (Custom Tabs / `SFSafariViewController`), so no
WebView plugin, page or platform-view testing is added. The address is shown
by the system UI; recorded as an intentional delta. The planned
`webview_flutter` row in `docs/LEGACY_PARITY.md` is replaced.

### D5 Thumbnails

`NaThumbnail` in `na_design` renders a `NaImageSource` (`NetworkImageSource`
/ `AssetImageSource`) at 56×56 with rounded corners; a network image shows the
fallback asset while loading and on error. Uses `Image.network` with
`loadingBuilder`/`errorBuilder`; no caching package is added because the list
is small and fetched once per session.

### D6 Home cards

`EventsHomeCards` watches `eventsProvider` and renders a `NaCarousel` of at
most three `HomeEventCard`s (title "Events", then the same row content as the
page). Loading, failure and an empty feed render nothing. Tapping a card calls
the `onTap` supplied by the router (`go('/events')`).

### D7 Tests

`WordPressMimic` routes `/wp-json/wp/v2/calendar` by `category-slug`,
replying with `CalendarEvents`, or the existing error, unreachable, malformed
and held replies. `TestContainer` binds an `EventsFeedMimic` unless the
acceptance harness supplies the adapter over the HTTP mimic.
