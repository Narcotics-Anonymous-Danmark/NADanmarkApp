import 'dart:math';

final class Gen {
  Gen({required this.seed}) : _random = Random(seed);

  factory Gen.fromEnvironment() {
    const seedText = String.fromEnvironment('NA_TEST_SEED');
    final seed = switch (int.tryParse(seedText)) {
      final int parsed => parsed,
      null => DateTime.now().millisecondsSinceEpoch % 1000000,
    };
    return Gen(seed: seed);
  }

  final int seed;
  final Random _random;

  int integer({required int min, required int max}) =>
      min + _random.nextInt(max - min + 1);

  double decimal({required double min, required double max}) =>
      min + _random.nextDouble() * (max - min);

  T pick<T>({required List<T> from}) => from[_random.nextInt(from.length)];

  String word({required int length}) => String.fromCharCodes(
    List.generate(length, (_) => 97 + _random.nextInt(26)),
  );

  String describe() => 'Gen(seed: $seed)';
}
