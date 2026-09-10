import 'dart:io';

import 'package:na_cli/src/host/env_value.dart';
import 'package:na_cli/src/ports/environment.dart';

final class IoEnvironment implements Environment {
  const IoEnvironment();

  @override
  EnvValue lookup({required final EnvKey key}) {
    final value = Platform.environment[key.value];
    if (value == null || value.isEmpty) {
      return EnvUnset(key: key);
    }
    return EnvSet(value: value);
  }
}
