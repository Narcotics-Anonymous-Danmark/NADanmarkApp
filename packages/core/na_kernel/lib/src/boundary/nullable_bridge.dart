R bridgeNullable<T, R>({
  required T? value,
  required R Function(T value) whenPresent,
  required R Function() whenAbsent,
}) => switch (value) {
  null => whenAbsent(),
  final T present => whenPresent(present),
};
