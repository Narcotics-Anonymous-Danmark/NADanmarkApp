import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' show fail;
import 'package:na_app/app/na_danmark_app.dart';
import 'package:na_app/app/na_router.dart';
import 'package:na_app/composition/app_startup.dart';
import 'package:na_app/composition/production_overrides.dart';
import 'package:na_design/na_design.dart';
import 'package:na_testing/na_testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' show PatrolTester;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const underPatrolRunner = bool.hasEnvironment('PATROL_APP_PACKAGE_NAME');
const happyPathName =
    'meetings: open a municipality, expand a day and read the formats';

Future<void> happyPath(PatrolTester $) async {
  final started = await $.tester.runAsync(() async {
    final built = ProviderContainer(
      overrides: [
        ...await platformOverrides(),
        ...networkOverrides(dio: Dio()..httpClientAdapter = BmltServerMimic()),
      ],
    );
    await AppStartup(container: built).run();
    return built;
  });
  final container = switch (started) {
    final ProviderContainer ready => ready,
    null => fail('the app did not start'),
  };
  await $.pumpWidgetAndSettle(
    UncontrolledProviderScope(
      container: container,
      child: NaDanmarkApp(router: createRouter(initialLocation: homePath)),
    ),
  );
  await $(const Key('menu-button')).tap();
  await $(const Key('menu-meetings')).tap();
  await $(
    const Key('municipality-row-Varde'),
  ).scrollTo(view: $(NaPageFrame).$(Scrollable)).tap();
  await $(const Key('meeting-section-sunday')).tap();
  await $(const Key('meeting-card-115')).waitUntilVisible();
  await $(const Key('meeting-formats-115')).tap();
  await $(const Key('formats-popover')).waitUntilVisible();
  await $(const Key('formats-popover-close')).tap();
  await $(const Key('back-button')).tap();
  await $(const Key('municipality-row-Varde')).waitUntilExists();
}

void main() {
  if (underPatrolRunner) {
    patrolTest(happyPathName, happyPath);
  } else {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    PackageInfo.setMockInitialValues(
      appName: 'NA Danmark',
      packageName: 'dk.nadanmark.app',
      version: '2.0.0',
      buildNumber: '1120000001',
      buildSignature: '',
    );
    patrolWidgetTest(happyPathName, happyPath);
  }
}
