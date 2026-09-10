sealed class KeyAlias {
  const KeyAlias();

  String get value => switch (this) {
    ProvidedAlias(:final alias) => alias,
    ConventionalAlias() => 'nadanmarkapp',
  };
}

final class ProvidedAlias extends KeyAlias {
  const ProvidedAlias({required this.alias});

  final String alias;
}

final class ConventionalAlias extends KeyAlias {
  const ConventionalAlias();
}
