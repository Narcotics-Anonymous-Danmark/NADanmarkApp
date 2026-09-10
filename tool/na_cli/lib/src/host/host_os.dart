enum HostOs {
  linux,
  macos
  ;

  String get androidToolsSuffix => switch (this) {
    HostOs.linux => 'linux',
    HostOs.macos => 'mac',
  };
}
