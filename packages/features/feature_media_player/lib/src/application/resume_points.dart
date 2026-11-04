import 'dart:async';

import 'package:meta/meta.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

@immutable
final class ResumeLibrary {
  const ResumeLibrary({required this.books, required this.speaks});

  static const ResumeLibrary empty = ResumeLibrary(
    books: ResumeIndex.empty,
    speaks: ResumeIndex.empty,
  );

  final ResumeIndex books;
  final ResumeIndex speaks;

  ResumeIndex of({required PlaylistKind kind}) => switch (kind) {
    PlaylistKind.book => books,
    PlaylistKind.speak => speaks,
  };

  ResumeLibrary withIndex({
    required PlaylistKind kind,
    required ResumeIndex index,
  }) => switch (kind) {
    PlaylistKind.book => ResumeLibrary(books: index, speaks: speaks),
    PlaylistKind.speak => ResumeLibrary(books: books, speaks: index),
  };

  @override
  int get hashCode => Object.hash(books, speaks);

  @override
  bool operator ==(Object other) =>
      other is ResumeLibrary && other.books == books && other.speaks == speaks;

  @override
  String toString() => 'ResumeLibrary(books: $books, speaks: $speaks)';
}

final NotifierProvider<ResumePoints, LoadResult<ResumeLibrary>>
resumePointsProvider = NotifierProvider(ResumePoints.new);

final class ResumePoints extends Notifier<LoadResult<ResumeLibrary>> {
  static const ResumeCodec _codec = ResumeCodec();

  Future<void> _queue = Future.value();

  KeyValueStorePort get _storage => ref.read(keyValueStorePortProvider);

  Clock get _clock => ref.read(clockProvider);

  @override
  LoadResult<ResumeLibrary> build() {
    unawaited(_serial(_load));
    return const Loading();
  }

  Future<ResumeState> pointFor({
    required PlaylistKind kind,
    required PlaylistId id,
  }) => _serial(() async {
    final stored = await _storage.read(key: kind.pointKey(id: id));
    return switch (stored) {
      StoredString(:final value) => switch (_codec.decodePoint(
        text: value,
        fallbackTime: _clock.now(),
      )) {
        Ok(value: final point) => ResumeAt(point: point),
        Err() => const NotStarted(),
      },
      NothingStored() => const NotStarted(),
    };
  });

  Future<void> save({
    required PlaylistKind kind,
    required PlaylistId id,
    required ResumePoint point,
  }) => _serial(() async {
    await _storage.write(
      key: kind.pointKey(id: id),
      value: _codec.encodePoint(point: point),
    );
    await _writeIndex(
      kind: kind,
      index: (await _indexOf(kind: kind)).withPoint(id: id, point: point),
    );
  });

  Future<void> clear({required PlaylistKind kind, required PlaylistId id}) =>
      _serial(() async {
        await _storage.remove(key: kind.pointKey(id: id));
        final index = await _indexOf(kind: kind);
        if (index.points.containsKey(id)) {
          await _writeIndex(
            kind: kind,
            index: index.without(id: id),
          );
        }
      });

  Future<void> _load() async {
    final books = await _indexOf(kind: PlaylistKind.book);
    final speaks = await _indexOf(kind: PlaylistKind.speak);
    if (ref.mounted) {
      state = Loaded(
        value: ResumeLibrary(books: books, speaks: speaks),
      );
    }
  }

  Future<ResumeIndex> _indexOf({required PlaylistKind kind}) async =>
      switch (await _storage.read(key: kind.indexKey)) {
        StoredString(:final value) => _codec.decodeIndex(
          text: value,
          fallbackTime: _clock.now(),
        ),
        NothingStored() => ResumeIndex.empty,
      };

  Future<void> _writeIndex({
    required PlaylistKind kind,
    required ResumeIndex index,
  }) async {
    await _storage.write(
      key: kind.indexKey,
      value: _codec.encodeIndex(index: index),
    );
    await _load();
  }

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then<void>((_) {}, onError: (Object error) {});
    return result;
  }
}
