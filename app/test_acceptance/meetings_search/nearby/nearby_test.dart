@Tags(['acceptance'])
library;

import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../../support/meetings.dart';
import '../../support/nearby.dart';
import '../../support/pump_app.dart';

const Duration debounce = Duration(milliseconds: 500);

void main() {
  group('Requirement: BMLT endpoints', () {
    testWidgets('Empty object means no meetings', (tester) async {
      final app = await pumpNearby(tester: tester, bmlt: nearbyServing());
      addTearDown(app.dispose);
      expect(pageText('Nothing found'), findsOneWidget);
      expect(pageText('The meetings could not be loaded'), findsNothing);
    });

    testWidgets('Radius query carries the exact parameters', (tester) async {
      final bmlt = nearbyServing(reply: mondayMeeting());
      final app = await pumpNearby(tester: tester, bmlt: bmlt);
      addTearDown(app.dispose);
      const expected =
          '$tomato?switcher=GetSearchResults&geo_width_km=15'
          '&long_val=8.4606976&lat_val=55.476224'
          '&sort_keys=longitude,latitude&callingApp=bmlt_search_3_ionic';
      expect(nearbyRequests(bmlt), [Uri.parse(expected)]);
    });
  });

  group('Requirement: Meetings nearby', () {
    testWidgets('Search uses the default radius setting', (tester) async {
      final bmlt = nearbyServing(reply: mondayMeeting());
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        storedValues: {...inEnglish, 'searchRange': '20'},
        delivery: locatedAt(aarhus),
      );
      addTearDown(app.dispose);
      expect(nearbyRequests(bmlt), [
        nearbyUri(at: aarhus, radius: const Km(20)),
      ]);
      expect(sliderValue(tester), const Km(20));
    });

    testWidgets('Slider re-searches without relocating', (tester) async {
      final bmlt = nearbyServing(reply: mondayMeeting());
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        delivery: locatedAt(aarhus),
      );
      addTearDown(app.dispose);
      final positionsBefore = app.geolocation.positionCalls;
      await moveNearbySlider(tester: tester, to: const Km(30));
      await advance(
        tester: tester,
        app: app,
        by: debounce - const Duration(milliseconds: 1),
      );
      expect(nearbyRequests(bmlt), hasLength(1));
      await advance(
        tester: tester,
        app: app,
        by: const Duration(milliseconds: 1),
      );
      expect(nearbyRequests(bmlt), [
        nearbyUri(at: aarhus, radius: const Km(15)),
        nearbyUri(at: aarhus, radius: const Km(30)),
      ]);
      expect(app.geolocation.positionCalls, positionsBefore);
    });

    testWidgets('Fallback to default coordinates', (tester) async {
      final bmlt = nearbyServing(reply: mondayMeeting());
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        delivery: const FixAtOnce(fix: NoFix()),
      );
      addTearDown(app.dispose);
      expect(nearbyRequests(bmlt), [
        nearbyUri(at: GeoPoint.searchFallback, radius: const Km(15)),
      ]);
    });

    testWidgets('Slider shows the current radius', (tester) async {
      final app = await pumpNearby(
        tester: tester,
        bmlt: nearbyServing(reply: mondayMeeting()),
        storedValues: {...inEnglish, 'searchRange': '20'},
        delivery: locatedAt(aarhus),
      );
      addTearDown(app.dispose);
      expect(pageText('Search radius: 20 km'), findsOneWidget);
      await moveNearbySlider(tester: tester, to: const Km(35));
      expect(sliderValue(tester), const Km(35));
      expect(pageText('Search radius: 35 km'), findsOneWidget);
    });

    testWidgets('Slider does not change the setting', (tester) async {
      final bmlt = nearbyServing(reply: mondayMeeting());
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        storedValues: {...inEnglish, 'searchRange': '15'},
        delivery: locatedAt(aarhus),
      );
      addTearDown(app.dispose);
      await moveNearbySlider(tester: tester, to: const Km(40));
      await advance(tester: tester, app: app, by: debounce);
      expect(app.storage.snapshot['searchRange'], '15');
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('menu-home')));
      await tester.pumpAndSettle();
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('menu-nearby')));
      await settle(tester);
      expect(sliderValue(tester), const Km(15));
    });

    testWidgets('Older result is discarded', (tester) async {
      final bmlt = nearbyServing()
        ..serveNearby(radius: const Km(15), reply: mondayMeeting())
        ..serveNearby(radius: const Km(30), reply: fridayMeetings());
      final narrow = bmlt.holdNearby(radius: const Km(15));
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        delivery: locatedAt(aarhus),
        settleWith: AppSettle.frames,
      );
      addTearDown(app.dispose);
      await moveNearbySlider(tester: tester, to: const Km(30));
      await advance(tester: tester, app: app, by: debounce);
      expect(sectionLabel(tester, 'friday'), 'Friday (2)');
      narrow.release();
      await settle(tester);
      expect(sectionLabel(tester, 'friday'), 'Friday (2)');
      expect(sectionHeader('monday'), findsNothing);
    });

    testWidgets('Previous results stay while searching again', (tester) async {
      final bmlt = nearbyServing()
        ..serveNearby(radius: const Km(15), reply: mondayMeeting())
        ..serveNearby(radius: const Km(30), reply: fridayMeetings());
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        delivery: locatedAt(aarhus),
      );
      addTearDown(app.dispose);
      expect(sectionLabel(tester, 'monday'), 'Monday (1)');
      final wide = bmlt.holdNearby(radius: const Km(30));
      await moveNearbySlider(tester: tester, to: const Km(30));
      await advance(tester: tester, app: app, by: debounce);
      expect(nearbyRequests(bmlt), hasLength(2));
      expect(sectionLabel(tester, 'monday'), 'Monday (1)');
      wide.release();
      await settle(tester);
      expect(sectionHeader('monday'), findsNothing);
      expect(sectionLabel(tester, 'friday'), 'Friday (2)');
    });
  });

  group('Requirement: Location acquisition and timeouts', () {
    testWidgets('Permission granted times out after 10 seconds', (
      tester,
    ) async {
      final bmlt = nearbyServing(reply: mondayMeeting());
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        delivery: const FixNever(),
        settleWith: AppSettle.frames,
      );
      addTearDown(app.dispose);
      expect(loadingText(tester), 'Locating…');
      await advance(tester: tester, app: app, by: const Duration(seconds: 9));
      expect(nearbyRequests(bmlt), isEmpty);
      await advance(tester: tester, app: app, by: const Duration(seconds: 1));
      await settle(tester);
      expect(nearbyRequests(bmlt), [
        nearbyUri(at: GeoPoint.searchFallback, radius: const Km(15)),
      ]);
      expect(loadingBar(), findsNothing);
    });

    testWidgets('Late position triggers a second search', (tester) async {
      final bmlt = nearbyServing(reply: mondayMeeting());
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        delivery: FixAfter(
          delay: const Duration(seconds: 22),
          fix: Located(point: aarhus),
        ),
        settleWith: AppSettle.frames,
      );
      addTearDown(app.dispose);
      await advance(tester: tester, app: app, by: const Duration(seconds: 10));
      await settle(tester);
      expect(sectionLabel(tester, 'monday'), 'Monday (1)');
      bmlt.serve(endpoint: BmltEndpoint.nearby, reply: fridayMeetings());
      await advance(tester: tester, app: app, by: const Duration(seconds: 12));
      await settle(tester);
      expect(nearbyRequests(bmlt), [
        nearbyUri(at: GeoPoint.searchFallback, radius: const Km(15)),
        nearbyUri(at: aarhus, radius: const Km(15)),
      ]);
      expect(sectionHeader('monday'), findsNothing);
      expect(sectionLabel(tester, 'friday'), 'Friday (2)');
    });

    testWidgets('Without permission the timeout is 45 seconds', (
      tester,
    ) async {
      final bmlt = nearbyServing(reply: mondayMeeting());
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        access: LocationAccess.askable,
        answer: PromptAnswer.ignore,
        delivery: const FixNever(),
        settleWith: AppSettle.frames,
      );
      addTearDown(app.dispose);
      expect(app.geolocation.requestCalls, const CallCount(1));
      await advance(tester: tester, app: app, by: const Duration(seconds: 44));
      expect(nearbyRequests(bmlt), isEmpty);
      await advance(tester: tester, app: app, by: const Duration(seconds: 1));
      await settle(tester);
      expect(nearbyRequests(bmlt), [
        nearbyUri(at: GeoPoint.searchFallback, radius: const Km(15)),
      ]);
    });

    testWidgets('Refused permission searches at once', (tester) async {
      final bmlt = nearbyServing(reply: mondayMeeting());
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        access: LocationAccess.askable,
        answer: PromptAnswer.refuse,
        delivery: const FixNever(),
      );
      addTearDown(app.dispose);
      expect(nearbyRequests(bmlt), [
        nearbyUri(at: GeoPoint.searchFallback, radius: const Km(15)),
      ]);
      expect(loadingBar(), findsNothing);
      expect(app.geolocation.positionCalls, const CallCount(0));
    });

    testWidgets('Location services off searches at once', (tester) async {
      final bmlt = nearbyServing(reply: mondayMeeting());
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        delivery: const FixAtOnce(fix: ServicesOff()),
      );
      addTearDown(app.dispose);
      expect(nearbyRequests(bmlt), [
        nearbyUri(at: GeoPoint.searchFallback, radius: const Km(15)),
      ]);
      expect(loadingBar(), findsNothing);
    });

    testWidgets('Relocating keeps the last real position', (tester) async {
      final bmlt = nearbyServing(reply: mondayMeeting());
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        delivery: locatedAt(aarhus),
      );
      addTearDown(app.dispose);
      app.geolocation.delivery = const FixNever();
      await tester.tap(find.byKey(locateButton));
      await pumpFrames(tester);
      await advance(tester: tester, app: app, by: const Duration(seconds: 10));
      await settle(tester);
      expect(nearbyRequests(bmlt), [
        nearbyUri(at: aarhus, radius: const Km(15)),
        nearbyUri(at: aarhus, radius: const Km(15)),
      ]);
      expect(find.byKey(locationNotSetNote), findsNothing);
    });
  });

  group('Requirement: Nearby results states', () {
    testWidgets('No meetings in range', (tester) async {
      final app = await pumpNearby(
        tester: tester,
        bmlt: nearbyServing(),
        delivery: locatedAt(aarhus),
      );
      addTearDown(app.dispose);
      expect(pageText('Nothing found'), findsOneWidget);
      expect(loadingBar(), findsNothing);
    });

    testWidgets('Failed nearby search can be retried', (tester) async {
      final bmlt = nearbyServing(reply: const BmltUnreachable());
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        storedValues: {...inEnglish, 'searchRange': '25'},
        delivery: locatedAt(aarhus),
      );
      addTearDown(app.dispose);
      expect(pageText('The meetings could not be loaded'), findsOneWidget);
      expect(loadingBar(), findsNothing);
      bmlt.serve(endpoint: BmltEndpoint.nearby, reply: mondayMeeting());
      await tester.tap(find.byKey(const Key('meetings-retry')));
      await settle(tester);
      expect(nearbyRequests(bmlt), [
        nearbyUri(at: aarhus, radius: const Km(25)),
        nearbyUri(at: aarhus, radius: const Km(25)),
      ]);
      expect(pageText('The meetings could not be loaded'), findsNothing);
      expect(sectionLabel(tester, 'monday'), 'Monday (1)');
    });

    testWidgets('Default coordinates are disclosed', (tester) async {
      final app = await pumpNearby(
        tester: tester,
        bmlt: nearbyServing(reply: mondayMeeting()),
        delivery: const FixAtOnce(fix: NoFix()),
      );
      addTearDown(app.dispose);
      expect(find.byKey(locationNotSetNote), findsOneWidget);
      expect(
        find.ancestor(
          of: pageText('Location not set'),
          matching: find.byType(NaErrorState),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Real position shows no location error', (tester) async {
      final app = await pumpNearby(
        tester: tester,
        bmlt: nearbyServing(reply: mondayMeeting()),
        delivery: locatedAt(aarhus),
      );
      addTearDown(app.dispose);
      expect(find.byKey(locationNotSetNote), findsNothing);
      expect(pageText('Location not set'), findsNothing);
    });
  });

  group('Requirement: Location permission', () {
    testWidgets('Permission is not requested elsewhere', (tester) async {
      final app = await pumpNearby(
        tester: tester,
        bmlt: nearbyServing(),
        location: MenuDestination.home.path,
      );
      addTearDown(app.dispose);
      for (final entry in ['menu-meetings', 'menu-settings', 'menu-home']) {
        await openMenu(tester);
        await tester.tap(find.byKey(Key(entry)));
        await settle(tester);
      }
      expect(app.geolocation.calls, const CallCount(0));
    });

    testWidgets('Position is not persisted', (tester) async {
      final app = await pumpNearby(
        tester: tester,
        bmlt: nearbyServing(reply: mondayMeeting()),
        delivery: locatedAt(aarhus),
      );
      addTearDown(app.dispose);
      expect(app.geolocation.positionCalls, const CallCount(1));
      expect(
        app.storage.snapshot.values.where(
          (value) => value.contains('56.15') || value.contains('10.2'),
        ),
        isEmpty,
      );
    });
  });

  group('Requirement: Loading states', () {
    testWidgets('Loader text while searching', (tester) async {
      final bmlt = nearbyServing(reply: mondayMeeting());
      final held = bmlt.holdNearby(radius: const Km(15));
      final app = await pumpNearby(
        tester: tester,
        bmlt: bmlt,
        delivery: locatedAt(aarhus),
        settleWith: AppSettle.frames,
      );
      addTearDown(app.dispose);
      expect(loadingText(tester), 'Finding meetings…');
      held.release();
      await settle(tester);
      expect(loadingBar(), findsNothing);
    });
  });
}
