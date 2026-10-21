import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/time/local_date.dart';

extension type const ProfileName(String text) {
  ProfileName get trimmed => ProfileName(text.trim());
}

extension type const ProfileIndex(int position) {
  ProfileIndex within({required List<CleantimeProfile> entries}) =>
      ProfileIndex(position.clamp(0, entries.length - 1));
}

@immutable
final class CleantimeProfile {
  const CleantimeProfile({required this.name, required this.cleanDate});

  final ProfileName name;
  final LocalDate cleanDate;

  CleantimeProfile withName({required ProfileName name}) =>
      CleantimeProfile(name: name, cleanDate: cleanDate);

  CleantimeProfile withCleanDate({required LocalDate cleanDate}) =>
      CleantimeProfile(name: name, cleanDate: cleanDate);

  @override
  int get hashCode => Object.hash(name, cleanDate);

  @override
  bool operator ==(Object other) =>
      other is CleantimeProfile &&
      other.name == name &&
      other.cleanDate == cleanDate;

  @override
  String toString() => 'CleantimeProfile(${name.text}, $cleanDate)';
}

@immutable
final class CleantimeProfiles {
  const CleantimeProfiles._({required this.entries, required this.active});

  factory CleantimeProfiles.single({required CleantimeProfile profile}) =>
      CleantimeProfiles._(
        entries: List.unmodifiable([profile]),
        active: const ProfileIndex(0),
      );

  factory CleantimeProfiles.restore({
    required List<CleantimeProfile> entries,
    required ProfileIndex active,
    required CleantimeProfile fallback,
  }) => entries.isEmpty
      ? CleantimeProfiles.single(profile: fallback)
      : CleantimeProfiles._(
          entries: List.unmodifiable(entries),
          active: active.within(entries: entries),
        );

  final List<CleantimeProfile> entries;
  final ProfileIndex active;

  CleantimeProfile get activeProfile => entries[active.position];

  CleantimeProfiles add({required CleantimeProfile profile}) =>
      CleantimeProfiles._(
        entries: List.unmodifiable([...entries, profile]),
        active: ProfileIndex(entries.length),
      );

  CleantimeProfiles rename({required ProfileName name}) =>
      _replaceActive(profile: activeProfile.withName(name: name));

  CleantimeProfiles changeDate({required LocalDate cleanDate}) =>
      _replaceActive(
        profile: activeProfile.withCleanDate(cleanDate: cleanDate),
      );

  CleantimeProfiles select({required ProfileIndex index}) =>
      CleantimeProfiles._(
        entries: entries,
        active: index.within(entries: entries),
      );

  CleantimeProfiles deleteActive({required CleantimeProfile fallback}) =>
      CleantimeProfiles.restore(
        entries: List.unmodifiable(
          entries.indexed
              .where((entry) => entry.$1 != active.position)
              .map((entry) => entry.$2),
        ),
        active: const ProfileIndex(0),
        fallback: fallback,
      );

  CleantimeProfiles _replaceActive({required CleantimeProfile profile}) =>
      CleantimeProfiles._(
        entries: List.unmodifiable(
          entries.indexed.map(
            (entry) => entry.$1 == active.position ? profile : entry.$2,
          ),
        ),
        active: active,
      );

  static const ListEquality<CleantimeProfile> _equality = ListEquality();

  @override
  int get hashCode => Object.hash(_equality.hash(entries), active);

  @override
  bool operator ==(Object other) =>
      other is CleantimeProfiles &&
      other.active == active &&
      _equality.equals(other.entries, entries);

  @override
  String toString() => 'CleantimeProfiles($entries, active ${active.position})';
}
