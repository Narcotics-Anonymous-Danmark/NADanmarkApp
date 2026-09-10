import 'dart:convert';

import 'package:na_cli/src/boundary/json_object.dart';

final class ServiceAccount {
  const ServiceAccount({
    required this.clientEmail,
    required this.privateKeyPem,
  });

  final String clientEmail;
  final String privateKeyPem;

  static ServiceAccountParse parse({required final String raw}) {
    final trimmed = raw.trim();
    final json = trimmed.startsWith('{') ? trimmed : _decodeBase64(trimmed);
    return switch (JsonObject.parse(text: json)) {
      JsonObjectParsed(:final object) => _fromObject(object),
      JsonListParsed() => const ServiceAccountRejected(
        reason: 'service account must be a JSON object',
      ),
      JsonMalformed(:final reason) => ServiceAccountRejected(
        reason: 'service account JSON: $reason',
      ),
    };
  }

  static ServiceAccountParse _fromObject(final JsonObject object) {
    final email = object.text(key: 'client_email').orElse(fallback: '');
    final key = object.text(key: 'private_key').orElse(fallback: '');
    if (email.isEmpty || key.isEmpty) {
      return const ServiceAccountRejected(
        reason: 'service account needs client_email and private_key',
      );
    }
    return ServiceAccountParsed(
      account: ServiceAccount(clientEmail: email, privateKeyPem: key),
    );
  }

  static String _decodeBase64(final String text) {
    try {
      return utf8.decode(base64Decode(text.replaceAll(RegExp(r'\s'), '')));
    } on FormatException {
      return '';
    }
  }
}

sealed class ServiceAccountParse {
  const ServiceAccountParse();
}

final class ServiceAccountParsed extends ServiceAccountParse {
  const ServiceAccountParsed({required this.account});

  final ServiceAccount account;
}

final class ServiceAccountRejected extends ServiceAccountParse {
  const ServiceAccountRejected({required this.reason});

  final String reason;
}
