import 'package:flutter/widgets.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

extension MeetingTexts on AppLocalizations {
  String weekdayName({required Weekday weekday}) => switch (weekday) {
    Weekday.sunday => sunday,
    Weekday.monday => monday,
    Weekday.tuesday => tuesday,
    Weekday.wednesday => wednesday,
    Weekday.thursday => thursday,
    Weekday.friday => friday,
    Weekday.saturday => saturday,
  };

  String dayFilterName({required DayFilter day}) => switch (day) {
    AllDays() => weekdays,
    OnlyDay(:final weekday) => weekdayName(weekday: weekday),
  };

  String municipalityName({required Municipality municipality}) =>
      switch (municipality) {
        NamedMunicipality(:final name) => name.value,
        OnlineMunicipality() => municipalityOnline,
      };
}

Language languageOf({required BuildContext context}) =>
    Language.fromCode(code: Localizations.localeOf(context).languageCode);

NaChipTone toneOf({required FormatCategory category}) => switch (category) {
  FormatCategory.alert => NaChipTone.danger,
  FormatCategory.language => NaChipTone.language,
  FormatCategory.audience => NaChipTone.primary,
  FormatCategory.facility || FormatCategory.content => NaChipTone.dark,
};
