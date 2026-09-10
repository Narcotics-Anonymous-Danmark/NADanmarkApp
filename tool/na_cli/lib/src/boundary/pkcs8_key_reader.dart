import 'dart:typed_data';

import 'package:na_cli/src/crypto/pem_normaliser.dart';
import 'package:na_cli/src/crypto/signing_key.dart';
import 'package:pointycastle/asn1.dart';

final class Pkcs8KeyReader {
  const Pkcs8KeyReader();

  SigningKeyParse read({required final PemDocument pem}) {
    try {
      final bytes = Uint8List.fromList(pem.derBytes);
      return switch (pem.kind) {
        PemKind.rsaPrivateKey => _rsa(_sequence(bytes)),
        PemKind.ecPrivateKey => _ec(_sequence(bytes)),
        PemKind.privateKey => _pkcs8(_sequence(bytes)),
      };
    } on Object catch (error) {
      return SigningKeyRejected(reason: 'cannot parse private key: $error');
    }
  }

  SigningKeyParse _pkcs8(final List<ASN1Object> info) {
    final algorithm = _elements(info[1]);
    final oid = algorithm.first;
    final inner = info[2];
    final innerBytes = inner is ASN1OctetString
        ? inner.valueBytes ?? Uint8List(0)
        : Uint8List(0);
    if (oid is ASN1ObjectIdentifier &&
        oid.objectIdentifierAsString == '1.2.840.113549.1.1.1') {
      return _rsa(_sequence(innerBytes));
    }
    return _ec(_sequence(innerBytes));
  }

  SigningKeyParse _rsa(final List<ASN1Object> key) => SigningKeyParsed(
    key: RsaSigningKey(
      modulus: _integer(key[1]),
      privateExponent: _integer(key[3]),
      p: _integer(key[4]),
      q: _integer(key[5]),
    ),
  );

  SigningKeyParse _ec(final List<ASN1Object> key) {
    final scalar = key[1];
    final bytes = scalar is ASN1OctetString
        ? scalar.valueBytes ?? Uint8List(0)
        : Uint8List(0);
    if (bytes.isEmpty) {
      return const SigningKeyRejected(reason: 'EC key has no private scalar');
    }
    return SigningKeyParsed(
      key: EcP256SigningKey(
        d: bytes.fold(
          BigInt.zero,
          (final acc, final b) => (acc << 8) | BigInt.from(b),
        ),
      ),
    );
  }

  List<ASN1Object> _sequence(final Uint8List bytes) =>
      _elements(ASN1Parser(bytes).nextObject());

  List<ASN1Object> _elements(final ASN1Object object) =>
      object is ASN1Sequence ? object.elements ?? const [] : const [];

  BigInt _integer(final ASN1Object object) =>
      object is ASN1Integer ? object.integer ?? BigInt.zero : BigInt.zero;
}
