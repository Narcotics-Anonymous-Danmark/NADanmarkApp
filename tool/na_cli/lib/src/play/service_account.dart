import 'dart:convert';

import 'package:na_cli/src/boundary/google_wire.dart';
import 'package:na_cli/src/boundary/wire_json.dart';

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
    return switch (const WireJson().object(
      text: json,
      fromJson: ServiceAccountDto.fromJson,
    )) {
      WireDecoded(:final value) => _fromDto(value),
      WireRejected(:final reason) => ServiceAccountRejected(
        reason: 'service account JSON: $reason',
      ),
    };
  }

  static ServiceAccountParse _fromDto(final ServiceAccountDto dto) =>
      switch ((dto.clientEmail, dto.privateKey)) {
        (final String email, final String key)
            when email.isNotEmpty && key.isNotEmpty =>
          ServiceAccountParsed(
            account: ServiceAccount(clientEmail: email, privateKeyPem: key),
          ),
        _ => const ServiceAccountRejected(
          reason: 'service account needs client_email and private_key',
        ),
      };

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
