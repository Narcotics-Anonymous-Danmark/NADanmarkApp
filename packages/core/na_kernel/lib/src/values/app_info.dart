import 'package:meta/meta.dart';

enum BuildApproval { approved, trial }

extension type const BuildType(String value) {}

@immutable
final class AppInfo {
  const AppInfo({
    required this.version,
    required this.buildType,
    required this.approval,
  });

  final String version;
  final BuildType buildType;
  final BuildApproval approval;

  @override
  int get hashCode => Object.hash(version, buildType, approval);

  @override
  bool operator ==(Object other) =>
      other is AppInfo &&
      other.version == version &&
      other.buildType == buildType &&
      other.approval == approval;

  @override
  String toString() => 'AppInfo($version, ${buildType.value}, $approval)';
}
