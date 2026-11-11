import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' show fail, find;
import 'package:na_app/app/na_danmark_app.dart';
import 'package:na_app/app/na_router.dart';
import 'package:na_app/composition/app_startup.dart';
import 'package:na_app/composition/production_overrides.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' show PatrolTester;

const underPatrolRunner = bool.hasEnvironment('PATROL_APP_PACKAGE_NAME');
const speaksName =
    'speaks: search, play a speak, see its length, scrub it, pause it from '
    'its row and close the player';
const SpeakSlug sigi = SpeakSlug('kokna-30-hovedspeak-sigi');
const String playableSpeak =
    'https://www.nadanmark.dk/wp-content/uploads/2021/05/'
    '01.-Vores-Symbol-Forord-Til-Sjette-Udgave.mp3';

List<SpeakGroupDto> withPlayableSigi(List<SpeakGroupDto> groups) => [
  for (final group in groups)
    SpeakGroupDto(
      title: group.title,
      speaks: [
        for (final speak in group.speaks ?? const <SpeakEntryDto>[])
          speak.audioUrl == sigi.url.value && speak.name == 'Hovedspeak Sigi'
              ? SpeakEntryDto(
                  name: speak.name,
                  location: speak.location,
                  year: speak.year,
                  audioUrl: playableSpeak,
                )
              : speak,
      ],
    ),
];

Duration clockTime(String text) => text
    .split(':')
    .map(int.parse)
    .fold(Duration.zero, (sum, part) => sum * 60 + Duration(seconds: part));

Future<String> waitForLength(PatrolIntegrationTester $) async {
  for (var attempt = 0; attempt < 40; attempt += 1) {
    await $.pump(const Duration(milliseconds: 500));
    final text = $(const Key('na-scrubber-length')).text ?? '--:--';
    if (text != '--:--') {
      return text;
    }
  }
  return fail('the audio engine never reported the speak length');
}

Future<void> startApp(PatrolTester $) async {
  final started = await $.tester.runAsync(() async {
    final built = ProviderContainer(
      overrides: [
        ...await platformOverrides(),
        ...networkOverrides(
          bmlt: Dio()..httpClientAdapter = BmltServerMimic(),
          wordpress: Dio()
            ..httpClientAdapter = (WordPressMimic()
              ..serve(
                language: SpeakLanguage.danish,
                reply: SpeakGroups(
                  groups: withPlayableSigi(sampleDanishSpeaks),
                ),
              )),
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

Future<void> speaks(PatrolIntegrationTester $) async {
  const row = Key('speak-row-$playableSpeak');
  await startApp($);
  await $(const Key('menu-button')).tap();
  await $(const Key('menu-speaks')).tap();
  await $(row).waitUntilVisible();
  await $(EditableText).enterText('sigi');
  await $.pump(const Duration(milliseconds: 300));
  await $.pumpAndSettle();
  await $(const Key('speak-count')).waitUntilVisible();
  await $(row).tap(settlePolicy: SettlePolicy.noSettle);
  if (await $.native.isPermissionDialogVisible(
    timeout: const Duration(seconds: 10),
  )) {
    await $.native.grantPermissionWhenInUse();
  }
  await $(const Key('docked-player')).waitUntilVisible();
  final length = clockTime(await waitForLength($));
  await $.tester.tapAt(
    $.tester.getCenter(find.byKey(const Key('na-scrubber-track'))),
  );
  await $.pump(const Duration(seconds: 2));
  final position = clockTime(
    $(const Key('na-scrubber-position')).text ?? '0:00',
  );
  if (position < length ~/ 2 - const Duration(seconds: 5)) {
    fail('scrubbing to the middle left the speak at $position of $length');
  }
  await $(row).tap(settlePolicy: SettlePolicy.noSettle);
  await $(const Key('speak-icon-play')).waitUntilVisible();
  await $(const Key('player-close')).tap(settlePolicy: SettlePolicy.noSettle);
  await $.pumpAndSettle();
  if ($(const Key('docked-player')).exists) {
    fail('the docked player is still shown after closing it');
  }
}

void main() {
  if (underPatrolRunner) {
    patrolTest(speaksName, speaks);
  }
}
