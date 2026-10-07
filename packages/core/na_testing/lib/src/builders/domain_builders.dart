import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';

Settings aSettings({
  Language language = Language.danish,
  FirstDayOfWeek firstDayOfWeek = FirstDayOfWeek.monday,
  CleanTimeUnitOrder cleanTimeUnitOrder = CleanTimeUnitOrder.yearsMonthsDays,
  int searchRadiusKm = 15,
}) => Settings(
  language: language,
  firstDayOfWeek: firstDayOfWeek,
  cleanTimeUnitOrder: cleanTimeUnitOrder,
  searchRadius: Km(searchRadiusKm),
);

JftEntry aJftEntry({
  int day = 10,
  DanishMonth month = DanishMonth.september,
  String title = 'Titel',
  String quote = '”Citat”',
  String source = 'Basis Tekst, s. 1',
  String text = 'Dagens tekst.',
  String closing = 'Bare for i dag: Jeg vil.',
}) => JftEntry(
  day: DayOfMonth(day),
  month: month,
  title: JftTitle(title),
  quote: JftQuote(quote),
  source: JftSource(source),
  text: JftText(text),
  closing: JftClosing.parse(text: closing),
);

JftCalendar aJftCalendar({List<JftEntry> extra = const []}) => JftCalendar(
  entries: List.unmodifiable([
    ...DanishMonth.values.expand(
      (month) => List.generate(
        month.daysInLeapYear,
        (index) => aJftEntry(
          day: index + 1,
          month: month,
          title: 'Titel ${index + 1}. ${month.name}',
        ),
      ),
    ),
    ...extra,
  ]),
);

const AppInfo testAppInfo = AppInfo(
  version: VersionName('2.0.0'),
  buildType: BuildType('test'),
  approval: BuildApproval.approved,
);

AppInfo anAppInfo({
  String version = '2.0.0',
  String buildType = 'test',
  BuildApproval approval = BuildApproval.approved,
}) => AppInfo(
  version: VersionName(version),
  buildType: BuildType(buildType),
  approval: approval,
);

LegacyMigrationMarker aMigrationMarker({
  String appVersion = '2.0.0',
  int importedKeys = 4,
  int skippedKeys = 0,
}) => LegacyMigrationMarker(
  appVersion: VersionName(appVersion),
  completedAt: Instant(DateTime.utc(2026, 9, 10, 12)),
  importedKeys: KeyCount(importedKeys),
  skippedKeys: KeyCount(skippedKeys),
);

LegacyStoreDumpDto aLegacyStoreDump({
  String language = 'en',
  String firstday = 'su',
  String searchRange = '30',
  String cleanTimeUnitSort = 'dmy',
  String theme = 'light',
}) => LegacyStoreDumpDto(
  language: language,
  firstday: firstday,
  searchRange: searchRange,
  cleanTimeUnitSort: cleanTimeUnitSort,
  theme: theme,
);

LegacyStoreDumpDto aLegacyDumpWithFormats({
  int fetchedAt = 1757500000000,
  List<BmltFormatDto> formats = const [],
}) => LegacyStoreDumpDto(
  meetingFormatsV1: FormatsCacheDto(fetchedAt: fetchedAt, formats: formats),
);

String aStoredMigrationMarker({
  String appVersion = '2.0.0',
  int importedKeys = 4,
  int skippedKeys = 0,
}) => const MigrationMarkerCodec().encode(
  marker: aMigrationMarker(
    appVersion: appVersion,
    importedKeys: importedKeys,
    skippedKeys: skippedKeys,
  ),
);
