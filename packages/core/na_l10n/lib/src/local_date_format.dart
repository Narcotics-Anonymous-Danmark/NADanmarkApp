import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:na_kernel/na_kernel.dart';

extension type const DatePattern(String skeleton) {
  static const DatePattern dayShortMonthYear = DatePattern('dd MMM yyyy');
  static const DatePattern dayMonthYear = DatePattern('dd. MMMM yyyy');
}

extension type const FormattedDate(String text) {}

final class LocalDateFormat {
  LocalDateFormat({required this.language}) {
    unawaited(initializeDateFormatting());
  }

  final Language language;

  FormattedDate format({
    required LocalDate date,
    required DatePattern pattern,
  }) => FormattedDate(
    DateFormat(pattern.skeleton, language.code).format(date.atMidnightUtc),
  );

  List<FormattedDate> get monthNames => List.unmodifiable(
    List.generate(
      12,
      (index) => FormattedDate(
        DateFormat.MMMM(language.code).format(DateTime.utc(2000, index + 1)),
      ),
    ),
  );
}
