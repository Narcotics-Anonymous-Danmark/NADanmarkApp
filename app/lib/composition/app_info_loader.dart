import 'package:na_kernel/na_kernel.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String appEnvDefine = String.fromEnvironment(
  'APP_ENV',
  defaultValue: 'dev',
);

const String naApprovedDefine = String.fromEnvironment(
  'NA_APPROVED',
  defaultValue: 'false',
);

BuildApproval approvalFromDefines() =>
    naApprovedDefine == 'true' ? BuildApproval.approved : BuildApproval.trial;

Future<AppInfo> loadAppInfo() async {
  final package = await PackageInfo.fromPlatform();
  return AppInfo(
    version: VersionName(package.version),
    buildType: const BuildType(appEnvDefine),
    approval: approvalFromDefines(),
  );
}
