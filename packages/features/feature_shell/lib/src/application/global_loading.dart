import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

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
  const LoadingActive({required this.count, required this.text});

  final int count;
  final String text;

  @override
  int get hashCode => Object.hash(count, text);

  @override
  bool operator ==(Object other) =>
      other is LoadingActive && other.count == count && other.text == text;
}

final NotifierProvider<GlobalLoading, LoadingActivity> globalLoadingProvider =
    NotifierProvider(GlobalLoading.new);

final class GlobalLoading extends Notifier<LoadingActivity> {
  @override
  LoadingActivity build() => const LoadingIdle();

  void present({required String text}) => state = switch (state) {
    LoadingIdle() => LoadingActive(count: 1, text: text),
    LoadingActive(:final count) => LoadingActive(count: count + 1, text: text),
  };

  void dismiss() => state = switch (state) {
    LoadingIdle() => const LoadingIdle(),
    LoadingActive(count: 1) => const LoadingIdle(),
    LoadingActive(:final count, :final text) => LoadingActive(
      count: count - 1,
      text: text,
    ),
  };
}
