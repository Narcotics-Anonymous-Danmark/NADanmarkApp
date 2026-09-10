@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

void main() {
  group('Weekday', () {
    test('maps BMLT tinyint 1 to Sunday', () {
      expect(Weekday.sunday.bmltTinyint, 1);
      expect(Weekday.saturday.bmltTinyint, 7);
    });

    test('orders Monday first when requested', () {
      expect(
        Weekday.orderedFrom(firstDay: FirstDayOfWeek.monday).first,
        Weekday.monday,
      );
      expect(
        Weekday.orderedFrom(firstDay: FirstDayOfWeek.monday).last,
        Weekday.sunday,
      );
    });

    test('keeps Sunday first when requested', () {
      expect(
        Weekday.orderedFrom(firstDay: FirstDayOfWeek.sunday).first,
        Weekday.sunday,
      );
    });
  });
}
