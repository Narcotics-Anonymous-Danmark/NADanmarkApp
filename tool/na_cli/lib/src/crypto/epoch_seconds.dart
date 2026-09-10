extension type const EpochSeconds(int value) {
  EpochSeconds.of({required final DateTime time})
    : this(time.millisecondsSinceEpoch ~/ 1000);

  EpochSeconds plus({required Duration duration}) =>
      EpochSeconds(value + duration.inSeconds);
}
