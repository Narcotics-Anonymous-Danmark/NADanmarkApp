import 'package:feature_settings/src/application/settings_controller.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:riverpod/riverpod.dart';

final Provider<Language> currentLanguageProvider = Provider(
  (ref) => ref.watch(settingsControllerProvider).inUse.language,
);

final Provider<Settings> currentSettingsProvider = Provider(
  (ref) => ref.watch(settingsControllerProvider).inUse,
);
