import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/app/na_danmark_app.dart';
import 'package:na_app/app/na_router.dart';
import 'package:na_app/composition/app_startup.dart';
import 'package:na_app/composition/production_overrides.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer(overrides: await productionOverrides());
  await AppStartup(container: container).run();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: NaDanmarkApp(router: createRouter(initialLocation: homePath)),
    ),
  );
}
