import 'dart:ui';

import 'package:na_kernel/na_kernel.dart';

extension LanguageLocale on Language {
  Locale get locale => Locale(code);
}

final List<Locale> supportedLocales = List.unmodifiable(
  Language.values.map((language) => language.locale),
);
