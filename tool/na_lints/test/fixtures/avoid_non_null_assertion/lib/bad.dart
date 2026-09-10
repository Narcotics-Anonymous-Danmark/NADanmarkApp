String shout({required final String? word}) {
  // expect_lint: avoid_non_null_assertion
  return word!.toUpperCase();
}

int firstLength({required final List<String?> words}) {
  // expect_lint: avoid_non_null_assertion
  final first = words.first!;
  return first.length;
}
