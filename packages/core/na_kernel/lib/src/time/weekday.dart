import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';

enum Weekday {
  sunday(bmltTinyint: 1, isoNumber: 7),
  monday(bmltTinyint: 2, isoNumber: 1),
  tuesday(bmltTinyint: 3, isoNumber: 2),
  wednesday(bmltTinyint: 4, isoNumber: 3),
  thursday(bmltTinyint: 5, isoNumber: 4),
  friday(bmltTinyint: 6, isoNumber: 5),
  saturday(bmltTinyint: 7, isoNumber: 6)
  ;

  const Weekday({required this.bmltTinyint, required this.isoNumber});

  final int bmltTinyint;
  final int isoNumber;

  static Weekday fromIsoNumber({required int isoNumber}) =>
      values.singleWhere((day) => day.isoNumber == isoNumber);

  static List<Weekday> orderedFrom({required FirstDayOfWeek firstDay}) =>
      switch (firstDay) {
        FirstDayOfWeek.sunday => List.unmodifiable(values),
        FirstDayOfWeek.monday => List.unmodifiable([
          ...values.skip(1),
          Weekday.sunday,
        ]),
      };
}

enum FirstDayOfWeek {
  monday(code: 'mo'),
  sunday(code: 'su')
  ;

  const FirstDayOfWeek({required this.code});

  final String code;

  static const FirstDayOfWeek fallback = FirstDayOfWeek.monday;

  static Outcome<FirstDayOfWeek, DecodeFailure> parse({required String code}) {
    final matches = values.where((day) => day.code == code);
    return matches.isEmpty
        ? Err(
            error: DecodeFailure(detail: 'firstday: unknown code "$code"'),
          )
        : Ok(value: matches.first);
  }
}
