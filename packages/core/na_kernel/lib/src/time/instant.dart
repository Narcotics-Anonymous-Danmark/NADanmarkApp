extension type const Instant(DateTime utc) {
  Instant plus({required Duration duration}) => Instant(utc.add(duration));

  Duration since({required Instant other}) => utc.difference(other.utc);

  Comparison compareTo({required Instant other}) => switch (utc.compareTo(
    other.utc,
  )) {
    < 0 => Comparison.before,
    0 => Comparison.same,
    _ => Comparison.after,
  };

  int get epochMilliseconds => utc.millisecondsSinceEpoch;
}

enum Comparison { before, same, after }
