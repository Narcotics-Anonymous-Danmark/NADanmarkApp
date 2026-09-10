import 'package:na_cli/src/crypto/signing_key.dart';

abstract interface class JwtSigner {
  List<int> sign({required SigningKey key, required List<int> message});
}
