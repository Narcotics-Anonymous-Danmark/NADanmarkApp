@Tags(['widget'])
library;

import 'package:feature_contact/feature_contact.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

void main() {
  testWidgets('trial builds show the warning first and buttons open links', (
    tester,
  ) async {
    final harness = TestContainer.build(
      appInfo: anAppInfo(approval: BuildApproval.trial, buildType: 'dev'),
    );
    addTearDown(harness.dispose);
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: const ContactBody(),
    );
    expect(find.byKey(const Key('contact-not-approved')), findsOneWidget);
    expect(find.text('Buildtype: dev'), findsOneWidget);
    for (final name in [
      'meeting-list-servant',
      'website',
      'na-world',
      'source-code',
      'bug-reports',
    ]) {
      await tester.tap(find.byKey(Key('contact-link-$name')));
    }
    expect(harness.links.opened.map((u) => u.toString()), [
      'mailto:modelisteansvarlig@nadanmark.dk',
      'https://nadanmark.dk/',
      'https://na.org/',
      'https://github.com/Narcotics-Anonymous-Danmark/App',
      'mailto:app@nadanmark.dk',
    ]);
    expect(find.byKey(const Key('contact-imported-settings')), findsNothing);
  });

  testWidgets('approved builds hide the warning and show the import notice', (
    tester,
  ) async {
    final harness = TestContainer.build(
      storedValues: {'legacyMigration.completed': aMigrationMarker().encoded},
    );
    addTearDown(harness.dispose);
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: const ContactBody(),
    );
    expect(find.byKey(const Key('contact-not-approved')), findsNothing);
    expect(find.byKey(const Key('contact-imported-settings')), findsOneWidget);
  });
}
