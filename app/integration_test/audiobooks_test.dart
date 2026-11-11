import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' show fail;
import 'package:na_app/app/na_danmark_app.dart';
import 'package:na_app/app/na_router.dart';
import 'package:na_app/composition/app_startup.dart';
import 'package:na_app/composition/production_overrides.dart';
import 'package:na_testing/na_testing.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' show PatrolTester;

const underPatrolRunner = bool.hasEnvironment('PATROL_APP_PACKAGE_NAME');
const audiobooksName =
    'audiobooks: play a chapter of Basic Text, close it, pick a group reading';

Future<void> startApp(PatrolTester $) async {
  final started = await $.tester.runAsync(() async {
    final built = ProviderContainer(
      overrides: [
        ...await platformOverrides(),
        ...networkOverrides(
          bmlt: Dio()..httpClientAdapter = BmltServerMimic(),
          wordpress: Dio()..httpClientAdapter = WordPressMimic(),
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

Future<void> audiobooks(PatrolIntegrationTester $) async {
  await startApp($);
  await $(const Key('menu-button')).tap();
  await $(const Key('menu-audiobooks')).tap();
  await $(const Key('audiobook-row-basic-text')).tap();
  await $(const Key('book-chapter-0')).tap(
    settlePolicy: SettlePolicy.noSettle,
  );
  if (await $.native.isPermissionDialogVisible(
    timeout: const Duration(seconds: 10),
  )) {
    await $.native.grantPermissionWhenInUse();
  }
  await $(const Key('docked-player')).waitUntilVisible();
  await $(const Key('book-continue-header')).waitUntilVisible();
  await $(const Key('player-close')).tap(settlePolicy: SettlePolicy.noSettle);
  await $.pumpAndSettle();
  await $(const Key('back-button')).tap();
  await $(const Key('audiobook-row-basic-text')).waitUntilVisible();
  await $(const Key('menu-button')).tap();
  await $(const Key('menu-groupReadings')).tap();
  await $(const Key('readings-select')).tap();
  await $('Vi kommer i bedring').tap();
  await $(const Key('reading-heading')).waitUntilVisible();
  if ($(const Key('reading-heading')).text != 'Vi kommer i bedring') {
    fail('the selected reading is not shown');
  }
}

void main() {
  if (underPatrolRunner) {
    patrolTest(audiobooksName, audiobooks);
  }
}
