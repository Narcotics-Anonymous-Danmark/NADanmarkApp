@Tags(['unit'])
library;

import 'package:test/test.dart';

import '../support/dates.dart';

void main() {
  group('AppVersion', () {
    test('computes the Play version code with the legacy formula', () {
      expect(aVersion(major: 1, minor: 3).versionCode, 1110300001);
      expect(aVersion().versionCode, 1120000001);
    });

    test('tags build one without a suffix', () {
      expect(aVersion().tag, '2.0.0');
    });

    test('tags later builds with a suffix', () {
      expect(aVersion(build: 2).tag, '2.0.0-b2');
    });
  });
}
