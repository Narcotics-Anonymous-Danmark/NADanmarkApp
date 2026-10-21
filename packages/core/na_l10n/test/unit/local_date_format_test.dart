@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

const LocalDate may3 = LocalDate(year: 2020, month: 5, day: 3);

void main() {
  test('formats dates in the app language', () {
    final danish = LocalDateFormat(language: Language.danish);
    final english = LocalDateFormat(language: Language.english);
    expect(
      danish.format(date: may3, pattern: DatePattern.dayShortMonthYear),
      const FormattedDate('03 maj 2020'),
    );
    expect(
      danish.format(date: may3, pattern: DatePattern.dayMonthYear),
      const FormattedDate('03. maj 2020'),
    );
    expect(
      english.format(
        date: const LocalDate(year: 2026, month: 9, day: 10),
        pattern: DatePattern.dayShortMonthYear,
      ),
      const FormattedDate('10 Sep 2026'),
    );
  });

  test('lists the month names of the language', () {
    expect(
      LocalDateFormat(language: Language.danish).monthNames.first,
      const FormattedDate('januar'),
    );
    expect(
      LocalDateFormat(language: Language.english).monthNames.last,
      const FormattedDate('December'),
    );
  });
}
