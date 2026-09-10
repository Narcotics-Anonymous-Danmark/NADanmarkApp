import 'package:meta/meta.dart';

@immutable
final class AppVersion {
  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    required this.build,
  });

  final int major;
  final int minor;
  final int patch;
  final int build;

  static const int codeBase = 1100000000;

  int get versionCode =>
      codeBase + (major * 10000 + minor * 100 + patch) * 1000 + build;

  String get semantic => '$major.$minor.$patch';

  String get tag => switch (build) {
    1 => semantic,
    _ => '$semantic-b$build',
  };

  @override
  int get hashCode => Object.hash(major, minor, patch, build);

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch &&
      other.build == build;

  @override
  String toString() => '$semantic+$versionCode';
}
