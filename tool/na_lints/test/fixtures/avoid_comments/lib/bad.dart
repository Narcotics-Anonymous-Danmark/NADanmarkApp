// Copyright 2026 NA Danmark. Licensed under the MIT license.

// expect_lint: avoid_comments
// A helper that does nothing.
void helper() {}

// expect_lint: avoid_comments
/// Documents [Thing].
final class Thing {
  // ignore: unused_element
  void _hidden() {}

  // expect_lint: avoid_comments
  /* a block comment */
  void visible() {}
}
