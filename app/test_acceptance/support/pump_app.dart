import 'package:adapter_bmlt/adapter_bmlt.dart';
import 'package:adapter_jft/adapter_jft.dart';
import 'package:dio/dio.dart';
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

const testBmltEndpoints = BmltEndpoints(
  denmark: BmltBaseUrl(
    'https://denmark.test/main_server/client_interface/json/',
  ),
  tomato: BmltBaseUrl('https://tomato.test/main_server/client_interface/json/'),
);

TestContainer realJftContainer({
  Map<String, String> storedValues = const {},
  LegacyStoreRead legacyStore = const LegacyStoreAbsent(),
  AppInfo appInfo = testAppInfo,
  TestTime? time,
  BmltServerMimic? bmlt,
}) => TestContainer.buildAt(
  time: time ?? TestTime.copenhagen(startAt: anInstant()),
  storedValues: storedValues,
  legacyStore: legacyStore,
  appInfo: appInfo,
  meetingPorts: MeetingPortBinding.supplied,
  extra: bmltOverrides(
    dio: Dio()..httpClientAdapter = bmlt ?? BmltServerMimic(),
    endpoints: testBmltEndpoints,
  ),
);

Future<AppHarness> pumpApp({
  required WidgetTester tester,
  TestContainer? container,
  BmltServerMimic? bmlt,
  String initialLocation = '/home',
}) async {
  tester.view.physicalSize = const Size(600, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final harness = container ?? realJftContainer(bmlt: bmlt);
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
  await settle(tester);
  return AppHarness(container: harness, systemPops: systemPops);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump();
  await tester.pumpAndSettle();
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

Finder inPopover(Finder matching) => find.descendant(
  of: find.byKey(const Key('formats-popover')),
  matching: matching,
);

Finder inCard(int id, Finder matching) => find.descendant(
  of: find.byKey(Key('meeting-card-$id')),
  matching: matching,
);

Future<void> openMunicipality(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(Key('municipality-row-$name')));
  await tester.pumpAndSettle();
}

Future<void> toggleDay(WidgetTester tester, String weekday) async {
  await tester.tap(find.byKey(Key('meeting-section-$weekday')));
  await tester.pumpAndSettle();
}

enum NudgeDirection { up, down }

Future<void> nudgeThumb({
  required WidgetTester tester,
  required String label,
  required NudgeDirection direction,
  required int times,
}) async {
  final handle = tester.ensureSemantics();
  for (final _ in List.filled(times, 0)) {
    switch (direction) {
      case NudgeDirection.up:
        tester.semantics.increase(find.semantics.byLabel(label));
      case NudgeDirection.down:
        tester.semantics.decrease(find.semantics.byLabel(label));
    }
    await tester.pump();
  }
  handle.dispose();
}
