@Tags(['widget'])
library;

import 'package:feature_contact/feature_contact.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

Future<void> pumpContact(WidgetTester tester, AppInfo appInfo) async {
  tester.view.physicalSize = const Size(1080, 4800);
  addTearDown(tester.view.resetPhysicalSize);
  final harness = TestContainer.build(appInfo: appInfo);
  addTearDown(harness.dispose);
  await pumpFeature(
    tester: tester,
    harness: harness,
    child: goldenFrame(
      child: const SizedBox(height: 1500, child: ContactBody()),
    ),
  );
}

void main() {
  setUpAll(loadNaFonts);

  testWidgets('the about page of an approved build', (tester) async {
    await pumpContact(tester, anAppInfo());
    await expectGolden(finder: goldenTarget, name: 'contact_approved');
    await expectAccessible(tester);
  });

  testWidgets('the about page of a trial build', (tester) async {
    await pumpContact(
      tester,
      anAppInfo(approval: BuildApproval.trial, buildType: 'dev'),
    );
    await expectGolden(finder: goldenTarget, name: 'contact_trial');
    await expectAccessible(tester);
  });
}
