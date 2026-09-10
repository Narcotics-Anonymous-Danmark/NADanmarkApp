import 'package:adapter_jft/adapter_jft.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_app/app/na_danmark_app.dart';
import 'package:na_app/app/na_router.dart';
import 'package:na_app/composition/app_startup.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

final class AppHarness {
  const AppHarness({required this.container, required this.systemPops});

  final TestContainer container;
  final List<String> systemPops;

  KeyValueStoreMimic get storage => container.storage;

  RecordingEventBus get events => container.events;

  ExternalLinksMimic get links => container.links;

  Future<void> dispose() => container.dispose();
}

TestContainer realJftContainer({
  Map<String, String> storedValues = const {},
  LegacyStoreRead legacyStore = const LegacyStoreAbsent(),
  AppInfo appInfo = testAppInfo,
  TestTime? time,
}) => TestContainer.buildAt(
  time: time ?? TestTime.copenhagen(startAt: anInstant()),
  storedValues: storedValues,
  legacyStore: legacyStore,
  appInfo: appInfo,
);

Future<AppHarness> pumpApp({
  required WidgetTester tester,
  TestContainer? container,
  String initialLocation = '/home',
}) async {
  tester.view.physicalSize = const Size(600, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final harness = container ?? realJftContainer();
  final systemPops = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.pop') {
        systemPops.add(call.method);
      }
      return null;
    },
  );
  harness.jft.outcome = await tester
      .runAsync(
        () => AssetJftSource(bundle: RepoAssetBundle.locate()).load(),
      )
      .then(
        (loaded) => loaded ?? const Err(error: UnavailableFailure(what: 'jft')),
      );
  await AppStartup(container: harness.container).run();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: NaDanmarkApp(
        router: createRouter(initialLocation: initialLocation),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppHarness(container: harness, systemPops: systemPops);
}

Finder inPage(Finder matching) =>
    find.descendant(of: find.byType(NaPageFrame), matching: matching);

Finder pageText(String text) => inPage(find.text(text));

Finder inMenu(Finder matching) =>
    find.descendant(of: find.byType(NaSideMenu), matching: matching);

Future<void> scrollPageTo(WidgetTester tester, Finder target) =>
    tester.scrollUntilVisible(
      target,
      200,
      scrollable: inPage(find.byType(Scrollable)),
    );

Future<void> openMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('menu-button')));
  await tester.pumpAndSettle();
}

Future<void> pressBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(
      const MethodCall('popRoute'),
    ),
    (data) {},
  );
  await tester.pumpAndSettle();
}

Future<void> chooseOption({
  required WidgetTester tester,
  required Key row,
  required String option,
}) async {
  await tester.tap(find.byKey(row));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}
