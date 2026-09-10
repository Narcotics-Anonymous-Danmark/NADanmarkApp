@Tags(['widget'])
library;

import 'package:feature_jft/feature_jft.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

void main() {
  testWidgets('the body shows the entry, the closing lead and the copyright', (
    tester,
  ) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    await harness.read(jftControllerProvider.notifier).load();
    await pumpFeature(tester: tester, harness: harness, child: const JftBody());
    expect(find.text('10. september'), findsOneWidget);
    expect(find.text('Titel 10. september'), findsOneWidget);
    expect(find.byKey(const Key('jft-closing')), findsOneWidget);
    expect(find.textContaining('Copyright (c) 2007-2026'), findsOneWidget);
  });

  testWidgets('loading shows nothing and failures show the error card', (
    tester,
  ) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    await pumpFeature(tester: tester, harness: harness, child: const JftBody());
    expect(find.byType(NaCard), findsNothing);
    harness.jft.outcome = const Err(error: UnavailableFailure(what: 'asset'));
    await harness.read(jftControllerProvider.notifier).load();
    await tester.pumpAndSettle();
    expect(find.byType(NaErrorState), findsOneWidget);
    expect(find.text('Dagens tekst kunne ikke indlæses'), findsOneWidget);
  });

  testWidgets('a missing day also shows the error card', (tester) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    harness.jft.outcome = const Ok(value: JftCalendar(entries: []));
    await harness.read(jftControllerProvider.notifier).load();
    await pumpFeature(tester: tester, harness: harness, child: const JftBody());
    expect(find.byType(NaErrorState), findsOneWidget);
  });

  testWidgets('the preview card is absent until loaded and then tappable', (
    tester,
  ) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    var taps = 0;
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: JftPreviewCard(onTap: () => taps += 1),
    );
    expect(find.byKey(const Key('jft-preview-card')), findsNothing);
    await harness.read(jftControllerProvider.notifier).load();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('jft-preview-card')), findsOneWidget);
    expect(find.byKey(const Key('jft-closing')), findsNothing);
    await tester.tap(find.byKey(const Key('jft-preview-card')));
    expect(taps, 1);
  });

  testWidgets('a closing without the lead renders as plain text', (
    tester,
  ) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: JftEntryView(
        entry: aJftEntry(closing: 'Noget andet'),
        scale: JftScale.full,
      ),
    );
    expect(find.text('Noget andet'), findsOneWidget);
  });
}
