import 'package:meta/meta.dart';
import 'package:na_kernel/src/values/language.dart';
import 'package:na_kernel/src/values/settings.dart';

@immutable
sealed class DomainEvent {
  const DomainEvent();
}

final class LanguageChanged extends DomainEvent {
  const LanguageChanged({required this.language});

  final Language language;
}

final class SettingsChanged extends DomainEvent {
  const SettingsChanged({required this.settings});

  final Settings settings;
}

final class LegacyMigrationCompleted extends DomainEvent {
  const LegacyMigrationCompleted({
    required this.importedKeys,
    required this.skippedKeys,
  });

  final int importedKeys;
  final int skippedKeys;
}
