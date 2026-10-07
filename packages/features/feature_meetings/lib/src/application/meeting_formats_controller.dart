import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

final NotifierProvider<MeetingFormatsController, LoadResult<List<FormatRow>>>
meetingFormatsProvider = NotifierProvider(MeetingFormatsController.new);

final ProviderFamily<LoadResult<FormatIndex>, Language> formatIndexProvider =
    Provider.family(
      (ref, language) => ref
          .watch(meetingFormatsProvider)
          .map(
            transform: (rows) => FormatIndex.build(
              rows: rows,
              display: FormatLanguageCode.displayFor(language: language),
            ),
          ),
    );

sealed class _FetchStatus {
  const _FetchStatus();
}

final class _NeverFetched extends _FetchStatus {
  const _NeverFetched();
}

final class _FreshUntil extends _FetchStatus {
  const _FreshUntil({required this.until});

  final Instant until;
}

final class _InFlight extends _FetchStatus {
  const _InFlight({required this.done});

  final Future<void> done;
}

final class _FailedAt extends _FetchStatus {
  const _FailedAt({required this.at});

  final Instant at;
}

final class MeetingFormatsController
    extends Notifier<LoadResult<List<FormatRow>>> {
  static const FormatsCacheCodec _codec = FormatsCacheCodec();

  _FetchStatus _status = const _NeverFetched();

  @override
  LoadResult<List<FormatRow>> build() => const Loading();

  Future<void> ensureLoaded() {
    final now = ref.read(clockProvider).now();
    return switch (_status) {
      _InFlight(:final done) => done,
      _FreshUntil(:final until)
          when now.compareTo(other: until) == Comparison.before =>
        Future.value(),
      _FailedAt(:final at)
          when now.since(other: at) < FormatsSnapshot.retryAfterFailure =>
        Future.value(),
      _NeverFetched() || _FreshUntil() || _FailedAt() => _start(),
    };
  }

  Future<void> _start() {
    final done = _load();
    _status = _InFlight(done: done);
    return done;
  }

  Future<void> _load() async {
    final cached = await _cached();
    final now = ref.read(clockProvider).now();
    switch (cached) {
      case Ok(:final value)
          when value.rows.isNotEmpty &&
              value.freshnessAt(now: now) == SnapshotFreshness.fresh:
        _status = _FreshUntil(
          until: value.fetchedAt.plus(duration: FormatsSnapshot.lifetime),
        );
        state = Loaded(value: value.rows);
        return;
      case Ok() || Err():
        break;
    }
    switch (await ref.read(meetingFormatsPortProvider).formatRows()) {
      case Ok(:final value) when value.isNotEmpty:
        await _store(
          snapshot: FormatsSnapshot(fetchedAt: now, rows: value),
        );
        _status = _FreshUntil(
          until: now.plus(duration: FormatsSnapshot.lifetime),
        );
        state = Loaded(value: value);
      case Ok() || Err():
        _status = _FailedAt(at: now);
        state = Loaded(
          value: switch (cached) {
            Ok(:final value) => value.rows,
            Err() => const [],
          },
        );
    }
  }

  Future<Outcome<FormatsSnapshot, DecodeFailure>> _cached() async =>
      switch (await ref
          .read(keyValueStorePortProvider)
          .read(key: MeetingFormatKeys.cache)) {
        StoredString(:final value) => _codec.decode(text: value),
        NothingStored() => const Err(
          error: DecodeFailure(detail: 'formats cache: nothing stored'),
        ),
      };

  Future<void> _store({required FormatsSnapshot snapshot}) async {
    await ref
        .read(keyValueStorePortProvider)
        .write(
          key: MeetingFormatKeys.cache,
          value: _codec.encode(snapshot: snapshot),
        );
  }
}
