@Tags(['widget'])
library;

import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

void main() {
  testWidgets('the shell frames a page, opens the menu and lists entries', (
    tester,
  ) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: NaShell(
        location: MenuDestination.settings.path,
        child: const ShellPage(
          title: 'Indstillinger',
          back: NoBack(),
          footer: NoFooter(),
          body: SizedBox.shrink(),
        ),
      ),
    );
    expect(find.text('Indstillinger'), findsAtLeastNWidgets(1));
    expect(find.byKey(const Key('global-loading-bar')), findsNothing);
    await tester.tap(find.byKey(const Key('menu-button')));
    await tester.pumpAndSettle();
    expect(harness.read(menuControllerProvider), NaDrawerVisibility.open);
    expect(find.byKey(const Key('menu-version')), findsOneWidget);
    expect(find.text('Version: 2.0.0'), findsOneWidget);
    expect(
      tester
          .widget<NaMenuTile>(find.byKey(const Key('menu-settings')))
          .selected,
      NaSelection.selected,
    );
    harness.read(globalLoadingProvider.notifier).present(text: 'Locating…');
    await tester.pump();
    expect(find.byKey(const Key('global-loading-bar')), findsOneWidget);
  });

  testWidgets('a back affordance and a docked player are rendered', (
    tester,
  ) async {
    final harness = TestContainer.build(
      extra: [
        dockedPlayerProvider.overrideWithValue(
          const PlayerDocked(
            player: SizedBox(key: Key('player'), height: 64),
            height: 64,
          ),
        ),
      ],
    );
    addTearDown(harness.dispose);
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: NaShell(
        location: BookRoute.basicText.path,
        child: ShellPage(
          title: 'Basis Tekst',
          back: BackTo(parent: MenuDestination.audiobooks.path),
          footer: const NoFooter(),
          body: const HomeBody(cards: [SizedBox(key: Key('card'))]),
        ),
      ),
    );
    expect(find.byKey(const Key('back-button')), findsOneWidget);
    expect(find.byKey(const Key('player')), findsOneWidget);
    expect(find.byKey(const Key('welcome-title')), findsOneWidget);
    expect(find.byKey(const Key('card')), findsOneWidget);
    expect(
      tester.widget<NaPageFrame>(find.byType(NaPageFrame)).bottomInset,
      64,
    );
  });

  testWidgets('footer content is drawn in the page frame', (tester) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: NaShell(
        location: MenuDestination.nearby.path,
        child: const ShellPage(
          title: 'Møder i nærheden',
          back: NoBack(),
          footer: FooterContent(
            child: SizedBox(key: Key('footer'), height: 40),
          ),
          body: SizedBox.shrink(),
        ),
      ),
    );
    expect(
      tester.widget<NaPageFrame>(find.byType(NaPageFrame)).footer,
      isA<SizedBox>().having((box) => box.key, 'key', const Key('footer')),
    );
  });

  testWidgets('the locating activity shows the localised text', (
    tester,
  ) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: NaShell(
        location: MenuDestination.nearby.path,
        child: const ShellPage(
          title: 'Møder i nærheden',
          back: NoBack(),
          footer: NoFooter(),
          body: SizedBox.shrink(),
        ),
      ),
    );
    final span = BusyTracker(
      bus: harness.events,
    ).begin(activity: BusyActivity.locating);
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .widget<NaIndeterminateBar>(
            find.byKey(const Key('global-loading-bar')),
          )
          .statusText,
      'Finder position …',
    );
    span.end();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('global-loading-bar')), findsNothing);
  });
}
