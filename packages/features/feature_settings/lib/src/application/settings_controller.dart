import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

@immutable
sealed class SettingsState {
  const SettingsState();

  Settings get inUse => switch (this) {
    SettingsReady(:final settings) ||
    SettingsUnsaved(:final settings) => settings,
    SettingsNotLoaded() => throw StateError(
      'Settings were read before SettingsController.load() ran.',
    ),
  };
}

final class SettingsNotLoaded extends SettingsState {
  const SettingsNotLoaded();

  @override
  int get hashCode => (SettingsNotLoaded).hashCode;

  @override
  bool operator ==(Object other) => other is SettingsNotLoaded;
}

final class SettingsReady extends SettingsState {
  const SettingsReady({required this.settings});

  final Settings settings;

  @override
  int get hashCode => Object.hash(SettingsReady, settings);

  @override
  bool operator ==(Object other) =>
      other is SettingsReady && other.settings == settings;
}

final class SettingsUnsaved extends SettingsState {
  const SettingsUnsaved({required this.settings, required this.failure});

  final Settings settings;
  final StorageFailure failure;

  @override
  int get hashCode => Object.hash(settings, failure);

  @override
  bool operator ==(Object other) =>
      other is SettingsUnsaved &&
      other.settings == settings &&
      other.failure == failure;
}

final NotifierProvider<SettingsController, SettingsState>
settingsControllerProvider = NotifierProvider(SettingsController.new);

final class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsNotLoaded();

  Settings get current => state.inUse;

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
        state = SettingsReady(settings: next);
        _announce(next: next, previous: previous);
      case Err(:final error):
        state = SettingsUnsaved(settings: previous, failure: error);
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
