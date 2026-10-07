import 'dart:convert';

import 'package:na_cli/src/boundary/jwt_wire.dart';
import 'package:na_cli/src/boundary/wire_json.dart';
import 'package:na_cli/src/crypto/jwt_signer.dart';
import 'package:na_cli/src/crypto/signing_key.dart';

extension type const SignedJwt(String value) {}

sealed class JwtKeyHint {
  const JwtKeyHint();
}

final class NoKeyId extends JwtKeyHint {
  const NoKeyId();
}

final class KeyId extends JwtKeyHint {
  const KeyId({required this.value});

  final String value;
}

final class Jwt {
  const Jwt({required this.signer});

  final JwtSigner signer;

  SignedJwt sign({
    required final SigningKey key,
    required final JwtKeyHint hint,
    required final JwtClaimsDto claims,
  }) {
    final algorithm = switch (key) {
      RsaSigningKey() => 'RS256',
      EcP256SigningKey() => 'ES256',
    };
    final encodedHeader = _segment(
      switch (hint) {
        NoKeyId() => JwtHeaderDto(alg: algorithm, typ: 'JWT'),
        KeyId(:final value) => JwtHeaderDto(
          alg: algorithm,
          typ: 'JWT',
          kid: value,
        ),
      }.toJson(),
    );
    final encodedClaims = _segment(claims.toJson());
    final signingInput = '$encodedHeader.$encodedClaims';
    final signature = signer.sign(
      key: key,
      message: utf8.encode(signingInput),
    );
    return SignedJwt('$signingInput.${_base64Url(signature)}');
  }

  String _segment(final WireObject json) =>
      _base64Url(utf8.encode(const WireJson().encode(json: json)));

  String _base64Url(final List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
