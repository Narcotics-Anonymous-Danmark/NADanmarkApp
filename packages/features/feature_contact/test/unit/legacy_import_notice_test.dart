@Tags(['unit'])
library;

import 'package:feature_contact/feature_contact.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_testing/na_testing.dart';

void main() {
  test('the notice is shown only after a marker with imported keys', () async {
    final harness = TestContainer.build(
      storedValues: {
        'legacyMigration.completed': aMigrationMarker(importedKeys: 2).encoded,
      },
    );
    addTearDown(harness.dispose);
    expect(
      await harness.read(legacyImportNoticeProvider.future),
      ImportNotice.shown,
    );
  });

  test(
    'no marker, zero imports or a malformed marker hide the notice',
    () async {
      for (final stored in [
        <String, String>{},
        {
          'legacyMigration.completed': aMigrationMarker(
            importedKeys: 0,
          ).encoded,
        },
        {'legacyMigration.completed': 'garbage'},
      ]) {
        final harness = TestContainer.build(storedValues: stored);
        expect(
          await harness.read(legacyImportNoticeProvider.future),
          ImportNotice.hidden,
        );
        await harness.dispose();
      }
    },
  );

  test('standard links point at the legacy targets', () {
    expect(ContactLinks.standard.website.toString(), 'https://nadanmark.dk/');
    expect(ContactLinks.standard.bugReports.scheme, 'mailto');
  });
}
