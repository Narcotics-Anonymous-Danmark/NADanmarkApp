# Slice 0: shell, settings, contact, JFT and settings migration

## Why

The Flutter rewrite needs one thin vertical slice that proves every layer end
to end before the meeting features land: routing and the side menu, a typed
settings store, the About page, the daily "Just for Today" text and the
one-time import of the four legacy settings keys.

## What changes

- `feature_shell`: side menu with the twelve legacy entries, page frame with
  header, global loading bar, docked player host slot, back-button rules and
  the home page (title, helpline, JFT preview card slot).
- `feature_settings`: `SettingsController` over a typed `SettingsPort`, live
  language switch, selector dialogs and the radius slider.
- `feature_contact`: the five About cards, external links through
  `ExternalLinksPort`, build information from `AppInfo`, the import notice.
- `feature_jft`: bundled 366 entries through `JftPort`, today's entry from the
  `Clock`, full page and clipped home preview.
- `feature_legacy_migration`: runs once before first render, translates the
  four settings keys, writes `legacyMigration.completed`, publishes
  `LegacyMigrationCompleted`.
- Adapters: `adapter_storage` (settings over shared_preferences),
  `adapter_jft` (bundled asset), `adapter_links` (url_launcher),
  `adapter_legacy_store` (native plugin reading the Ionic IndexedDB through an
  offscreen WebView on Android and iOS).
- `na_design`: header bar, side menu, drawer layout, cards, block button, list
  row, option dialog, slider, indeterminate bar, fade clip, icons.
- App: `GoRouter` shell with all sixteen routes, `AppStartup`, locale from the
  settings, `AppInfo` from `package_info_plus` and the build defines.

## Non-goals

Cleantime profiles, resume points and meeting formats stay in the legacy store
until slices 3 and 4; signing and the store uploads are tracked separately.

## Capabilities touched

app-shell, settings, contact, jft, legacy-migration, localisation.
