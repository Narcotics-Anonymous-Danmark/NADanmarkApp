@Tags(['unit'])
library;

import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/release/version_request.dart';
import 'package:test/test.dart';

import '../support/builders.dart';

void main() {
  VersionRequest request({
    final String positional = '',
    final String bump = '',
    final String build = '',
  }) => VersionRequest.from(
    positional: positional.isEmpty
        ? const OptionOmitted()
        : OptionGiven(value: positional),
    bump: bump.isEmpty ? const OptionOmitted() : OptionGiven(value: bump),
    build: build.isEmpty ? const OptionOmitted() : OptionGiven(value: build),
  );

  test('keeps the current version when nothing is requested', () {
    final resolved = request().resolve(current: anAppVersion(build: 3));
    expect((resolved as VersionResolved).version, anAppVersion(build: 3));
  });

  test('sets an explicit version with build 1 by default', () {
    final resolved = request(
      positional: '2.3.4',
    ).resolve(current: anAppVersion());
    expect(
      (resolved as VersionResolved).version,
      anAppVersion(minor: 3, patch: 4),
    );
  });

  test('honours --build', () {
    final resolved = request(
      positional: '2.3.4',
      build: '9',
    ).resolve(current: anAppVersion());
    expect((resolved as VersionResolved).version.build.value, 9);
  });

  test('bumps from the current version', () {
    final resolved = request(
      bump: 'minor',
    ).resolve(current: anAppVersion(build: 5));
    expect((resolved as VersionResolved).version, anAppVersion(minor: 1));
  });

  test('rejects version and bump together', () {
    final resolved = request(
      positional: '2.0.0',
      bump: 'patch',
    ).resolve(current: anAppVersion());
    expect(resolved, isA<VersionRequestRejected>());
  });

  test('rejects --build alone', () {
    expect(
      request(build: '2').resolve(current: anAppVersion()),
      isA<VersionRequestRejected>(),
    );
  });

  test('rejects an invalid build', () {
    expect(
      request(
        positional: '2.0.0',
        build: '1000',
      ).resolve(current: anAppVersion()),
      isA<VersionRequestRejected>(),
    );
  });
}
