import 'dart:convert';

import 'package:na_cli/src/boundary/google_wire.dart';
import 'package:na_cli/src/boundary/jwt_wire.dart';
import 'package:na_cli/src/boundary/wire_json.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/crypto/epoch_seconds.dart';
import 'package:na_cli/src/crypto/jwt.dart';
import 'package:na_cli/src/crypto/signing_key.dart';
import 'package:na_cli/src/http/http_call.dart';
import 'package:na_cli/src/http/http_reply.dart';
import 'package:na_cli/src/ports/http_transport.dart';

extension type const AccessToken(String value) {}

final class GoogleAccessToken {
  const GoogleAccessToken({required this.http, required this.jwt});

  final HttpTransport http;
  final Jwt jwt;

  static const String scope =
      'https://www.googleapis.com/auth/androidpublisher';
  static final Uri tokenUrl = Uri.parse('https://oauth2.googleapis.com/token');

  JwtClaimsDto claims({
    required final String clientEmail,
    required final DateTime now,
  }) {
    final issued = EpochSeconds.of(time: now);
    return JwtClaimsDto(
      iss: clientEmail,
      scope: scope,
      aud: tokenUrl.toString(),
      iat: issued.value,
      exp: issued.plus(duration: const Duration(hours: 1)).value,
    );
  }

  Future<AccessToken> fetch({
    required final SigningKey key,
    required final String clientEmail,
    required final DateTime now,
  }) async {
    final assertion = jwt.sign(
      key: key,
      hint: const NoKeyId(),
      claims: claims(clientEmail: clientEmail, now: now),
    );
    final reply = await http.send(
      call: HttpCall(
        method: HttpMethod.post,
        url: tokenUrl,
        headers: const {'content-type': 'application/x-www-form-urlencoded'},
        body: utf8.encode(
          'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer'
          '&assertion=${assertion.value}',
        ),
      ),
    );
    if (reply.status.outcome == HttpOutcome.failure) {
      throw CliFailure.general(
        message:
            'google token request failed (${reply.status.value}): '
            '${reply.body}',
      );
    }
    return switch (const WireJson().object(
      text: reply.body,
      fromJson: GoogleTokenDto.fromJson,
    )) {
      WireDecoded(value: GoogleTokenDto(accessToken: final String token))
          when token.isNotEmpty =>
        AccessToken(token),
      WireDecoded() => throw const CliFailure.general(
        message: 'google token response has no access_token',
      ),
      WireRejected(:final reason) => throw CliFailure.general(
        message: 'google token response: $reason',
      ),
    };
  }
}
