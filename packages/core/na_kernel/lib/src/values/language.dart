import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';

enum Language {
  danish(code: 'da'),
  english(code: 'en')
  ;

  const Language({required this.code});

  final String code;

  static const Language fallback = Language.danish;

  static Language fromCode({required String code}) => values.firstWhere(
    (language) => language.code == code,
    orElse: () => fallback,
  );

  static Outcome<Language, DecodeFailure> parse({required String code}) {
    final matches = values.where((language) => language.code == code);
    return matches.isEmpty
        ? Err(error: DecodeFailure(detail: 'language: unknown code "$code"'))
        : Ok(value: matches.first);
  }
}
