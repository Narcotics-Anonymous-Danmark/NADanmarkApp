void greet({final String name = 'world', final int times = 1}) {}

final class Config {
  const Config([this.retries = 3]);

  final int retries;
}
