import 'package:feature_jft/feature_jft.dart';
import 'package:feature_legacy_migration/feature_legacy_migration.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AppStartup {
  const AppStartup({required this.container});

  final ProviderContainer container;

  Future<void> run() async {
    await container.read(legacyMigrationProvider).runIfNeeded();
    await container.read(settingsControllerProvider.notifier).load();
    await container.read(jftControllerProvider.notifier).load();
  }
}
