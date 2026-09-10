import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';

extension type const Km(int value) {
  Km.clampedSearchRadius({required int value})
    : this(
        value < searchRadiusMinimum.value
            ? searchRadiusMinimum.value
            : value > searchRadiusMaximum.value
            ? searchRadiusMaximum.value
            : value,
      );

  static const Km searchRadiusMinimum = Km(5);
  static const Km searchRadiusMaximum = Km(50);
  static const Km searchRadiusFallback = Km(15);

  static Outcome<Km, DecodeFailure> parseSearchRadius({
    required String text,
  }) => switch (int.tryParse(text.trim())) {
    final int parsed
        when parsed >= searchRadiusMinimum.value &&
            parsed <= searchRadiusMaximum.value =>
      Ok(value: Km(parsed)),
    final int parsed => Err(
      error: DecodeFailure(detail: 'searchRange: $parsed is outside 5..50'),
    ),
    null => Err(
      error: DecodeFailure(detail: 'searchRange: "$text" is not an integer'),
    ),
  };

  String get code => value.toString();
}
