@Tags(['unit'])
library;

import 'package:feature_meetings/feature_meetings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

String cacheWrittenAt({required Instant fetchedAt}) =>
    const FormatRowsCodec().encodeSnapshot(
      snapshot: FormatsSnapshot(
        fetchedAt: fetchedAt,
        rows: [aMeetingFormatRow()],
      ),
    );

List<FormatRow> loadedRows(TestContainer harness) =>
    switch (harness.read(meetingFormatsProvider)) {
      Loaded(:final value) => value,
      Loading() || Failed() => fail('formats are not loaded'),
    };

TestContainer harnessWith({Map<String, String> storedValues = const {}}) {
  final harness = TestContainer.build(storedValues: storedValues);
  addTearDown(harness.dispose);
  return harness;
}

void main() {
  test('a fresh cache is used without the network', () async {
    final harness = harnessWith(
      storedValues: {
        MeetingFormatKeys.cache.name: cacheWrittenAt(
          fetchedAt: anInstant(day: 7),
        ),
      },
    );
    await harness.read(meetingFormatsProvider.notifier).ensureLoaded();
    expect(loadedRows(harness), [aMeetingFormatRow()]);
    expect(harness.meetingFormats.calls, 0);
  });

  test('without a cache the rows are fetched and cached', () async {
    final harness = harnessWith();
    await harness.read(meetingFormatsProvider.notifier).ensureLoaded();
    expect(loadedRows(harness), hasLength(54));
    expect(harness.meetingFormats.calls, 1);
    final stored = const FormatRowsCodec().decodeSnapshot(
      text: harness.storage.snapshot[MeetingFormatKeys.cache.name] ?? '',
    );
    expect(
      (stored as Ok<FormatsSnapshot, DecodeFailure>).value.fetchedAt,
      anInstant(),
    );
  });

  test('a stale cache is refreshed and used when the fetch fails', () async {
    final harness = harnessWith(
      storedValues: {
        MeetingFormatKeys.cache.name: cacheWrittenAt(
          fetchedAt: anInstant(day: 2),
        ),
      },
    );
    harness.meetingFormats.rows = const Err(
      error: NetworkFailure(detail: 'offline'),
    );
    await harness.read(meetingFormatsProvider.notifier).ensureLoaded();
    expect(loadedRows(harness), [aMeetingFormatRow()]);
    expect(harness.meetingFormats.calls, 1);
    expect(harness.storage.writes, isEmpty);
  });

  test('a failure without cache retries only after sixty seconds', () async {
    final harness = harnessWith();
    harness.meetingFormats.rows = const Err(
      error: NetworkFailure(detail: 'offline'),
    );
    final controller = harness.read(meetingFormatsProvider.notifier);
    await controller.ensureLoaded();
    expect(loadedRows(harness), isEmpty);
    harness.time.advance(by: const Duration(seconds: 59));
    await controller.ensureLoaded();
    expect(harness.meetingFormats.calls, 1);
    harness.time.advance(by: const Duration(seconds: 1));
    harness.meetingFormats.rows = Ok(value: recordedFormatRows());
    await controller.ensureLoaded();
    expect(harness.meetingFormats.calls, 2);
    expect(loadedRows(harness), hasLength(54));
  });

  test('an empty answer is never cached and counts as a failure', () async {
    final harness = harnessWith();
    harness.meetingFormats.rows = const Ok(value: []);
    final controller = harness.read(meetingFormatsProvider.notifier);
    await controller.ensureLoaded();
    await controller.ensureLoaded();
    expect(harness.storage.writes, isEmpty);
    expect(harness.meetingFormats.calls, 1);
  });

  test('concurrent requests share one fetch', () async {
    final harness = harnessWith();
    final gate = harness.meetingFormats.hold();
    final controller = harness.read(meetingFormatsProvider.notifier);
    final waiting = List.generate(20, (_) => controller.ensureLoaded());
    await Future<void>.delayed(Duration.zero);
    gate.open();
    await Future.wait(waiting);
    expect(harness.meetingFormats.calls, 1);
  });

  test('fetched rows stay fresh for seven days', () async {
    final harness = harnessWith();
    final controller = harness.read(meetingFormatsProvider.notifier);
    await controller.ensureLoaded();
    harness.time.advance(by: const Duration(days: 6, hours: 23));
    await controller.ensureLoaded();
    expect(harness.meetingFormats.calls, 1);
    harness.time.advance(by: const Duration(hours: 1));
    await controller.ensureLoaded();
    expect(harness.meetingFormats.calls, 2);
  });

  test('the index follows the display language and waits for rows', () async {
    final harness = harnessWith();
    expect(
      harness.read(formatIndexProvider(Language.english)),
      isA<Loading<FormatIndex>>(),
    );
    await harness.read(meetingFormatsProvider.notifier).ensureLoaded();
    FormatIndex index(Language language) =>
        switch (harness.read(formatIndexProvider(language))) {
          Loaded(:final value) => value,
          Loading() || Failed() => fail('index not loaded'),
        };
    const codes = MeetingFormatCodes(
      keys: [FormatKey('ÅM')],
      sharedIds: [FormatId(17)],
    );
    expect(
      index(
        Language.english,
      ).formatsOf(codes: codes, origin: MeetingOrigin.denmark).single.name,
      'Open',
    );
    expect(
      index(
        Language.danish,
      ).formatsOf(codes: codes, origin: MeetingOrigin.denmark).single.name,
      'Åben Møde',
    );
  });
}
