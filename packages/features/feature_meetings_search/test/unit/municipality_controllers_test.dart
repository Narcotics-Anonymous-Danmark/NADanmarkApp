@Tags(['unit'])
library;

import 'package:feature_meetings_search/feature_meetings_search.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';
import 'package:riverpod/misc.dart';

const aarhus = NamedMunicipality(name: MunicipalityName('Aarhus'));

TestContainer harnessFor({required List<Meeting> meetings}) {
  final harness = TestContainer.build();
  addTearDown(harness.dispose);
  harness.meetingSearch
    ..meetings = Ok(value: meetings)
    ..municipalities = Ok(
      value: List.unmodifiable(
        ['Aarhus', 'Aarhus', '', 'København'].map(MunicipalityName.new),
      ),
    );
  return harness;
}

Future<T> settled<T>(
  TestContainer harness,
  ProviderListenable<T> provider,
) async {
  final subscription = harness.container.listen(provider, (previous, next) {});
  addTearDown(subscription.close);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return harness.read(provider);
}

void main() {
  group('MunicipalitiesController', () {
    test('lists unique municipalities with Online last', () async {
      final harness = harnessFor(meetings: const []);
      final loaded = await settled(harness, municipalitiesProvider);
      expect(
        (loaded as Loaded<List<Municipality>>).value.map((m) => '$m'),
        ['Aarhus', 'København', 'Online'],
      );
    });

    test('an empty answer is an empty list', () async {
      final harness = harnessFor(meetings: const []);
      harness.meetingSearch.municipalities = const Ok(value: []);
      final loaded = await settled(harness, municipalitiesProvider);
      expect((loaded as Loaded<List<Municipality>>).value, isEmpty);
    });

    test('a failure can be retried and brackets the busy activity', () async {
      final harness = harnessFor(meetings: const []);
      harness.meetingSearch.municipalities = const Err(
        error: NetworkFailure(detail: 'offline'),
      );
      expect(
        await settled(harness, municipalitiesProvider),
        isA<Failed<List<Municipality>>>(),
      );
      harness.meetingSearch.municipalities = const Ok(
        value: [MunicipalityName('Aarhus')],
      );
      await harness.read(municipalitiesProvider.notifier).retry();
      expect(
        harness.read(municipalitiesProvider),
        isA<Loaded<List<Municipality>>>(),
      );
      expect(harness.events.recordedOf<BusyStarted>(), hasLength(2));
      expect(harness.events.recordedOf<BusyEnded>(), hasLength(2));
    });
  });

  group('MunicipalityMeetingsController', () {
    test('keeps only the meetings of the municipality', () async {
      final harness = harnessFor(
        meetings: [
          aMeeting(id: 1, municipality: 'Aarhus'),
          aMeeting(id: 2, municipality: 'København'),
        ],
      );
      final loaded = await settled(
        harness,
        municipalityMeetingsProvider(aarhus),
      );
      expect(
        (loaded as Loaded<List<Meeting>>).value.map((m) => m.id),
        [const MeetingId(1)],
      );
    });

    test('Online collects every online alias', () async {
      final harness = harnessFor(
        meetings: [
          aMeeting(id: 1, municipality: ''),
          aMeeting(id: 2, municipality: 'Viborg online'),
          aMeeting(id: 3, municipality: 'Aarhus'),
        ],
      );
      final loaded = await settled(
        harness,
        municipalityMeetingsProvider(const OnlineMunicipality()),
      );
      expect((loaded as Loaded<List<Meeting>>).value, hasLength(2));
    });

    test(
      'a revisit starts loading again instead of showing old data',
      () async {
        final harness = harnessFor(
          meetings: [aMeeting(id: 1, municipality: 'Aarhus')],
        );
        final first = harness.container.listen(
          municipalityMeetingsProvider(aarhus),
          (previous, next) {},
        );
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(
          harness.read(municipalityMeetingsProvider(aarhus)),
          isA<Loaded<List<Meeting>>>(),
        );
        first.close();
        await Future<void>.delayed(Duration.zero);
        final gate = harness.meetingSearch.holdMeetings();
        final second = harness.container.listen(
          municipalityMeetingsProvider(aarhus),
          (previous, next) {},
        );
        addTearDown(second.close);
        expect(
          harness.read(municipalityMeetingsProvider(aarhus)),
          isA<Loading<List<Meeting>>>(),
        );
        gate.open();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(harness.meetingSearch.meetingCalls, 2);
      },
    );

    test('a failure can be retried', () async {
      final harness = harnessFor(meetings: const []);
      harness.meetingSearch.meetings = const Err(
        error: NetworkFailure(detail: 'offline'),
      );
      expect(
        await settled(harness, municipalityMeetingsProvider(aarhus)),
        isA<Failed<List<Meeting>>>(),
      );
      harness.meetingSearch.meetings = Ok(
        value: [aMeeting(id: 1, municipality: 'Aarhus')],
      );
      await harness.read(municipalityMeetingsProvider(aarhus).notifier).retry();
      expect(
        harness.read(municipalityMeetingsProvider(aarhus)),
        isA<Loaded<List<Meeting>>>(),
      );
    });

    test('a result arriving after disposal is dropped', () async {
      final harness = harnessFor(meetings: const []);
      final gate = harness.meetingSearch.holdMeetings();
      final subscription = harness.container.listen(
        municipalityMeetingsProvider(aarhus),
        (previous, next) {},
      );
      await Future<void>.delayed(Duration.zero);
      subscription.close();
      await Future<void>.delayed(Duration.zero);
      gate.open();
      await Future<void>.delayed(Duration.zero);
      expect(harness.events.recordedOf<BusyEnded>(), hasLength(1));
    });
  });
}
