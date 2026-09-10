import 'package:feature_settings/src/application/settings_controller.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:riverpod/riverpod.dart';

final Provider<Language> currentLanguageProvider = Provider(
  (ref) => switch (ref.watch(settingsControllerProvider)) {
    Loaded(:final value) => value.language,
    Loading() || Failed() => Language.fallback,
  },
);

final Provider<Settings> currentSettingsProvider = Provider(
  (ref) => switch (ref.watch(settingsControllerProvider)) {
    Loaded(:final value) => value,
    Loading() || Failed() => Settings.defaults,
  },
);
