import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';

enum CleanTimeUnitOrder {
  yearsMonthsDays(code: 'ymd'),
  daysMonthsYears(code: 'dmy')
  ;

  const CleanTimeUnitOrder({required this.code});

  final String code;

  static const CleanTimeUnitOrder fallback = CleanTimeUnitOrder.yearsMonthsDays;

  static Outcome<CleanTimeUnitOrder, DecodeFailure> parse({
    required String code,
  }) {
    final matches = values.where((order) => order.code == code);
    return matches.isEmpty
        ? Err(
            error: DecodeFailure(
              detail: 'cleanTimeUnitSort: unknown code "$code"',
            ),
          )
        : Ok(value: matches.first);
  }
}
