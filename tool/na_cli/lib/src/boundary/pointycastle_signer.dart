import 'dart:typed_data';

import 'package:na_cli/src/crypto/jwt_signer.dart';
import 'package:na_cli/src/crypto/signing_key.dart';
import 'package:pointycastle/export.dart';

final class PointycastleSigner implements JwtSigner {
  const PointycastleSigner();

  @override
  List<int> sign({
    required final SigningKey key,
    required final List<int> message,
  }) => switch (key) {
    RsaSigningKey() => _rs256(key: key, message: message),
    EcP256SigningKey() => _es256(key: key, message: message),
  };

  List<int> _rs256({
    required final RsaSigningKey key,
    required final List<int> message,
  }) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
      ..init(
        true,
        PrivateKeyParameter<RSAPrivateKey>(
          RSAPrivateKey(key.modulus, key.privateExponent, key.p, key.q),
        ),
      );
    return signer.generateSignature(Uint8List.fromList(message)).bytes;
  }

  List<int> _es256({
    required final EcP256SigningKey key,
    required final List<int> message,
  }) {
    final curve = ECCurve_secp256r1();
    final signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64))
      ..init(
        true,
        PrivateKeyParameter<ECPrivateKey>(ECPrivateKey(key.d, curve)),
      );
    final signature =
        signer.generateSignature(Uint8List.fromList(message)) as ECSignature;
    return [..._fixed32(signature.r), ..._fixed32(signature.s)];
  }

  List<int> _fixed32(final BigInt value) {
    final hex = value.toRadixString(16).padLeft(64, '0');
    return List.generate(
      32,
      (final i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    );
  }
}
