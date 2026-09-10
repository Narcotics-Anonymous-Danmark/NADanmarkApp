@Tags(['unit'])
library;

import 'package:na_cli/src/release/pubspec_version.dart';
import 'package:na_cli/src/release/semantic_version.dart';
import 'package:na_cli/src/release/version.dart';
import 'package:test/test.dart';

import '../support/builders.dart';

void main() {
  group('version code formula', () {
    test('2.0.0 build 1 is 1120000001', () {
      expect(anAppVersion().code.value, 1120000001);
    });

    test('3.12.7 build 42 follows the formula', () {
      final version = anAppVersion(major: 3, minor: 12, patch: 7, build: 42);
      expect(version.code.value, 1100000000 + (30000 + 1200 + 7) * 1000 + 42);
    });

    test('reads the build back from a code', () {
      final parsed = AppVersion.fromCode(
        version: const SemanticVersion(major: 2, minor: 1, patch: 3),
        code: const VersionCode(1120103005),
      );
      expect(parsed, isA<AppVersionParsed>());
      expect((parsed as AppVersionParsed).version.build.value, 5);
    });

    test('rejects a code that does not match the formula', () {
      final parsed = AppVersion.fromCode(
        version: const SemanticVersion(major: 2, minor: 0, patch: 0),
        code: const VersionCode(1120001500),
      );
      expect(parsed, isA<AppVersionUnparseable>());
    });
  });

  group('tag', () {
    test('is x.y.z for build 1', () {
      expect(anAppVersion().tag.value, '2.0.0');
    });

    test('carries -b<build> otherwise', () {
      expect(anAppVersion(build: 7).tag.value, '2.0.0-b7');
    });
  });

  group('guards', () {
    test('accepts a regular version', () {
      expect(anAppVersion().validate(), isA<AppVersionAccepted>());
    });

    test('rejects minor >= 100, patch >= 100, build outside 1..999', () {
      final rejected = anAppVersion(
        minor: 100,
        patch: 100,
        build: 1000,
      ).validate();
      expect(rejected, isA<AppVersionRejected>());
      expect((rejected as AppVersionRejected).reasons, hasLength(3));
    });

    test('rejects build 0', () {
      expect(anAppVersion(build: 0).validate(), isA<AppVersionRejected>());
    });

    test('rejects a code above 2100000000', () {
      final rejected = anAppVersion(major: 100).validate();
      expect(rejected, isA<AppVersionRejected>());
    });
  });

  group('semantic version', () {
    test('parses x.y.z', () {
      final parsed = SemanticVersion.parse(text: '1.2.3');
      expect(
        (parsed as SemanticVersionParsed).version,
        const SemanticVersion(major: 1, minor: 2, patch: 3),
      );
    });

    test('rejects garbage', () {
      expect(
        SemanticVersion.parse(text: 'v1.2'),
        isA<SemanticVersionRejected>(),
      );
    });

    test('bumps each part and resets the lower ones', () {
      const v = SemanticVersion(major: 1, minor: 2, patch: 3);
      expect(v.bump(kind: BumpKind.patch).toString(), '1.2.4');
      expect(v.bump(kind: BumpKind.minor).toString(), '1.3.0');
      expect(v.bump(kind: BumpKind.major).toString(), '2.0.0');
    });

    test('parses bump kinds', () {
      expect(BumpKind.parse(text: 'minor'), isA<BumpKindParsed>());
      expect(BumpKind.parse(text: 'huge'), isA<BumpKindRejected>());
    });
  });

  group('pubspec version line', () {
    const editor = PubspecVersion();

    test('reads version and build', () {
      final parsed = editor.read(
        pubspecText: aPubspec(name: 'na_app', version: '2.0.0+1120000001'),
      );
      expect((parsed as AppVersionParsed).version, anAppVersion());
    });

    test('rewrites only the version line', () {
      final text = aPubspec(name: 'na_app', version: '2.0.0+1120000001');
      final written = editor.write(
        pubspecText: text,
        version: anAppVersion(minor: 1, build: 2),
      );
      expect(written, contains('version: 2.1.0+1120100002'));
      expect(written, contains('name: na_app'));
    });

    test('reports a missing version line', () {
      expect(
        editor.read(pubspecText: aPubspec()),
        isA<AppVersionUnparseable>(),
      );
    });
  });
}
