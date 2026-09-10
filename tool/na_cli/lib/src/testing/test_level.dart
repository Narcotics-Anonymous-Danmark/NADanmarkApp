import 'package:na_cli/src/cli_failure.dart';

enum TestLevel {
  unit,
  widget,
  acceptance,
  e2e
  ;

  static List<TestLevel> fromWords({required final List<String> words}) {
    if (words.isEmpty) {
      return const [TestLevel.unit];
    }
    if (words.contains('all')) {
      return TestLevel.values;
    }
    return List.unmodifiable(words.map(_single));
  }

  static TestLevel _single(final String word) {
    final matches = TestLevel.values.where((final level) => level.name == word);
    if (matches.isEmpty) {
      throw CliFailure.usage(
        message: 'unknown test level "$word" (unit|widget|acceptance|e2e|all)',
      );
    }
    return matches.first;
  }
}
