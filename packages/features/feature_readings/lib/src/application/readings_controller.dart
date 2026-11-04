import 'dart:async';

import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

final NotifierProvider<ReadingsController, LoadResult<ReadingCollection>>
readingsProvider = NotifierProvider(ReadingsController.new);

final NotifierProvider<SelectedReading, ReadingIndex> selectedReadingProvider =
    NotifierProvider(SelectedReading.new);

final class ReadingsController extends Notifier<LoadResult<ReadingCollection>> {
  @override
  LoadResult<ReadingCollection> build() {
    unawaited(Future.microtask(_load));
    return const Loading();
  }

  Future<void> _load() async {
    final outcome = await ref.read(readingsPortProvider).load();
    if (ref.mounted) {
      state = LoadResult.fromOutcome(outcome: outcome);
    }
  }
}

final class SelectedReading extends Notifier<ReadingIndex> {
  @override
  ReadingIndex build() => const ReadingIndex(0);

  ReadingIndex get selected => state;

  set selected(ReadingIndex index) => state = index;
}
