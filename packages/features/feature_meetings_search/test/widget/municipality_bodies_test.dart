@Tags(['widget'])
library;

import 'package:feature_meetings_search/feature_meetings_search.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

const varde = NamedMunicipality(name: MunicipalityName('Varde'));

TestContainer harnessWith({
  Outcome<List<MunicipalityName>, Failure> municipalities = const Ok(
    value: [
      MunicipalityName('Aarhus'),
      MunicipalityName('Varde'),
      MunicipalityName(''),
    ],
  ),
  Outcome<List<Meeting>, Failure>? meetings,
}) {
  final harness = TestContainer.build();
  addTearDown(harness.dispose);
  harness.meetingSearch
    ..municipalities = municipalities
    ..meetings = meetings ?? Ok(value: [aMeeting(id: 1)]);
  return harness;
}

Future<void> pumpBody(
  WidgetTester tester,
  TestContainer harness,
  Widget body,
) => pumpFeature(
  tester: tester,
  harness: harness,
  child: goldenFrame(
    child: SizedBox(
      height: 480,
      child: ColoredBox(color: NaColors.light.background, child: body),
    ),
  ),
);

const offline = Err<List<Meeting>, Failure>(
  error: NetworkFailure(detail: 'offline'),
);

void main() {
  setUpAll(loadNaFonts);

  group('MunicipalityListBody', () {
    testWidgets('lists the municipalities and opens one', (tester) async {
      final opened = <MunicipalitySegment>[];
      await pumpBody(
        tester,
        harnessWith(),
        MunicipalityListBody(onOpen: opened.add),
      );
      expect(find.byKey(const Key('municipality-row-Online')), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'municipalities_loaded');
      await expectAccessible(tester);
      await tester.tap(find.byKey(const Key('municipality-row-Varde')));
      expect(opened, [const MunicipalitySegment('Varde')]);
    });

    testWidgets('shows nothing while loading', (tester) async {
      final harness = harnessWith();
      final gate = harness.meetingSearch.holdMunicipalities();
      await pumpBody(tester, harness, MunicipalityListBody(onOpen: (_) {}));
      expect(find.byType(NaDisclosureRow), findsNothing);
      await expectGolden(finder: goldenTarget, name: 'municipalities_loading');
      gate.open();
      await tester.pumpAndSettle();
    });

    testWidgets('an empty list says nothing found', (tester) async {
      await pumpBody(
        tester,
        harnessWith(municipalities: const Ok(value: [])),
        MunicipalityListBody(onOpen: (_) {}),
      );
      expect(find.text('Intet fundet'), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'municipalities_empty');
      await expectAccessible(tester);
    });

    testWidgets('a failure offers a retry that recovers', (tester) async {
      final harness = harnessWith(
        municipalities: const Err(error: NetworkFailure(detail: 'offline')),
      );
      await pumpBody(tester, harness, MunicipalityListBody(onOpen: (_) {}));
      expect(find.text('Møderne kunne ikke hentes'), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'municipalities_error');
      await expectAccessible(tester);
      harness.meetingSearch.municipalities = const Ok(
        value: [MunicipalityName('Aarhus')],
      );
      await tester.tap(find.byKey(const Key('meetings-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('municipality-row-Aarhus')), findsOneWidget);
    });
  });

  group('MunicipalityMeetingsBody', () {
    testWidgets('lists the meetings of the municipality', (tester) async {
      await pumpBody(
        tester,
        harnessWith(),
        const MunicipalityMeetingsBody(
          municipality: varde,
          firstDay: FirstDayOfWeek.monday,
        ),
      );
      expect(find.text('Søndag (1)'), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'meetings_loaded');
      await expectAccessible(tester);
    });

    testWidgets('meetings elsewhere only is nothing found', (tester) async {
      await pumpBody(
        tester,
        harnessWith(
          meetings: Ok(value: [aMeeting(municipality: 'Aarhus')]),
        ),
        const MunicipalityMeetingsBody(
          municipality: varde,
          firstDay: FirstDayOfWeek.monday,
        ),
      );
      expect(find.text('Intet fundet'), findsOneWidget);
    });

    testWidgets('a failure offers a retry that recovers', (tester) async {
      final harness = harnessWith(meetings: offline);
      await pumpBody(
        tester,
        harness,
        const MunicipalityMeetingsBody(
          municipality: varde,
          firstDay: FirstDayOfWeek.monday,
        ),
      );
      expect(find.text('Møderne kunne ikke hentes'), findsOneWidget);
      harness.meetingSearch.meetings = Ok(value: [aMeeting(id: 1)]);
      await tester.tap(find.byKey(const Key('meetings-retry')));
      await tester.pumpAndSettle();
      expect(find.text('Søndag (1)'), findsOneWidget);
    });

    testWidgets('shows nothing while loading', (tester) async {
      final harness = harnessWith();
      final gate = harness.meetingSearch.holdMeetings();
      await pumpBody(
        tester,
        harness,
        const MunicipalityMeetingsBody(
          municipality: varde,
          firstDay: FirstDayOfWeek.monday,
        ),
      );
      expect(find.byType(NaSectionHeader), findsNothing);
      gate.open();
      await tester.pumpAndSettle();
      expect(find.byType(NaSectionHeader), findsOneWidget);
    });
  });

  test('the Online segment maps to the online group and back', () {
    expect(
      const MunicipalitySegment('Online').municipality,
      const OnlineMunicipality(),
    );
    expect(
      MunicipalitySegment.of(municipality: const OnlineMunicipality()),
      const MunicipalitySegment('Online'),
    );
    expect(const MunicipalitySegment('Varde').municipality, varde);
  });
}
