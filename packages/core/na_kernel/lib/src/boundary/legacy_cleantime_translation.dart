import 'package:meta/meta.dart';
import 'package:na_kernel/src/boundary/legacy_wire.dart';
import 'package:na_kernel/src/cleantime/cleantime_profiles.dart';
import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/time/local_date.dart';
import 'package:na_kernel/src/values/storage_key.dart';

@immutable
sealed class LegacyCleantimeImport {
  const LegacyCleantimeImport();
}

final class ImportCleantime extends LegacyCleantimeImport {
  const ImportCleantime({required this.profiles});

  final CleantimeProfiles profiles;

  @override
  int get hashCode => profiles.hashCode;

  @override
  bool operator ==(Object other) =>
      other is ImportCleantime && other.profiles == profiles;

  @override
  String toString() => 'ImportCleantime($profiles)';
}

final class SkipCleantime extends LegacyCleantimeImport {
  const SkipCleantime();

  @override
  int get hashCode => (SkipCleantime).hashCode;

  @override
  bool operator ==(Object other) => other is SkipCleantime;

  @override
  String toString() => 'SkipCleantime()';
}

@immutable
final class LegacyCleantimeTranslation {
  const LegacyCleantimeTranslation({
    required this.import,
    required this.importedKeys,
    required this.skippedKeys,
  });

  final LegacyCleantimeImport import;
  final List<StorageKey> importedKeys;
  final List<StorageKey> skippedKeys;

  @override
  int get hashCode => Object.hash(
    import,
    Object.hashAll(importedKeys),
    Object.hashAll(skippedKeys),
  );

  @override
  bool operator ==(Object other) =>
      other is LegacyCleantimeTranslation &&
      other.import == import &&
      other.importedKeys.join(',') == importedKeys.join(',') &&
      other.skippedKeys.join(',') == skippedKeys.join(',');

  @override
  String toString() =>
      'LegacyCleantimeTranslation($import, imported $importedKeys, '
      'skipped $skippedKeys)';
}

final class LegacyCleantimeTranslator {
  const LegacyCleantimeTranslator();

  static const StorageKey legacyProfilesKey = StorageKey('cleanDateProfiles');
  static const StorageKey legacyActiveKey = StorageKey('activeProfile');

  static final RegExp _leadingDate = RegExp(r'^\d{4}-\d{2}-\d{2}');

  LegacyCleantimeTranslation translate({
    required LegacyStoreDumpDto dump,
    required ProfileName Function(ProfileIndex index) unnamed,
  }) {
    final profiles = _profilesOf(dump: dump, unnamed: unnamed);
    final active = _activeOf(dump: dump);
    final (imported, skipped) = switch ((profiles, active)) {
      (_ProfilesKept(), _ActiveParsed()) => (
        const [legacyProfilesKey, legacyActiveKey],
        const <StorageKey>[],
      ),
      (_ProfilesKept(), _ActiveUnreadable()) => (
        const [legacyProfilesKey],
        const [legacyActiveKey],
      ),
      (_ProfilesKept(), _ActiveAbsent()) => (
        const [legacyProfilesKey],
        const <StorageKey>[],
      ),
      (_ProfilesEmpty(), _ActiveParsed() || _ActiveUnreadable()) => (
        const <StorageKey>[],
        const [legacyProfilesKey, legacyActiveKey],
      ),
      (_ProfilesEmpty(), _ActiveAbsent()) => (
        const <StorageKey>[],
        const [legacyProfilesKey],
      ),
      (_ProfilesAbsent(), _ActiveParsed() || _ActiveUnreadable()) => (
        const <StorageKey>[],
        const [legacyActiveKey],
      ),
      (_ProfilesAbsent(), _ActiveAbsent()) => (
        const <StorageKey>[],
        const <StorageKey>[],
      ),
    };
    return LegacyCleantimeTranslation(
      import: switch (profiles) {
        _ProfilesKept(:final entries) => ImportCleantime(
          profiles: CleantimeProfiles.restore(
            entries: entries,
            active: switch (active) {
              _ActiveParsed(:final index) => index,
              _ActiveUnreadable() || _ActiveAbsent() => const ProfileIndex(0),
            },
            fallback: entries.first,
          ),
        ),
        _ProfilesEmpty() || _ProfilesAbsent() => const SkipCleantime(),
      },
      importedKeys: imported,
      skippedKeys: skipped,
    );
  }

  _LegacyProfiles _profilesOf({
    required LegacyStoreDumpDto dump,
    required ProfileName Function(ProfileIndex index) unnamed,
  }) => switch (dump.cleanDateProfiles) {
    null => const _ProfilesAbsent(),
    final List<LegacyCleanDateProfileDto> entries => switch (_keptEntries(
      entries: entries,
    )) {
      [] => const _ProfilesEmpty(),
      final List<CleantimeProfile> kept => _ProfilesKept(
        entries: List.unmodifiable(
          kept.indexed.map(
            (entry) => entry.$2.name.text.isEmpty
                ? entry.$2.withName(name: unnamed(ProfileIndex(entry.$1)))
                : entry.$2,
          ),
        ),
      ),
    },
  };

  _LegacyActive _activeOf({required LegacyStoreDumpDto dump}) =>
      switch (dump.activeProfile) {
        null => const _ActiveAbsent(),
        final String text => switch (int.tryParse(text.trim())) {
          final int position => _ActiveParsed(index: ProfileIndex(position)),
          null => const _ActiveUnreadable(),
        },
      };

  List<CleantimeProfile> _keptEntries({
    required List<LegacyCleanDateProfileDto> entries,
  }) => List.unmodifiable(
    entries
        .map(
          (entry) => switch (_leadingDate.firstMatch(entry.cleandate ?? '')) {
            final RegExpMatch match =>
              LocalDate.parseIso(
                text: match.group(0) ?? '',
              ).map(
                transform: (date) => CleantimeProfile(
                  name: ProfileName((entry.name ?? '').trim()),
                  cleanDate: date,
                ),
              ),
            null => const Err<CleantimeProfile, DecodeFailure>(
              error: DecodeFailure(detail: 'cleandate: no leading date'),
            ),
          },
        )
        .whereType<Ok<CleantimeProfile, DecodeFailure>>()
        .map((ok) => ok.value),
  );
}

sealed class _LegacyProfiles {
  const _LegacyProfiles();
}

final class _ProfilesKept extends _LegacyProfiles {
  const _ProfilesKept({required this.entries});

  final List<CleantimeProfile> entries;
}

final class _ProfilesEmpty extends _LegacyProfiles {
  const _ProfilesEmpty();
}

final class _ProfilesAbsent extends _LegacyProfiles {
  const _ProfilesAbsent();
}

sealed class _LegacyActive {
  const _LegacyActive();
}

final class _ActiveParsed extends _LegacyActive {
  const _ActiveParsed({required this.index});

  final ProfileIndex index;
}

final class _ActiveUnreadable extends _LegacyActive {
  const _ActiveUnreadable();
}

final class _ActiveAbsent extends _LegacyActive {
  const _ActiveAbsent();
}
