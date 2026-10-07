extension type const CallCount(int value) {
  CallCount get next => CallCount(value + 1);

  CallCount operator +(CallCount other) => CallCount(value + other.value);
}

extension type const RowCount(int value) {}
