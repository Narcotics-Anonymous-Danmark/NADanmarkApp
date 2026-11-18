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
const eventsName =
    'events: home shows the event cards, a card opens the events page, a row '
    'opens the event in the in-app browser and back returns to the list';
const EventSlug kokna = EventSlug('kokna-31');

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

Future<void> events(PatrolIntegrationTester $) async {
  await startApp($);
  await $(const Key('home-event-card-0')).scrollTo();
  await $(const Key('home-event-card-0')).tap();
  final row = $(Key('event-row-${kokna.page}'));
  await row.waitUntilVisible();
  await row.tap(settlePolicy: SettlePolicy.noSettle);
  await $.pump(const Duration(seconds: 3));
  await $.native.pressBack();
  await $.pumpAndSettle();
  await row.waitUntilVisible();
  if (!$(const Key('events-list')).exists) {
    fail('the events list is not shown after returning from the browser');
  }
}

void main() {
  if (underPatrolRunner) {
    patrolTest(eventsName, events);
  }
}
