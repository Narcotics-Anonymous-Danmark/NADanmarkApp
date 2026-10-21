import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

import 'meetings.dart';
import 'pump_app.dart';

const RoutePath cleantimePath = RoutePath('/cleantime-counter');
const RoutePath homePath = RoutePath('/home');
const RoutePath settingsPath = RoutePath('/settings');

extension type const CardGroup(int number) {}

extension type const WheelSteps(int count) {}
const profileSelector = Key('cleantime-profile-selector');
const addProfile = Key('cleantime-add-profile');
const renameProfile = Key('cleantime-rename-profile');
const deleteProfile = Key('cleantime-delete-profile');
const dateField = Key('cleantime-date-field');
const cleandayCard = Key('cleantime-cleanday');
const homeCarousel = Key('home-cleantime-carousel');

const Map<String, String> inDanish = {'language': 'da'};

const ProfileName bo = ProfileName('Bo');
const ProfileName carl = ProfileName('Carl');

TestTime todayIs(LocalDate date) => TestTime.copenhagen(
  startAt: Instant(DateTime.utc(date.year, date.month, date.day, 12)),
);

LocalDate daysBefore({required LocalDate today, required DayCount days}) =>
    today.plusDays(days: -days.value);

Map<String, String> storedProfiles({
  required List<CleantimeProfile> entries,
  ProfileIndex active = const ProfileIndex(0),
}) => aStoredCleantimeProfiles(entries: entries, active: active);

Future<AppHarness> pumpCleantime({
  required WidgetTester tester,
  Map<String, String> storedValues = const {},
  Map<String, String> language = inEnglish,
  LocalDate today = const LocalDate(year: 2026, month: 9, day: 10),
  RoutePath location = cleantimePath,
  NotificationPermission permission = NotificationPermission.granted,
  NotificationPrompt prompt = NotificationPrompt.grant,
  ScheduleBehaviour behaviour = ScheduleBehaviour.accept,
  LegacyStoreRead legacyStore = const LegacyStoreAbsent(),
}) {
  final container = realJftContainer(
    storedValues: {...language, ...storedValues},
    time: todayIs(today),
    legacyStore: legacyStore,
  );
  container.notifications
    ..permission = permission
    ..prompt = prompt
    ..behaviour = behaviour;
  return pumpApp(
    tester: tester,
    container: container,
    initialLocation: location.value,
  );
}

List<CleantimeProfile> savedProfiles(AppHarness app) =>
    switch (const CleantimeProfilesCodec().decodeProfiles(
      text: app.storage.snapshot[SettingKeys.cleantimeProfiles.name] ?? '',
    )) {
      Ok(:final value) => value,
      Err() => const [],
    };

String savedActive(AppHarness app) =>
    app.storage.snapshot[SettingKeys.activeCleantimeProfile.name] ?? '';

String selectedProfileName(WidgetTester tester) =>
    tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(profileSelector),
            matching: find.byType(Text),
          ),
        )
        .data ??
    '';

List<String> groupValues(WidgetTester tester, CardGroup group) =>
    List.unmodifiable(
      tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(Key('cleantime-group-${group.number}')),
              matching: find.byKey(const Key('cleantime-value')),
            ),
          )
          .map((text) => text.data ?? ''),
    );

List<String> groupTitles(WidgetTester tester, CardGroup group) =>
    List.unmodifiable(
      tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(Key('cleantime-group-${group.number}')),
              matching: find.byKey(const Key('cleantime-unit-title')),
            ),
          )
          .map((text) => text.data ?? ''),
    );

String keyTagAsset(WidgetTester tester) {
  final image = tester.widget<Image>(
    find.descendant(of: find.byKey(cleandayCard), matching: find.byType(Image)),
  );
  return switch (image.image) {
    final AssetImage asset => asset.keyName,
    ImageProvider() => '',
  };
}

Future<void> enterProfileName(WidgetTester tester, ProfileName name) async {
  await tester.enterText(find.byType(EditableText), name.text);
  await tester.pump();
}

Future<void> pickProfile(WidgetTester tester, ProfileName name) async {
  await tester.tap(find.text(name.text).last);
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> confirmDialog(WidgetTester tester) =>
    tapKey(tester, const Key('na-dialog-confirm'));

Future<void> cancelDialog(WidgetTester tester) =>
    tapKey(tester, const Key('na-dialog-cancel'));

Future<void> addNamedProfile(WidgetTester tester, ProfileName name) async {
  await tapKey(tester, addProfile);
  await enterProfileName(tester, name);
  await confirmDialog(tester);
}

enum DateWheel { day, month, year }

Future<void> turnWheel({
  required WidgetTester tester,
  required DateWheel wheel,
  required WheelSteps steps,
}) async {
  await tester.drag(
    find.byKey(Key('na-date-wheel-${wheel.name}')),
    Offset(0, -NaDatePicker.itemExtent * steps.count),
  );
  await tester.pumpAndSettle();
}

Future<void> pickDate({
  required WidgetTester tester,
  required LocalDate from,
  required LocalDate to,
}) async {
  await tapKey(tester, dateField);
  await turnWheel(
    tester: tester,
    wheel: DateWheel.year,
    steps: WheelSteps(to.year - from.year),
  );
  await turnWheel(
    tester: tester,
    wheel: DateWheel.month,
    steps: WheelSteps(to.month - from.month),
  );
  await turnWheel(
    tester: tester,
    wheel: DateWheel.day,
    steps: WheelSteps(to.day - from.day),
  );
  await confirmDialog(tester);
}

Instant tenOClock(LocalDate date) =>
    Instant(DateTime.utc(date.year, date.month, date.day, 8));
