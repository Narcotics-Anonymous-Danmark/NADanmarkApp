import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

import 'pump_app.dart';

const Map<String, String> inEnglish = {'language': 'en'};

String municipalityPath(String name) =>
    '/listfull/${Uri.encodeComponent(name)}';

BmltServerMimic bmltServing({
  List<Map<String, String>> meetings = const [],
  List<String> municipalities = const [],
}) => BmltServerMimic()
  ..serve(
    endpoint: BmltEndpoint.meetings,
    reply: BmltRows(rows: meetings),
  )
  ..serve(
    endpoint: BmltEndpoint.municipalities,
    reply: BmltRows(
      rows: List.unmodifiable(
        municipalities.map(
          (name) => aBmltMunicipalityJson(municipality: name),
        ),
      ),
    ),
  );

Future<AppHarness> pumpMeetings({
  required WidgetTester tester,
  required BmltServerMimic bmlt,
  String location = '/listfull',
  Map<String, String> storedValues = inEnglish,
  TestTime? time,
  LegacyStoreRead legacyStore = const LegacyStoreAbsent(),
}) => pumpApp(
  tester: tester,
  initialLocation: location,
  container: realJftContainer(
    storedValues: storedValues,
    bmlt: bmlt,
    time: time,
    legacyStore: legacyStore,
  ),
);

String formatsCache({
  required Instant fetchedAt,
  List<Map<String, String>> rows = const [],
}) => const FormatRowsCodec().encodeSnapshot(
  snapshot: FormatsSnapshot(
    fetchedAt: fetchedAt,
    rows: formatRowsFrom(json: rows.isEmpty ? recordedFormatRowsJson() : rows),
  ),
);

Finder sectionHeader(String weekday) =>
    find.byKey(Key('meeting-section-$weekday'));

Finder card(int id) => find.byKey(Key('meeting-card-$id'));

const Color darkChipColour = Color(0xFF222428);

List<String> textsIn(WidgetTester tester, Finder scope) => tester
    .widgetList<Text>(find.descendant(of: scope, matching: find.byType(Text)))
    .map((text) => text.data ?? '')
    .toList();

String sectionLabel(WidgetTester tester, String weekday) =>
    textsIn(tester, sectionHeader(weekday)).first;

Color sectionColour(WidgetTester tester, String weekday) {
  final text = tester.widget<Text>(
    find.descendant(of: sectionHeader(weekday), matching: find.byType(Text)),
  );
  return text.style?.color ?? const Color(0x00000000);
}

List<String> chipLabels(WidgetTester tester, int id) =>
    textsIn(tester, find.byKey(Key('meeting-formats-$id')));

Color chipColour(WidgetTester tester, String key) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byKey(Key('format-chip-$key')),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color ?? const Color(0x00000000);
}

Future<void> openFormats(WidgetTester tester, int id) async {
  await tester.tap(find.byKey(Key('meeting-formats-$id')));
  await tester.pumpAndSettle();
}
