import 'dart:convert';

import 'package:na_kernel/na_kernel.dart';

extension type const WordPressBaseUrl(String value) {}

extension type const BasicCredentials(String userAndPassword) {}

sealed class WordPressCredentials {
  const WordPressCredentials();

  factory WordPressCredentials.of({required BasicCredentials credentials}) =>
      credentials.userAndPassword.trim().isEmpty
      ? const NoCredentials()
      : BasicAuth(credentials: credentials);

  Map<String, String> get headers => switch (this) {
    BasicAuth(:final credentials) => {
      'Authorization':
          'Basic ${base64.encode(utf8.encode(credentials.userAndPassword))}',
    },
    NoCredentials() => const {},
  };
}

final class BasicAuth extends WordPressCredentials {
  const BasicAuth({required this.credentials});

  final BasicCredentials credentials;
}

final class NoCredentials extends WordPressCredentials {
  const NoCredentials();
}

final class WordPressEndpoints {
  const WordPressEndpoints({required this.base, required this.credentials});

  final WordPressBaseUrl base;
  final WordPressCredentials credentials;

  String speaks({required SpeakLanguage language}) =>
      '${_trimmed(base: base)}/wp-json/wp/v2/speaks'
      '?excerpt[]=${language.excerpt.value}';

  static String _trimmed({required WordPressBaseUrl base}) =>
      base.value.endsWith('/')
      ? base.value.substring(0, base.value.length - 1)
      : base.value;
}
