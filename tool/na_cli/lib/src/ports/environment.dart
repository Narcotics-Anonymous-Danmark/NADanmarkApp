import 'package:na_cli/src/host/env_value.dart';

extension type const EnvKey(String value) {}

abstract interface class Environment {
  EnvValue lookup({required EnvKey key});
}
