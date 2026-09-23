import 'package:meta/meta.dart';
import 'package:na_kernel/src/values/language.dart';
import 'package:na_kernel/src/values/legacy_migration_marker.dart';
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

  final KeyCount importedKeys;
  final KeyCount skippedKeys;
}

enum BusyActivity { findingMeetings }

final class BusyStarted extends DomainEvent {
  const BusyStarted({required this.activity});

  final BusyActivity activity;
}

final class BusyEnded extends DomainEvent {
  const BusyEnded({required this.activity});

  final BusyActivity activity;
}
