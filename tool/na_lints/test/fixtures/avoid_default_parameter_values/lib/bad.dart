void greet({
  // expect_lint: avoid_default_parameter_values
  final String name = 'world',
  // expect_lint: avoid_default_parameter_values
  final int times = 1,
}) {}

final class Config {
  const Config([
    // expect_lint: avoid_default_parameter_values
    this.retries = 3,
  ]);

  final int retries;
}
