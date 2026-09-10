import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';

enum DanishMonth {
  januar(number: 1),
  februar(number: 2),
  marts(number: 3),
  april(number: 4),
  maj(number: 5),
  juni(number: 6),
  juli(number: 7),
  august(number: 8),
  september(number: 9),
  oktober(number: 10),
  november(number: 11),
  december(number: 12)
  ;

  const DanishMonth({required this.number});

  final int number;

  static DanishMonth ofNumber({required int number}) =>
      values.singleWhere((month) => month.number == number);

  static Outcome<DanishMonth, DecodeFailure> parse({required String name}) {
    final matches = values.where((month) => month.name == name);
    return matches.isEmpty
        ? Err(error: DecodeFailure(detail: 'month: unknown name "$name"'))
        : Ok(value: matches.first);
  }

  int get daysInLeapYear => switch (this) {
    DanishMonth.februar => 29,
    DanishMonth.april ||
    DanishMonth.juni ||
    DanishMonth.september ||
    DanishMonth.november => 30,
    DanishMonth.januar ||
    DanishMonth.marts ||
    DanishMonth.maj ||
    DanishMonth.juli ||
    DanishMonth.august ||
    DanishMonth.oktober ||
    DanishMonth.december => 31,
  };
}
