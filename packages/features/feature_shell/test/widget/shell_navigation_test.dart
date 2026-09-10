@Tags(['widget'])
library;

import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:na_design/na_design.dart';
import 'package:na_l10n/na_l10n.dart';
import 'package:na_testing/na_testing.dart';

GoRouter routerAt({required String location}) => GoRouter(
  initialLocation: location,
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          NaShell(location: RoutePath(state.uri.path), child: child),
      routes: [
        ...MenuDestination.values.map(
          (d) => GoRoute(
            path: d.path.value,
            builder: (context, state) => ShellPage(
              title: d.label(l10n: AppLocalizations.of(context)),
              back: const NoBack(),
              body: Text('page ${d.name}'),
            ),
          ),
        ),
        ...BookRoute.values.map(
          (b) => GoRoute(
            path: b.path.value,
            builder: (context, state) => ShellPage(
              title: b.label(l10n: AppLocalizations.of(context)),
              back: BackTo(parent: MenuDestination.audiobooks.path),
              body: Text('page ${b.name}'),
            ),
          ),
        ),
      ],
    ),
  ],
);

Future<TestContainer> pumpShell(
  WidgetTester tester, {
  required String location,
}) async {
  final harness = TestContainer.build();
  addTearDown(harness.dispose);
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: NaTheme(
        data: NaThemeData.light(),
        child: WidgetsApp.router(
          color: NaColors.light.primary,
          routerConfig: routerAt(location: location),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: supportedLocales,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

Future<void> systemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(
      const MethodCall('popRoute'),
    ),
    (data) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('menu taps navigate and close, back closes the menu first', (
    tester,
  ) async {
    final harness = await pumpShell(tester, location: '/home');
    await tester.tap(find.byKey(const Key('menu-button')));
    await tester.pumpAndSettle();
    await systemBack(tester);
    expect(harness.read(menuControllerProvider), NaDrawerVisibility.closed);
    await tester.tap(find.byKey(const Key('menu-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-events')));
    await tester.pumpAndSettle();
    expect(find.text('page events'), findsOneWidget);
    expect(harness.read(menuControllerProvider), NaDrawerVisibility.closed);
    await systemBack(tester);
    expect(find.text('page home'), findsOneWidget);
  });

  testWidgets('book pages go back to audiobooks by button and by system back', (
    tester,
  ) async {
    await pumpShell(tester, location: '/basic-text');
    await tester.tap(find.byKey(const Key('back-button')));
    await tester.pumpAndSettle();
    expect(find.text('page audiobooks'), findsOneWidget);
    await pumpShell(tester, location: '/how-and-why');
    await systemBack(tester);
    expect(find.text('page audiobooks'), findsOneWidget);
  });
}
