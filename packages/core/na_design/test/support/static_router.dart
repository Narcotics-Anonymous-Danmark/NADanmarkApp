import 'package:flutter/widgets.dart';

RouterConfig<Object> aStaticRouter({required Widget home}) => RouterConfig(
  routerDelegate: _StaticRouterDelegate(home: home),
  routeInformationParser: const _StaticParser(),
  routeInformationProvider: PlatformRouteInformationProvider(
    initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
  ),
);

final class _StaticParser extends RouteInformationParser<Object> {
  const _StaticParser();

  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) =>
      Future.value(routeInformation.uri);
}

final class _StaticRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier {
  _StaticRouterDelegate({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) => home;

  @override
  Future<bool> popRoute() => Future.value(false);

  @override
  Future<void> setNewRoutePath(Object configuration) => Future.value();
}
