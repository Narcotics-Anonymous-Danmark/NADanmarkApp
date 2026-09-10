sealed class SigningKey {
  const SigningKey();
}

final class RsaSigningKey extends SigningKey {
  const RsaSigningKey({
    required this.modulus,
    required this.privateExponent,
    required this.p,
    required this.q,
  });

  final BigInt modulus;
  final BigInt privateExponent;
  final BigInt p;
  final BigInt q;
}

final class EcP256SigningKey extends SigningKey {
  const EcP256SigningKey({required this.d});

  final BigInt d;
}

sealed class SigningKeyParse {
  const SigningKeyParse();
}

final class SigningKeyParsed extends SigningKeyParse {
  const SigningKeyParsed({required this.key});

  final SigningKey key;
}

final class SigningKeyRejected extends SigningKeyParse {
  const SigningKeyRejected({required this.reason});

  final String reason;
}
