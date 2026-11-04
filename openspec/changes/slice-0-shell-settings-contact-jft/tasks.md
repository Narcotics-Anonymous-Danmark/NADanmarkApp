# Tasks

- [x] Kernel types: settings, codes, `Km`, JFT calendar, marker, translator
- [x] Ports and unbound providers; mimics and builders in `na_testing`
- [x] Adapters: storage settings, bundled JFT, url_launcher, legacy-store plugin (Dart, Android, iOS, HTML)
- [x] Design system components
- [x] Features: shell, settings, contact, jft, legacy migration
- [x] App wiring: router, startup, locale, `AppInfo`, production overrides
- [x] ARB keys (da + en) and regeneration
- [x] Acceptance tests for the spec scenarios of the six capabilities
- [x] Widget tests per feature and for the design primitives
- [ ] Compile and exercise the iOS plugin on macOS. While on macOS also:
  capture the iOS da/en screenshots for `docs/screenshots/meetings-search/`
  (municipalities, meeting list, formats popover from slice 1; nearby results,
  "Location not set" and error from slice 2), and check that "Meetings nearby"
  shows the `NSLocationWhenInUseUsageDescription` prompt with the legacy text
  and searches after "Allow While Using App" and after "Don't Allow".
  For slice 3: build iOS with `flutter_local_notifications` (the
  `UNUserNotificationCenter` delegate in `AppDelegate.swift`), check that the
  notification permission is asked on the first Home visit with an upcoming
  anniversary, that a scheduled Cleanday notification is delivered, and capture
  the iOS da/en screenshots for `docs/screenshots/cleantime/`.
  For slice 4: build iOS with `just_audio` and `audio_service` (the `audio`
  background mode in `Info.plist`), play a chapter of Basic Text, lock the
  screen and check that it keeps playing, that the lock-screen controls show
  the chapter, "Basis Tekst" and the cover, and that pause, ±15/30 and next
  work from there; capture the iOS da/en screenshots for
  `docs/screenshots/audiobooks/` and `docs/screenshots/readings/`
- [ ] Patrol run on the Android emulator through `./bin/na test e2e`
- [ ] Archive: fold into `openspec/specs/` once merged
