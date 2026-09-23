@Tags(['widget'])
library;

import 'package:feature_settings/feature_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_testing/na_testing.dart';

void main() {
  setUpAll(loadNaFonts);

  testWidgets('the settings page', (tester) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    await harness.read(settingsControllerProvider.notifier).load();
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: goldenFrame(
        child: const SizedBox(height: 420, child: SettingsBody()),
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'settings_page');
    await expectAccessible(tester);
  });
}
