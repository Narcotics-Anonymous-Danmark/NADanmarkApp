import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

final NotifierProvider<SettingsController, LoadResult<Settings>>
settingsControllerProvider = NotifierProvider(SettingsController.new);

final class SettingsController extends Notifier<LoadResult<Settings>> {
  @override
  LoadResult<Settings> build() => const Loading();

  Settings get current => switch (state) {
    Loaded(:final value) => value,
    Loading() || Failed() => Settings.defaults,
  };

  Future<void> load() async {
    final port = ref.read(settingsPortProvider);
    final stored = await port.read();
    await _persist(next: stored, previous: stored);
  }

  Future<void> changeLanguage({required Language language}) =>
      _change(transform: (s) => s.withLanguage(language: language));

  Future<void> changeFirstDayOfWeek({required FirstDayOfWeek firstDay}) =>
      _change(transform: (s) => s.withFirstDayOfWeek(firstDayOfWeek: firstDay));

  Future<void> changeCleanTimeUnitOrder({required CleanTimeUnitOrder order}) =>
      _change(
        transform: (s) => s.withCleanTimeUnitOrder(cleanTimeUnitOrder: order),
      );

  Future<void> changeSearchRadius({required Km radius}) =>
      _change(transform: (s) => s.withSearchRadius(searchRadius: radius));

  Future<void> _change({
    required Settings Function(Settings settings) transform,
  }) async {
    final previous = current;
    await _persist(next: transform(previous), previous: previous);
  }

  Future<void> _persist({
    required Settings next,
    required Settings previous,
  }) async {
    final port = ref.read(settingsPortProvider);
    switch (await port.write(settings: next)) {
      case Ok():
        state = Loaded(value: next);
        _announce(next: next, previous: previous);
      case Err(:final error):
        state = Failed(failure: error);
    }
  }

  void _announce({required Settings next, required Settings previous}) {
    final bus = ref.read(eventBusProvider);
    if (next == previous) {
      return;
    }
    bus.publish(event: SettingsChanged(settings: next));
    if (next.language != previous.language) {
      bus.publish(event: LanguageChanged(language: next.language));
    }
  }
}
