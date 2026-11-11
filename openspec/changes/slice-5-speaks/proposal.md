# Slice 5: speaks

## Why

Speaks are the recorded talks from Danish and foreign NA conventions. After
the books they are what members listen to most, and the legacy page is the
last media page still missing from the Flutter app. The player and the resume
points shipped in slice 4 already support speak playlists, so this slice adds
the feed, the catalogue rules and the page.

## What Changes

- **Speak catalogue** (`na_kernel`): the normalisation rules of the legacy
  `speaks.catalog.ts` as pure functions:
  - text folding and tidying;
  - convention, city, date, kind, speaker and edition parsing;
  - title, meta and context lines;
  - deduplication by URL, the conventions with counts, the years and the
    search text.
- **Feed DTOs and mapper** for the WordPress `speaks` endpoint.
- **Port**: `SpeaksFeedPort`, one call per feed language.
- **`adapter_wordpress`** (new): the feed over `dio` with Basic auth, from
  `NA_API_BASE_URL` and `NA_API_BASIC_AUTH`.
- **`feature_speaks`** (new):
  - the catalogue loader: both feeds, session cache, refresh;
  - the filter controller: query with a 200 ms debounce, conventions,
    languages, years, "only started", sort, the filter panel and paging;
  - the listing rules: filtering, year options, sorting, convention sections,
    pages of 40, and the continue-listening list;
  - the page with search, chips, filter panel, sticky convention headers,
    infinite scroll, pull-to-refresh, swipe to forget, and loading, error and
    empty states.
- **Design system**: search field, toggle chip and chip strip, swipe action,
  pull-to-refresh, message block, skeleton row, toolbar button, funnel icon.
- **App**: the `/speaks` route renders the page; the composition root binds
  the WordPress adapter.

Legacy behaviour not reproduced:
- The catalogue was rebuilt with translated kind labels on every language
  change. The kind is now a value, localised when rendered, and the search
  text holds the kind words of both languages.
- "Name" sorting used Danish collation (`localeCompare(…, 'da')`). It now
  compares the folded titles, so `Å` sorts with `A`. No collation library is
  added (see design D7).
- The "Filters" button was in the page header. It now sits next to the search
  field, because the shell header has no page actions.
- The avatar initial was computed but never shown; it is dropped.
- A convention section showed the city of its first visible speak. It now
  shows the convention's city, the first city seen in the feed.

## Non-goals

- Downloading speaks for offline listening.
- Speaks on Home (slice 6 composes Home).
- Cast and AirPlay (slice 9).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `speaks`:
  - feed credentials are optional, and a refresh that fails keeps the
    catalogue already shown;
  - search text with the kind words of both languages; no avatar initial;
  - folded-title sorting; convention city in section headers;
  - the Filters button next to the search field;
  - the speak cover for the lock screen.

## Impact

- **New packages**:
  - `packages/features/feature_speaks`, with the NA logo as the speak cover;
  - `packages/adapters/adapter_wordpress`, on `dio`.
- **Extended packages**:
  - `na_kernel`: `speaks/` types and rules, `speaks_wire.dart` DTOs and
    mapper; `unorm_dart 0.3.3` for NFD;
  - `na_ports`: `SpeaksFeedPort`;
  - `na_design`: `NaSearchField`, `NaSwipeActions`, `NaPullToRefresh`,
    `NaToggleChip`, `NaChipStrip`, `NaMessageBlock`, `NaSkeletonRow`,
    `NaToolbarButton`, `NaIcons.funnel`;
  - `na_testing`: `WordPressMimic`, `SpeaksFeedMimic`, speak builders and a
    sample feed;
  - `app`: route, configuration, overrides, acceptance tests, a Patrol test.
- **Configuration**: `coverage.yaml` floor for `adapter_wordpress`;
  `docs/LEGACY_PARITY.md` speak rows corrected to the real ARB keys.
