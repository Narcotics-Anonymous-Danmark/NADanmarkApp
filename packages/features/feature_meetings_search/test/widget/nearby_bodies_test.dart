@Tags(['widget'])
library;

import 'package:feature_meetings_search/feature_meetings_search.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

final GeoPoint aarhus = aGeoPoint(
  latitude: const Latitude(56.15),
  longitude: const Longitude(10.2),
);

TestContainer nearbyHarness({
  Outcome<List<Meeting>, Failure> nearby = const Ok(value: []),
  FixDelivery delivery = const FixAtOnce(fix: NoFix()),
}) {
  final harness = TestContainer.build();
  addTearDown(harness.dispose);
  harness.geolocation.delivery = delivery;
  harness.meetingSearch.nearby = nearby;
  return harness;
}

FixDelivery locatedAt(GeoPoint point) => FixAtOnce(fix: Located(point: point));

Future<void> pumpNearbyPage(WidgetTester tester, TestContainer harness) =>
    pumpFeature(
      tester: tester,
      harness: harness,
      child: goldenFrame(
        child: SizedBox(
          height: 560,
          child: ColoredBox(
            color: NaColors.light.background,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: NearbyBody(firstDay: FirstDayOfWeek.monday)),
                NearbyFooter(),
              ],
            ),
          ),
        ),
      ),
    );

const offline = Err<List<Meeting>, Failure>(
  error: NetworkFailure(detail: 'offline'),
);

void main() {
  setUpAll(loadNaFonts);

  group('NearbyBody', () {
    testWidgets('shows the meetings around a real position without a note', (
      tester,
    ) async {
      await pumpNearbyPage(
        tester,
        nearbyHarness(
          nearby: Ok(value: [aMeeting(id: 1, weekday: Weekday.monday)]),
          delivery: locatedAt(aarhus),
        ),
      );
      expect(find.byKey(const Key('meeting-section-monday')), findsOneWidget);
      expect(find.byKey(const Key('nearby-location-not-set')), findsNothing);
      await expectGolden(finder: goldenTarget, name: 'nearby_loaded');
      await expectAccessible(tester);
    });

    testWidgets('discloses the default coordinates', (tester) async {
      await pumpNearbyPage(
        tester,
        nearbyHarness(
          nearby: Ok(value: [aMeeting(id: 1, weekday: Weekday.monday)]),
        ),
      );
      expect(find.byKey(const Key('nearby-location-not-set')), findsOneWidget);
      expect(find.text('Placeringen er ikke indstillet'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Placeringen er ikke indstillet'),
          matching: find.byType(NaErrorState),
        ),
        findsOneWidget,
      );
      await expectGolden(finder: goldenTarget, name: 'nearby_default_position');
      await expectAccessible(tester);
    });

    testWidgets('says nothing found for an empty answer', (tester) async {
      await pumpNearbyPage(
        tester,
        nearbyHarness(delivery: locatedAt(aarhus)),
      );
      expect(find.byKey(const Key('meetings-nothing-found')), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'nearby_empty');
      await expectAccessible(tester);
    });

    testWidgets('shows nothing while waiting for the first result', (
      tester,
    ) async {
      final harness = nearbyHarness(delivery: locatedAt(aarhus));
      final gate = harness.meetingSearch.holdNearby();
      await pumpNearbyPage(tester, harness);
      expect(find.byKey(const Key('meetings-nothing-found')), findsNothing);
      expect(find.byKey(const Key('meetings-retry')), findsNothing);
      await expectGolden(finder: goldenTarget, name: 'nearby_waiting');
      gate.open();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('meetings-nothing-found')), findsOneWidget);
    });

    testWidgets('a failure offers a retry that recovers', (tester) async {
      final harness = nearbyHarness(
        nearby: offline,
        delivery: locatedAt(aarhus),
      );
      await pumpNearbyPage(tester, harness);
      expect(find.byKey(const Key('meetings-retry')), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'nearby_error');
      await expectAccessible(tester);
      harness.meetingSearch.nearby = Ok(
        value: [aMeeting(id: 1, weekday: Weekday.monday)],
      );
      await tester.tap(find.byKey(const Key('meetings-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('meeting-section-monday')), findsOneWidget);
    });
  });

  group('NearbyFooter', () {
    testWidgets('the button locates again', (tester) async {
      final harness = nearbyHarness(delivery: locatedAt(aarhus));
      await pumpNearbyPage(tester, harness);
      expect(find.text('MØDER I NÆRHEDEN'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nearby-locate')));
      await tester.pumpAndSettle();
      expect(harness.geolocation.positionCalls, const CallCount(2));
      expect(harness.meetingSearch.nearbyQueries, hasLength(2));
    });

    testWidgets('the slider shows the radius and changes it', (tester) async {
      final harness = nearbyHarness(delivery: locatedAt(aarhus));
      await pumpNearbyPage(tester, harness);
      final slider = find.byKey(const Key('nearby-radius-slider'));
      expect(tester.widget<NaSlider>(slider).value, 15);
      expect(tester.widget<NaSlider>(slider).label, 'Søgeradius');
      expect(find.text('Søgeradius: 15 km'), findsOneWidget);
      expect(find.text('5 km'), findsOneWidget);
      expect(find.text('50 km'), findsOneWidget);
      final rect = tester.getRect(slider);
      await tester.tapAt(Offset(rect.right - 13, rect.center.dy));
      await tester.pump();
      expect(tester.widget<NaSlider>(slider).value, 50);
      expect(find.text('Søgeradius: 50 km'), findsOneWidget);
      expect(harness.read(nearbyMeetingsProvider).radius, const Km(50));
      harness.time.advance(by: NearbyMeetingsController.sliderDebounce);
      await tester.pumpAndSettle();
      expect(
        harness.meetingSearch.nearbyQueries.last,
        NearbyQuery(centre: aarhus, radius: const Km(50)),
      );
    });
  });
}
