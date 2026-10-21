import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';

const ProfileName anna = ProfileName('Anna');

CleantimeProfile aCleantimeProfile({
  ProfileName name = anna,
  LocalDate cleanDate = const LocalDate(year: 2020, month: 5, day: 3),
}) => CleantimeProfile(name: name, cleanDate: cleanDate);

CleantimeProfiles aCleantimeProfiles({
  List<CleantimeProfile> entries = const [],
  ProfileIndex active = const ProfileIndex(0),
}) => CleantimeProfiles.restore(
  entries: entries.isEmpty ? [aCleantimeProfile()] : entries,
  active: active,
  fallback: aCleantimeProfile(),
);

Map<String, String> aStoredCleantimeProfiles({
  List<CleantimeProfile> entries = const [],
  ProfileIndex active = const ProfileIndex(0),
}) {
  const codec = CleantimeProfilesCodec();
  return Map.unmodifiable({
    SettingKeys.cleantimeProfiles.name: codec.encodeProfiles(
      profiles: entries.isEmpty ? [aCleantimeProfile()] : entries,
    ),
    SettingKeys.activeCleantimeProfile.name: codec.encodeActive(index: active),
  });
}

LegacyCleanDateProfileDto aLegacyCleanDateProfile({
  String name = 'Anna',
  String cleandate = '2020-05-03T00:00:00.000+02:00',
}) => LegacyCleanDateProfileDto(name: name, cleandate: cleandate);

LegacyStoreDumpDto aLegacyCleantimeDump({
  List<LegacyCleanDateProfileDto> profiles = const [],
  String activeProfile = '0',
}) => LegacyStoreDumpDto(
  cleanDateProfiles: profiles.isEmpty ? [aLegacyCleanDateProfile()] : profiles,
  activeProfile: activeProfile,
);
