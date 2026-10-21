import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

extension type const CleantimeText(String text) {}

final class CleantimeTexts {
  const CleantimeTexts({required this.l10n});

  factory CleantimeTexts.of({required Language language}) =>
      CleantimeTexts(l10n: lookupAppLocalizations(language.locale));

  final AppLocalizations l10n;

  CleantimeText years({required YearCount years}) => CleantimeText(
    '${years.value} ${years.value == 1 ? l10n.year : l10n.years}',
  );

  CleantimeText months({required MonthCount months}) => CleantimeText(
    '${months.value} ${months.value == 1 ? l10n.month : l10n.months}',
  );

  CleantimeText days({required DayCount days}) => CleantimeText(
    '${days.value} ${days.value == 1 ? l10n.day : l10n.days}',
  );

  CleantimeText anniversaryText({required Anniversary anniversary}) =>
      switch (anniversary.offset) {
        AfterDays(:final days) => CleantimeText(
          '${days.value} ${days.value == 1 ? l10n.dayclean : l10n.daysclean}',
        ),
        AfterMonths(:final months) => CleantimeText(
          '${months.value} '
          '${months.value == 1 ? l10n.monthclean : l10n.monthsclean}',
        ),
        AfterYears(:final years) => CleantimeText(
          '${years.value} '
          '${years.value == 1 ? l10n.yearclean : l10n.yearsclean}',
        ),
      };

  CleantimeText homeBreakdown({required YearsMonthsDays breakdown}) =>
      CleantimeText(
        l10n.cleantimeHomeBreakdown(
          years(years: breakdown.years).text,
          months(months: breakdown.months).text,
          days(days: breakdown.days).text,
        ),
      );

  ProfileName defaultProfileName({required ProfileIndex index}) =>
      ProfileName(l10n.cleantimeDefaultProfileName(index.position + 1));

  NotificationTitle notificationTitle({required ProfileName name}) =>
      NotificationTitle(l10n.notificationCleandayTitle(name.text));

  NotificationBody notificationBody({required Anniversary anniversary}) =>
      NotificationBody(
        l10n.notificationCleandayBody(
          anniversaryText(anniversary: anniversary).text,
        ),
      );

  NotificationChannelName get channel =>
      NotificationChannelName(l10n.notificationChannelCleanday);
}
