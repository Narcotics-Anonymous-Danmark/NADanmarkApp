@Tags(['unit'])
library;

import 'dart:async';

import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

void main() {
  group('BackRule', () {
    const rule = BackRule();

    test('closes an open menu first', () {
      expect(
        rule.resolve(
          location: const RoutePath('/settings'),
          menu: NaDrawerVisibility.open,
        ),
        isA<CloseMenu>(),
      );
    });

    test('book pages return to the audiobooks list', () {
      expect(
        rule.resolve(
          location: const RoutePath('/basic-text'),
          menu: NaDrawerVisibility.closed,
        ),
        isA<PopToParent>().having(
          (b) => b.parent,
          'parent',
          const RoutePath('/audiobooks'),
        ),
      );
    });

    test('other pages go home and home leaves the app', () {
      expect(
        rule.resolve(
          location: const RoutePath('/settings'),
          menu: NaDrawerVisibility.closed,
        ),
        isA<GoHome>(),
      );
      expect(
        rule.resolve(
          location: const RoutePath('/home'),
          menu: NaDrawerVisibility.closed,
        ),
        isA<LeaveApp>(),
      );
    });
  });

  group('Sub-pages', () {
    test('a municipality page goes back to the meeting list', () {
      expect(
        const BackRule().resolve(
          location: const RoutePath('/listfull/Aarhus'),
          menu: NaDrawerVisibility.closed,
        ),
        isA<PopToParent>().having(
          (rule) => rule.parent,
          'parent',
          MenuDestination.meetings.path,
        ),
      );
    });

    test('the menu entry stays selected on its sub-pages only', () {
      expect(
        MenuDestination.meetings.selectionAt(
          location: const RoutePath('/listfull/K%C3%B8benhavn'),
        ),
        NaSelection.selected,
      );
      expect(
        MenuDestination.meetings.selectionAt(
          location: MenuDestination.meetings.path,
        ),
        NaSelection.selected,
      );
      expect(
        MenuDestination.meetings.selectionAt(
          location: const RoutePath('/listfullness'),
        ),
        NaSelection.unselected,
      );
      expect(
        MenuDestination.home.selectionAt(
          location: const RoutePath('/listfull/Aarhus'),
        ),
        NaSelection.unselected,
      );
    });

    test('an unknown parent falls back to home', () {
      expect(
        MenuDestination.parentOf(location: const RoutePath('/nowhere/x')),
        MenuDestination.home.path,
      );
    });
  });

  group('GlobalLoading', () {
    test('is reference counted and never goes negative', () {
      final harness = TestContainer.build();
      addTearDown(harness.dispose);
      final loading = harness.read(globalLoadingProvider.notifier)..dismiss();
      expect(harness.read(globalLoadingProvider), const LoadingIdle());
      loading
        ..present(text: 'Locating…')
        ..present(text: 'Finding meetings…');
      expect(
        harness.read(globalLoadingProvider),
        const LoadingActive(
          count: 2,
          status: LoadingText(text: 'Finding meetings…'),
        ),
      );
      loading.dismiss();
      expect(harness.read(globalLoadingProvider), isA<LoadingActive>());
      loading.dismiss();
      expect(harness.read(globalLoadingProvider), const LoadingIdle());
    });

    test('busy events present and dismiss the bar', () async {
      final harness = TestContainer.build();
      addTearDown(harness.dispose);
      final subscription = harness.container.listen(
        globalLoadingProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);
      final tracker = BusyTracker(bus: harness.events);
      final finish = Completer<void>();
      final work = tracker.track(
        activity: BusyActivity.findingMeetings,
        work: () => finish.future,
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        harness.read(globalLoadingProvider),
        const LoadingActive(
          count: 1,
          status: BusyStatus(activity: BusyActivity.findingMeetings),
        ),
      );
      finish.complete();
      await work;
      await Future<void>.delayed(Duration.zero);
      expect(harness.read(globalLoadingProvider), const LoadingIdle());
    });

    test('a failed piece of work still ends the busy activity', () async {
      final harness = TestContainer.build();
      addTearDown(harness.dispose);
      final tracker = BusyTracker(bus: harness.events);
      await expectLater(
        tracker.track<void>(
          activity: BusyActivity.findingMeetings,
          work: () => Future.error(StateError('offline')),
        ),
        throwsStateError,
      );
      expect(harness.events.recordedOf<BusyStarted>(), hasLength(1));
      expect(harness.events.recordedOf<BusyEnded>(), hasLength(1));
    });
  });

  group('MenuController and destinations', () {
    test('opens and closes', () {
      final harness = TestContainer.build();
      addTearDown(harness.dispose);
      final menu = harness.read(menuControllerProvider.notifier);
      expect(harness.read(menuControllerProvider), NaDrawerVisibility.closed);
      menu.open();
      expect(harness.read(menuControllerProvider), NaDrawerVisibility.open);
      menu.close();
      expect(harness.read(menuControllerProvider), NaDrawerVisibility.closed);
    });

    test('twelve destinations in legacy order', () {
      expect(MenuDestination.values.map((d) => d.path.value), [
        '/home',
        '/map-search',
        '/location-search',
        '/listfull',
        '/jft',
        '/cleantime-counter',
        '/events',
        '/audiobooks',
        '/speaks',
        '/grc',
        '/settings',
        '/contact',
      ]);
      expect(const NoPlayer().height, 0);
      expect(
        const PlayerDocked(player: SizedBox.shrink(), height: 64).height,
        64,
      );
    });
  });

  test('loading states hash by value and book routes have labels', () {
    expect(const LoadingIdle().hashCode, const LoadingIdle().hashCode);
    expect(
      const LoadingActive(count: 1, status: LoadingText(text: 'a')).hashCode,
      const LoadingActive(count: 1, status: LoadingText(text: 'a')).hashCode,
    );
    expect(
      const BusyStatus(activity: BusyActivity.findingMeetings).hashCode,
      const BusyStatus(activity: BusyActivity.findingMeetings).hashCode,
    );
    expect(BookRoute.values.map((b) => b.path.value), [
      '/basic-text',
      '/how-and-why',
      '/step-working-guides',
    ]);
  });
}
