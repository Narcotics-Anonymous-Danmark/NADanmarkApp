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

**Strong types through `extension type const`.** Domain fields are never bare
`int`/`String`/`double`: ids, keys, URLs, names, texts, phone numbers, codes,
coordinates, distances and hours each get their own extension type, so two
values can never be swapped by mistake and the type says what the value is.

```dart
extension type const Km(double value) {}
extension type const MeetingId(int value) {}
```

**No vague types.** Never `Object`, `Object?`, `dynamic`, `List<(Object, Object)>`
or `Map<String, Object?>` where a precise type, a sealed hierarchy or a type
parameter can say what the value is. This applies to tests too: write one typed
test per value type (or a sealed test-case type) instead of a heterogeneous
`Object` list. Loosely typed data exists only in generated wire DTOs.

```dart
// bad
List<(Object, Object)> copies() => [(const InPerson(), const InPerson())];
// good
test('venues compare by value', () => expect(Virtual(link: link), Virtual(link: link)));
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

## Wire data and JSON

**JSON only through `json_serializable`.** No hand-written JSON parsers or readers.
Every JSON shape (HTTP APIs, caches, bundled assets, legacy dumps, CLI payloads)
is a `@JsonSerializable` wire DTO with its implementation in a generated
`part '<file>.g.dart'`, produced by `./bin/na gen json`. Generated files are never
edited by hand.

**Wire DTOs are lenient; domain types are strict.** Every DTO field is nullable,
without `checked` or `disallowUnrecognizedKeys`: the wire is never trusted. A
boundary mapper validates the DTO right after decoding and converts it into
domain types, returning `Outcome<Domain, DecodeFailure>`; malformed data becomes
an error value that is handled and reported, never a crash. Domain code never
sees a DTO.

```dart
// bad
final name = json['meeting_name'] as String;
// good
@JsonSerializable(createToJson: false)
final class BmltMeetingDto {
  const BmltMeetingDto({this.meetingName});
  factory BmltMeetingDto.fromJson(Map<String, dynamic> json) => _$BmltMeetingDtoFromJson(json);
  @JsonKey(name: 'meeting_name') final String? meetingName;
}
Outcome<Meeting, DecodeFailure> toMeeting(BmltMeetingDto dto) => ...;
```

## Dependencies and generated code

**Exact dependency versions.** Every third-party dependency and dev dependency is
pinned to one exact version (`dio: 5.8.0+1`), never a range (`^5.8.0`), so a commit
hash always reproduces the same build. Upgrades are deliberate commits.
`./bin/na check deps`.

**Internal packages are `0.0.0`.** Workspace packages are referenced by `path:`
only, declare `version: 0.0.0` and are never published. Only `app/` has a real
version, changed by `./bin/na release version`. `./bin/na check deps`.

**Generated code comes from `./bin/na gen`.** Localisations are generated from
the ARB files and JSON part files from the DTOs (`./bin/na gen l10n`, `gen json`,
`gen all`). Never hand-write or edit them.

**Prefer established solutions.** Do not hand-roll algorithms a library or the
platform already solves (locale collation, formatting, parsing, crypto). If no
library fits, simplify the requirement or raise the trade-off before writing one.

**No stray READMEs.** Explanations go into `docs/` or the relevant spec, not into
README files inside source, test or fixture folders.

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
