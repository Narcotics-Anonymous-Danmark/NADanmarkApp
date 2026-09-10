extension type const ExitCode(int value) {
  static const ExitCode success = ExitCode(0);
  static const ExitCode failure = ExitCode(1);
  static const ExitCode usage = ExitCode(64);
  static const ExitCode unavailable = ExitCode(127);
}
