@Tags(['widget'])
library;

import 'package:feature_jft/feature_jft.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

void main() {
  setUpAll(loadNaFonts);

  testWidgets('the daily text page', (tester) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    await harness.read(jftControllerProvider.notifier).load();
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: goldenFrame(child: const SizedBox(height: 600, child: JftBody())),
    );
    await expectGolden(finder: goldenTarget, name: 'jft_page');
    await expectAccessible(tester);
  });

  testWidgets('the daily text error state', (tester) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    harness.jft.outcome = const Err(error: UnavailableFailure(what: 'jft'));
    await harness.read(jftControllerProvider.notifier).load();
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: goldenFrame(child: const SizedBox(height: 200, child: JftBody())),
    );
    await expectGolden(finder: goldenTarget, name: 'jft_error');
    await expectAccessible(tester);
  });

  testWidgets('the home preview card', (tester) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    await harness.read(jftControllerProvider.notifier).load();
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: goldenFrame(child: JftPreviewCard(onTap: () {})),
    );
    await expectGolden(finder: goldenTarget, name: 'jft_preview_card');
    await expectAccessible(tester);
  });
}
