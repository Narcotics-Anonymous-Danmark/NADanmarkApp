# Testing

Four levels, one convention: only the subject is real, everything else is a
builder or a mimic from `na_testing`. Run everything through `./bin/na test`.

## Levels

| Level | Where | Tag | What is real | Runs |
|---|---|---|---|---|
| Unit | `packages/*/test/unit/` | `unit` | One class or function | every commit, CI on every PR |
| Widget | `packages/*/test/widget/` | `widget` | One widget tree with `TestContainer`; goldens + `meetsGuideline` (text contrast, tap targets, labels) | every PR |
| Acceptance | `app/test_acceptance/<capability>/` | `acceptance` | The real shell (`main` composition minus adapters) under `TestContainer` with mimics at the wire | every PR |
| E2E | `app/integration_test/` (Patrol) | `e2e` | The whole app on a device | Android emulator + iOS simulator per PR; real devices nightly on Firebase Test Lab |

Acceptance tests are the contract: every `#### Scenario:` in
`openspec/specs/<capability>/spec.md` is one `testWidgets` whose description is
the scenario name verbatim, grouped by `### Requirement:`. `./bin/na check
specs` fails when a scenario has no test or a test has no scenario.

```dart
group('Requirement: Temporarily closed rule', () {
  testWidgets('TC without virtual link is closed', (tester) async {
    final container = TestContainer(overrides: [
      bmltMimic.overrides,
    ]);
    bmltMimic.searchResults([aBmltMeetingJson(formats: 'O,TC', virtualMeetingLink: '')]);
    await tester.pumpShell(container, initialRoute: '/listfull');
    ...
    expect(find.text('Temporarily closed'), findsOneWidget);
  });
});
```

## Rules that keep tests fast

- Every test must finish in well under a second. Run a file with
  `flutter test --timeout 20s <file>` when something hangs; a hang is a bug in
  the test, not a reason for a longer timeout.
- Real I/O (asset bundles, files, platform channels) inside `testWidgets` must
  go through `tester.runAsync`, otherwise the fake-async zone never completes it.
- Acceptance tests set a tall viewport (`tester.view.physicalSize`) so lazily
  built lists render fully instead of scrolling; there are two `Scrollable`s in
  the shell (menu + page), so scope finders with `inPage`/`inMenu`.
- Feature widget tests use `pumpFeature` from `na_testing`, which hosts the
  body under a `WidgetsApp` with a Navigator (dialogs need one).
- `flutter test .` from the repo root bundles no package assets. Tests that
  need a bundled asset read it from the repo with `RepoAssetBundle.locate()`
  (na_testing) instead of `rootBundle`, inside `tester.runAsync`.

## Builders and generators

- Domain builders: `aMeeting(...)`, `aMeetingFormat(...)`, `aCleantimeProfile(...)`,
  `aResumePoint(...)`, `aSpeak(...)`, `anEvent(...)`. Named optional parameters
  with realistic defaults; a test states only what matters.
- Wire builders: `aBmltMeetingJson(...)`, `aBmltFormatJson(...)`,
  `aWordPressEventJson(...)`, `aSpeaksGroupJson(...)`, `aLegacyStoreDump(...)`.
- `Gen` is a seedable generator (`Gen(seed: 42)`) for property-style tests
  (`gen.meetings(count: 200)`, `gen.speakYearField()`); the seed is printed on
  failure.

## Mimics

A mimic speaks the real wire format of the system it replaces, so adapters are
tested against the same bytes production sees and features never know the
difference.

| Mimic | Replaces | Why |
|---|---|---|
| `BmltServerMimic` | Both BMLT roots (HTTP) | Records exact query strings, serves `{}` for empty results, per-query fixtures |
| `WordPressMimic` | nadanmark.dk `wp-json` (events, speaks) | Asserts basic auth header, per-feed failures |
| `KeyValueStoreMimic` | `shared_preferences` | In-memory, inspectable, can be pre-seeded |
| `LegacyStoreMimic` | The Ionic IndexedDB plugin | Serves a legacy dump, can throw, can report "no database" |
| `AudioEngineMimic` | just_audio / audio_service | Drives `running`, `ended`, `error`, position; records seeks and loads |
| `GeolocationMimic` | Location plugin | Permission state, delayed or never-arriving positions |
| `NotificationCenterMimic` | Local notifications | Records `cancelAll` and scheduled notifications with ids, times and texts |
| `CastSessionMimic` | Cast SDK | Session state stream, receiver media status |

Mocks (`mocktail`) only where call order matters and a mimic cannot express it.

## Shared setup

`test/support/` in every package holds the shared pieces: `pump_shell.dart`,
`golden.dart`, `matchers.dart`, `fixtures/`. Nothing is copied between test
files. Package-level `dart_test.yaml` declares the tags.

## Fake time

`TestTime` implements `Clock`, `Ticker` and `Scheduler`.
`testTime.advance(const Duration(seconds: 5))` fires due tickers and
scheduled actions deterministically; `testTime.setToday(LocalDate(2026, 3, 1))`
fixes the calendar day. No test sleeps.

## Coverage

`coverage.yaml` sets floors: merged 80 %, features 95 %, kernel 95 %, adapters
80 %, app 70 %. `./bin/na test unit widget acceptance --coverage` writes lcov
per package; `./bin/na coverage --merge --html --check` merges, renders
`coverage/html/index.html` and fails below any floor. Generated files are
excluded.

## Running and debugging

| Task | CLI | VSCode |
|---|---|---|
| One level | `./bin/na test unit` / `widget` / `acceptance` / `e2e` | Test Explorer, or "na: test <level>" task |
| One file | `./bin/na test unit --file packages/core/na_kernel/test/unit/local_date_test.dart` | launch config "Test: current file" |
| One scenario | `./bin/na test acceptance --name "TC without virtual link is closed"` | Code lens on the `testWidgets` |
| Update goldens | `./bin/na test widget --update-goldens` | run the CLI in the terminal |
| E2E on emulator | `./bin/na emulator start` then `./bin/na test e2e --device emulator-5554` | task "na: test e2e android" |
| E2E on a device | `./bin/na test e2e --device <id>` (ids from `flutter devices`) | same task after plugging in the device |
| Coverage report | `./bin/na coverage --merge --html --check` | task "na: coverage html" |

Debugging acceptance tests: set a breakpoint, open the test and use the
"Test: current file" launch config; `TestTime` and mimics are plain objects, inspectable in the
debugger. Debugging E2E: `./bin/na test e2e --develop --target app/integration_test/<file>` keeps the app running
after the test and prints the Patrol log path.
