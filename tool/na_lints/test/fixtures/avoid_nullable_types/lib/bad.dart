final class Holder {
  const Holder({required this.value, required this.onDone});

  // expect_lint: avoid_nullable_types
  final String? value;

  // expect_lint: avoid_nullable_types
  final void Function()? onDone;
}

// expect_lint: avoid_nullable_types
int? parse({required final String raw}) => int.tryParse(raw);

// expect_lint: avoid_nullable_types
void store({required final List<String?> items}) {}

// expect_lint: avoid_nullable_types
(int, String)? pair() => null;
