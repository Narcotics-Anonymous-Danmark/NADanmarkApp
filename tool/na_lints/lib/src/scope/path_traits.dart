enum PathTrait {
  lib(markers: ['/lib/']),
  generated(markers: ['/generated/', '.g.dart']),
  boundary(
    markers: [
      '/packages/adapters/',
      '/na_kernel/lib/src/boundary/',
      '/na_design/lib/src/flutter_bridge/',
      '/tool/na_cli/lib/src/boundary/',
      '/tool/na_lints/lib/src/boundary/',
    ],
  ),
  designFlutterBridge(markers: ['/na_design/lib/src/flutter_bridge/']),
  flutterBridge(markers: ['/flutter_bridge/']),
  boundaryFolder(markers: ['/boundary/']),
  clockAdapter(markers: ['/adapter_clock/']),
  testing(markers: ['/na_testing/'])
  ;

  const PathTrait({required this.markers});

  final List<String> markers;
}

Set<PathTrait> pathTraitsOf({required final String path}) {
  final normalised = '/${path.replaceAll(r'\', '/')}';
  return Set.unmodifiable(
    PathTrait.values.where(
      (final trait) => trait.markers.any(normalised.contains),
    ),
  );
}
