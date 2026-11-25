import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' show fail;
import 'package:na_app/app/na_danmark_app.dart';
import 'package:na_app/app/na_router.dart';
import 'package:na_app/composition/app_config.dart';
import 'package:na_app/composition/app_startup.dart';
import 'package:na_app/composition/production_overrides.dart';
import 'package:na_testing/na_testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' show PatrolTester;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const underPatrolRunner = bool.hasEnvironment('PATROL_APP_PACKAGE_NAME');
const mapName = 'map search: the map opens and the first search finishes';

Future<void> startApp(PatrolTester $) async {
  final started = await $.tester.runAsync(() async {
    final built = ProviderContainer(
      overrides: [
        ...await platformOverrides(),
        ...networkOverrides(
          bmlt: Dio()..httpClientAdapter = BmltServerMimic(),
          wordpress: Dio()..httpClientAdapter = WordPressMimic(),
        ),
        ...mapsOverrides(
          maps: AppConfig.fromEnvironment().maps,
          dio: Dio()..httpClientAdapter = PlacesServerMimic(),
          bundle: rootBundle,
        ),
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
}

Future<void> waitForFirstSearch(PatrolTester $) async {
  for (final _ in List.filled(120, 0)) {
    if (!$(const Key('global-loading-bar')).exists) {
      return;
    }
    await $.pump(const Duration(milliseconds: 500));
  }
  fail('the first map search did not finish within a minute');
}

Future<void> mapSearch(PatrolTester $) async {
  await startApp($);
  await $(const Key('menu-button')).tap();
  await $(const Key('menu-map')).tap();
  switch (AppConfig.fromEnvironment().maps) {
    case MapsConfigured():
      await $(
        const Key('google-map'),
      ).waitUntilExists(timeout: const Duration(seconds: 30));
      await $(const Key('map-place-search')).waitUntilVisible();
      await waitForFirstSearch($);
    case MapsNotConfigured():
      await $(const Key('map-unavailable')).waitUntilVisible();
  }
}

void main() {
  if (underPatrolRunner) {
    patrolTest(mapName, mapSearch);
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
    patrolWidgetTest(mapName, mapSearch);
  }
}
