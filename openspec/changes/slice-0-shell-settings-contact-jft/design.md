# Design

## Layers

kernel (`Settings`, `SettingKeys`, `SettingsCodec`, `Km`, `CleanTimeUnitOrder`,
`JftEntry`/`JftCalendar`/`DanishMonth`, `LegacyMigrationMarker`, `AppInfo`,
boundary `LegacySettingsTranslator`) ← ports (`SettingsPort`, `JftPort`,
`ExternalLinksPort`, `LegacyStorePort`, `appInfoProvider`) ← features and
adapters ← `app/`.

## Decisions

- Settings are stored under the legacy key names (`language`, `firstday`,
  `cleanTimeUnitSort`, `searchRange`) as strings; `SettingsCodec` decodes with
  per-key fallbacks so a malformed value never blocks the others.
- `SettingsController.load()` writes the resolved settings back, which is how
  the first start persists `da` and how malformed values get overwritten.
- The legacy import writes a key only when nothing is stored for it, then
  writes the marker even when the store is absent or unreadable.
- `LegacyStorePort` returns `LegacyStoreFound | LegacyStoreAbsent |
  LegacyStoreUnreadable`; the plugin answers `readAll` with a JSON object,
  `null` (no database) or a `PlatformException`.
- The native plugin loads `assets/na_migrate.html` at the legacy origin
  (`https://localhost` on Android through `shouldInterceptRequest`,
  `ionic://localhost` on iOS through `WKURLSchemeHandler`), dumps
  `_ionicstorage/_ionickv` with a cursor and reports through a JS bridge; a
  5 s timeout ends the read as unreadable.
- The side menu stays in the tree behind an `AnimatedSlide`; the menu state
  lives in `MenuController`. Back-button behaviour is a pure `BackRule`.
- `ConsumerWidget` is allowed by `avoid_stateful_widget`, which now checks the
  direct superclass only.
- Tests: `pumpFeature` in `na_testing` hosts a feature body under a
  `WidgetsApp` with a Navigator; acceptance tests load the real JFT asset via
  `tester.runAsync` and use a tall viewport so no scrolling is needed.

## Open points

- iOS native side is written but not compiled here (no Xcode on Linux).
- The 2 s import cut-off from the spec is not implemented; the plugin's 5 s
  timeout bounds the read instead.
