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
  day: day,
  month: month,
  title: title,
  quote: quote,
  source: source,
  text: text,
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
  version: '2.0.0',
  buildType: BuildType('test'),
  approval: BuildApproval.approved,
);

AppInfo anAppInfo({
  String version = '2.0.0',
  String buildType = 'test',
  BuildApproval approval = BuildApproval.approved,
}) => AppInfo(
  version: version,
  buildType: BuildType(buildType),
  approval: approval,
);

LegacyMigrationMarker aMigrationMarker({
  String appVersion = '2.0.0',
  int importedKeys = 4,
  int skippedKeys = 0,
}) => LegacyMigrationMarker(
  appVersion: appVersion,
  completedAt: Instant(DateTime.utc(2026, 9, 10, 12)),
  importedKeys: importedKeys,
  skippedKeys: skippedKeys,
);

Map<String, Object> aLegacyStoreDump({
  String language = 'en',
  String firstday = 'su',
  Object searchRange = 30,
  String cleanTimeUnitSort = 'dmy',
  Map<String, Object> extra = const {},
}) => Map.unmodifiable({
  'language': language,
  'firstday': firstday,
  'searchRange': searchRange,
  'cleanTimeUnitSort': cleanTimeUnitSort,
  'theme': 'light',
  ...extra,
});
