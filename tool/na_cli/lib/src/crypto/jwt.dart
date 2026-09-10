import 'dart:convert';

import 'package:na_cli/src/crypto/jwt_signer.dart';
import 'package:na_cli/src/crypto/signing_key.dart';

extension type const SignedJwt(String value) {}

final class Jwt {
  const Jwt({required this.signer});

  final JwtSigner signer;

  SignedJwt sign({
    required final SigningKey key,
    required final Map<String, Object> header,
    required final Map<String, Object> claims,
  }) {
    final algorithm = switch (key) {
      RsaSigningKey() => 'RS256',
      EcP256SigningKey() => 'ES256',
    };
    final encodedHeader = _segment({'alg': algorithm, 'typ': 'JWT', ...header});
    final encodedClaims = _segment(claims);
    final signingInput = '$encodedHeader.$encodedClaims';
    final signature = signer.sign(
      key: key,
      message: utf8.encode(signingInput),
    );
    return SignedJwt('$signingInput.${_base64Url(signature)}');
  }

  String _segment(final Map<String, Object> json) =>
      _base64Url(utf8.encode(jsonEncode(json)));

  String _base64Url(final List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
