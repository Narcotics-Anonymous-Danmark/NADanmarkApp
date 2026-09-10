# Coding guidelines

One rule per line. Each rule names the lint that enforces it; `na_lints/*` are our
own rules in `tool/na_lints`, everything else is a core Dart lint. All rules apply
to `lib/` code in every package. Tests follow the same rules except where noted.

## Types

**Never a nullable type, never `!`.** Absence is a named state in a sealed class.
`na_lints/avoid_nullable_types`, `na_lints/avoid_non_null_assertion`.

```dart
// bad
Address? address;
// good
sealed class MeetingVenue {}
final class InPerson extends MeetingVenue { const InPerson({required this.address}); final Address address; }
final class Virtual extends MeetingVenue { const Virtual({required this.link}); final Uri link; }
```

**No generic `Option<T>`.** Only two generic sealed types exist: `Outcome<T, F>`
(`Ok` / `Err`) for use-case results and `LoadResult<T>` (`Loading` / `Loaded` /
`Failed`) for UI state. Every other absence gets its own sealed class.

**Never a `bool` declaration.** Two states get a named enum. Inline predicates inside
`where`, `any`, `every`, `contains` are the only allowed booleans.
`na_lints/avoid_bool_type`, `avoid_positional_boolean_parameters`.

```dart
// bad
final bool isClosed;
// good
enum TemporarilyClosed { closed, open }
```

**Strong types through `extension type const`.** Ids, keys, URLs, distances and
hours are never bare `int`/`String`/`double`.

```dart
extension type const Km(double value) {}
extension type const MeetingId(int value) {}
```

**Nullable and boolean values from the outside world stop at the boundary.** They
may appear only in `packages/adapters/**`, `na_kernel/lib/src/boundary/**`,
`na_design/lib/src/flutter_bridge/**` and generated code, and never in an
exported API.

## Control flow

**Exhaustive `switch` expressions with pattern matching, no `_` and no `default`.**
`na_lints/avoid_wildcard_switch`, `no_default_cases`.

```dart
final label = switch (venue) {
  InPerson(:final address) => address.city,
  Virtual(:final link) => link.host,
};
```

**Collections are transformed functionally.** `map`, `where`, `fold`, `expand`,
`sorted` from `package:collection`; results are unmodifiable. No mutating loops.

**Time comes from the `Clock`, `Ticker` and `Scheduler` ports.** Never
`DateTime.now()`, `Timer`, `Future.delayed`. `na_lints/no_direct_datetime_now_or_timer`.

## Structure

**Hexagonal.** `na_kernel` holds value types and pure logic, `na_ports` holds
`abstract interface class` ports, `packages/adapters/*` implement ports,
`packages/features/*` hold use cases and widgets, `app/` composes everything with
Riverpod overrides. Dependency direction is checked by `./bin/na check deps`.

**Composition over inheritance.** No class hierarchies except sealed data types
and `implements` of a port.

**Named parameters everywhere.** Positional parameters only for single-value
wrappers and overrides forced by Dart. `na_lints/prefer_named_parameters`.

**No default parameter values in production code.** Every call site states its
choice. Defaults live in test builders and `na_testing`.
`na_lints/avoid_default_parameter_values`.

**No comments.** Rename until the code explains itself. `na_lints/avoid_comments`.

**No singletons, no static state, no global `ProviderScope`.** Everything is
created in the composition root or a test container.

## Widgets

**Widgets layer only.** Never import `package:flutter/material.dart` or
`cupertino.dart`; use `na_design`. `na_lints/avoid_material_cupertino_import`.

**Small widgets, `const` constructors.** Every visually distinct piece is its own
class; no `_buildX()` helper methods. `prefer_const_constructors`,
`na_lints/avoid_build_helper_methods`.

**Stateless first.** `StatefulWidget` only inside `na_design/lib/src/flutter_bridge`.
Feature state lives in Riverpod `Notifier`s; widgets `ref.watch` the narrowest
`select`ed slice. `na_lints/avoid_stateful_widget`.

**Reactive by streams and listenables.** Cross-feature events go through the
`EventBus` port with sealed `DomainEvent`s. Adapters expose `Stream`s. No polling
where a stream exists.

## Localisation

**All user-facing text comes from ARB.** Keys in `app_en.arb` and `app_da.arb` are
kept in parity by `./bin/na check arb`. Code and specs use English strings.

## Tests

**Pure unit tests.** Only the subject under test is real; every collaborator is a
mimic or fake from `na_testing`.

**Builders, not fixtures.** `aMeeting(...)`, `aBmltMeetingJson(...)`: named,
optional parameters with realistic defaults; a test states only what matters.
Shared setup lives in `test/support/`, never repeated across tests.

**Mimics over mocks at the wire.** Adapters are tested against `BmltServerMimic`,
`WordPressMimic`, `KeyValueStoreMimic` and friends, which speak the real wire
format. Mocks only to verify call order a mimic cannot express.
