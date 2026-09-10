import 'package:na_cli/src/workspace/workspace_member.dart';

enum PackageLayer {
  kernel,
  ports,
  design,
  l10n,
  testing,
  feature,
  adapter,
  app,
  tool
  ;

  static PackageLayer of({required final PackageName name}) {
    if (name.value == 'na_kernel') {
      return PackageLayer.kernel;
    }
    if (name.value == 'na_ports') {
      return PackageLayer.ports;
    }
    if (name.value == 'na_design') {
      return PackageLayer.design;
    }
    if (name.value == 'na_l10n') {
      return PackageLayer.l10n;
    }
    if (name.value == 'na_testing') {
      return PackageLayer.testing;
    }
    if (name.value == 'na_app') {
      return PackageLayer.app;
    }
    if (name.value.startsWith('feature_')) {
      return PackageLayer.feature;
    }
    if (name.value.startsWith('adapter_')) {
      return PackageLayer.adapter;
    }
    return PackageLayer.tool;
  }
}
