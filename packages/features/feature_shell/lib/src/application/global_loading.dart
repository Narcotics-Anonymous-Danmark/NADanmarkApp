import 'dart:async';

import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

@immutable
sealed class LoadingStatus {
  const LoadingStatus();
}

final class LoadingText extends LoadingStatus {
  const LoadingText({required this.text});

  final String text;

  @override
  int get hashCode => Object.hash(LoadingText, text);

  @override
  bool operator ==(Object other) => other is LoadingText && other.text == text;
}

final class BusyStatus extends LoadingStatus {
  const BusyStatus({required this.activity});

  final BusyActivity activity;

  @override
  int get hashCode => Object.hash(BusyStatus, activity);

  @override
  bool operator ==(Object other) =>
      other is BusyStatus && other.activity == activity;
}

@immutable
sealed class LoadingActivity {
  const LoadingActivity();
}

final class LoadingIdle extends LoadingActivity {
  const LoadingIdle();

  @override
  int get hashCode => (LoadingIdle).hashCode;

  @override
  bool operator ==(Object other) => other is LoadingIdle;
}

final class LoadingActive extends LoadingActivity {
  const LoadingActive({required this.count, required this.status});

  final int count;
  final LoadingStatus status;

  @override
  int get hashCode => Object.hash(count, status);

  @override
  bool operator ==(Object other) =>
      other is LoadingActive && other.count == count && other.status == status;
}

final NotifierProvider<GlobalLoading, LoadingActivity> globalLoadingProvider =
    NotifierProvider(GlobalLoading.new);

final class GlobalLoading extends Notifier<LoadingActivity> {
  @override
  LoadingActivity build() {
    final bus = ref.watch(eventBusProvider);
    final started = bus.on<BusyStarted>().listen(
      (event) => _present(status: BusyStatus(activity: event.activity)),
    );
    final ended = bus.on<BusyEnded>().listen((event) => dismiss());
    ref
      ..onDispose(() => unawaited(started.cancel()))
      ..onDispose(() => unawaited(ended.cancel()));
    return const LoadingIdle();
  }

  void present({required String text}) =>
      _present(status: LoadingText(text: text));

  void dismiss() => state = switch (state) {
    LoadingIdle() => const LoadingIdle(),
    LoadingActive(count: 1) => const LoadingIdle(),
    LoadingActive(:final count, :final status) => LoadingActive(
      count: count - 1,
      status: status,
    ),
  };

  void _present({required LoadingStatus status}) => state = switch (state) {
    LoadingIdle() => LoadingActive(count: 1, status: status),
    LoadingActive(:final count) => LoadingActive(
      count: count + 1,
      status: status,
    ),
  };
}
