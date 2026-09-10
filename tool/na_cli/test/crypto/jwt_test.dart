@Tags(['unit'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:na_cli/src/boundary/pkcs8_key_reader.dart';
import 'package:na_cli/src/boundary/pointycastle_signer.dart';
import 'package:na_cli/src/crypto/jwt.dart';
import 'package:na_cli/src/crypto/pem_normaliser.dart';
import 'package:na_cli/src/crypto/signing_key.dart';
import 'package:pointycastle/export.dart';
import 'package:test/test.dart';

import '../support/test_keys.dart';

void main() {
  const jwt = Jwt(signer: PointycastleSigner());

  SigningKey keyOf(final String pem) =>
      (const Pkcs8KeyReader().read(
                pem: (const PemNormaliser().normalise(raw: pem) as PemAccepted)
                    .document,
              )
              as SigningKeyParsed)
          .key;

  Map<String, Object?> segment(final String token, final int index) =>
      jsonDecode(
            utf8.decode(
              base64Url.decode(base64Url.normalize(token.split('.')[index])),
            ),
          )
          as Map<String, Object?>;

  Uint8List signingInput(final String token) {
    final parts = token.split('.');
    return Uint8List.fromList(utf8.encode('${parts[0]}.${parts[1]}'));
  }

  Uint8List signature(final String token) =>
      base64Url.decode(base64Url.normalize(token.split('.')[2]));

  test('parses RSA and EC keys from PKCS#8 and SEC1 PEM', () {
    expect(keyOf(rsaPkcs8Pem), isA<RsaSigningKey>());
    expect(keyOf(ecSec1Pem), isA<EcP256SigningKey>());
    expect(keyOf(ecPkcs8Pem), isA<EcP256SigningKey>());
    expect(
      (keyOf(ecSec1Pem) as EcP256SigningKey).d,
      (keyOf(ecPkcs8Pem) as EcP256SigningKey).d,
    );
  });

  test('RS256 token verifies with the public key', () {
    final key = keyOf(rsaPkcs8Pem) as RsaSigningKey;
    final token = jwt.sign(
      key: key,
      header: const {},
      claims: const {'iss': 'ci', 'aud': 'x'},
    );
    expect(segment(token.value, 0), {'alg': 'RS256', 'typ': 'JWT'});
    expect(segment(token.value, 1)['iss'], 'ci');
    final verifier = RSASigner(SHA256Digest(), '0609608648016503040201')
      ..init(
        false,
        PublicKeyParameter<RSAPublicKey>(
          RSAPublicKey(key.modulus, BigInt.from(65537)),
        ),
      );
    expect(
      verifier.verifySignature(
        signingInput(token.value),
        RSASignature(signature(token.value)),
      ),
      isTrue,
    );
  });

  test('ES256 token has a 64 byte P1363 signature that verifies', () {
    final key = keyOf(ecPkcs8Pem) as EcP256SigningKey;
    final token = jwt.sign(
      key: key,
      header: const {'kid': 'KEY1'},
      claims: const {'aud': 'appstoreconnect-v1'},
    );
    expect(segment(token.value, 0), {
      'alg': 'ES256',
      'typ': 'JWT',
      'kid': 'KEY1',
    });
    final bytes = signature(token.value);
    expect(bytes, hasLength(64));
    final curve = ECCurve_secp256r1();
    final publicPoint = curve.G * key.d;
    final verifier = ECDSASigner(SHA256Digest())
      ..init(
        false,
        PublicKeyParameter<ECPublicKey>(ECPublicKey(publicPoint, curve)),
      );
    BigInt unsigned(final List<int> part) => part.fold(
      BigInt.zero,
      (final acc, final b) => (acc << 8) | BigInt.from(b),
    );
    expect(
      verifier.verifySignature(
        signingInput(token.value),
        ECSignature(
          unsigned(bytes.sublist(0, 32)),
          unsigned(bytes.sublist(32)),
        ),
      ),
      isTrue,
    );
  });

  test('rejects a PEM whose body is not a key', () {
    final bogus = PemDocument(
      kind: PemKind.privateKey,
      base64Body: base64Encode([1, 2, 3]),
    );
    expect(const Pkcs8KeyReader().read(pem: bogus), isA<SigningKeyRejected>());
  });
}
