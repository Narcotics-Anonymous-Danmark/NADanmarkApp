import 'dart:math';

import 'package:na_cli/src/ports/secret_generator.dart';

final class SecureSecretGenerator implements SecretGenerator {
  const SecureSecretGenerator();

  @override
  String randomToken({required final int bytes}) {
    final random = Random.secure();
    return List.generate(
      bytes,
      (final _) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
