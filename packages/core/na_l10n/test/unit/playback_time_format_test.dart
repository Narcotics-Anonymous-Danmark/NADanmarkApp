@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:na_l10n/na_l10n.dart';

const PlaybackTimeFormat format = PlaybackTimeFormat();

String formatted(Duration duration) => format.format(duration: duration).text;

void main() {
  test('times read m:ss below an hour and h:mm:ss from an hour', () {
    expect(formatted(Duration.zero), '0:00');
    expect(formatted(const Duration(seconds: 65)), '1:05');
    expect(formatted(const Duration(seconds: 535)), '8:55');
    expect(formatted(const Duration(minutes: 59, seconds: 59)), '59:59');
    expect(formatted(const Duration(seconds: 3723)), '1:02:03');
    expect(formatted(const Duration(seconds: 50038)), '13:53:58');
  });

  test('fractions are floored and negative times read zero', () {
    expect(formatted(const Duration(milliseconds: 1999)), '0:01');
    expect(formatted(const Duration(seconds: -4)), '0:00');
  });
}
