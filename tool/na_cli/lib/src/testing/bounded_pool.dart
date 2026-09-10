import 'dart:math';

final class BoundedPool {
  const BoundedPool({required this.width});

  final int width;

  Future<List<R>> map<T, R>({
    required final List<T> items,
    required final Future<R> Function(T item) action,
  }) async {
    final results = <R>[];
    for (var start = 0; start < items.length; start += width) {
      final chunk = items.sublist(start, min(start + width, items.length));
      results.addAll(await Future.wait(chunk.map(action)));
    }
    return List.unmodifiable(results);
  }
}
