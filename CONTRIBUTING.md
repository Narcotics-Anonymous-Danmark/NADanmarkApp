# Contributing

## Set up

```
git clone https://github.com/Narcotics-Anonymous-Danmark/NADanmarkApp.git
cd NADanmarkApp
./bin/na bootstrap            # verifies Flutter (fvm) + JDK; Android SDK + AVD, CocoaPods, lefthook hooks
./bin/na doctor               # verify
./bin/na run                  # build and run on the connected device or an emulator
```

Read `AGENTS.md` (how we work), `docs/CODING_GUIDELINES.md` (rules, each with
its lint) and the spec of the capability you touch in
`openspec/specs/<capability>/spec.md`.

## Branches and commits

- Branch from `master` as `feat/<capability>`, `fix/<capability>-<what>`,
  `chore/<what>`, `docs/<what>`.
- Conventional Commits, scope = capability: `feat(cleantime): schedule
  anniversary notifications`. Enforced locally by lefthook (`commit-msg`) and
  in CI by the PR title check. Types: `feat`, `fix`, `refactor`, `test`,
  `docs`, `build`, `ci`, `chore`, `perf`.
- lefthook also runs `./bin/na format --check` and `./bin/na analyze` on
  commit and `./bin/na check` on push. Do not skip hooks.

## The OpenSpec workflow

1. `/opsx:propose <slug>` creates `openspec/changes/<slug>/` with
   `proposal.md`, spec deltas under `specs/<capability>/spec.md`, `design.md`
   and `tasks.md`. Open a PR with only the change folder and get it reviewed
   before writing code.
2. `/opsx:apply` implements the tasks, in this order: domain types → ports →
   mimics and builders → acceptance tests (red) → use cases → widgets → real
   adapter → one Patrol happy path.
3. Every `#### Scenario:` in the spec is an acceptance test named exactly like
   the scenario, in `app/test_acceptance/<capability>/`.
4. After merge, `/opsx:archive` folds the deltas into `openspec/specs/` and
   moves the change to `openspec/changes/archive/`.

A spec change without code is fine; code without a spec change is not.

## Before opening a PR

```
./bin/na check                                   # format, analyze, custom lints, ARB parity, deps, spec/test parity
./bin/na test unit widget acceptance --coverage
./bin/na coverage --merge --html --check         # floors from coverage.yaml
```

PR checklist:

- [ ] Title is a conventional commit.
- [ ] Linked OpenSpec change; every touched scenario has its acceptance test.
- [ ] New strings in both `app_en.arb` and `app_da.arb`.
- [ ] No nullable types, `!`, `bool` declarations, comments or `default` cases.
- [ ] Goldens updated on purpose (`./bin/na test widget --update-goldens`) and reviewed.
- [ ] `docs/LEGACY_PARITY.md` updated if a route, storage key, i18n key or plugin mapping changed.
- [ ] Coverage floors hold.

## Review expectations

- One reviewer approval; the reviewer runs the acceptance tests of the
  capability locally when the diff touches a `Notifier` or an adapter.
- Review against the spec first, the code second. A behaviour that is not in
  a spec or in "Intentional deltas" is a question, not a merge.
- Small PRs: one capability slice, under ~600 lines of non-test code.
- CI must be green: check, unit, widget, acceptance, E2E on Android emulator
  and iOS simulator.

## Running E2E locally

```
./bin/na bootstrap android        # once: SDK, AVD "na-e2e"
./bin/na test e2e --emulator      # Android
./bin/na test e2e --device        # a connected phone
./bin/na test e2e ios --simulator # macOS only
```

Patrol tests live in `app/integration_test/`; they use `env/test.json` and the
in-process mimic servers, so no network or credentials are needed. Real-device
runs on Firebase Test Lab happen nightly from CI.

## Never

- Call `flutter`, `dart`, `gradle`, `pod` or `patrol` directly for project tasks; use `./bin/na`.
- Import `package:flutter/material.dart` or `cupertino.dart`.
- Add a dependency from a feature to an adapter, from an adapter to a feature, or from anything to `app/`.
- Commit `env/release.json`, `app/ios/Flutter/Secrets.xcconfig`, `app/android/key.properties`, keystores or `.na-release/`.
- Change version numbers by hand.
- Add a translation to one ARB file only.
- Reproduce a legacy bug listed under "Intentional deltas" in a spec.
- Merge with a red or skipped test.
