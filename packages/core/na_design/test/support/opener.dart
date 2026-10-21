import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';

final class ResultLog<R> {
  final List<R> results = [];
}

Future<ResultLog<R>> pumpOpener<R>({
  required WidgetTester tester,
  required Future<R> Function(BuildContext context) open,
}) async {
  final log = ResultLog<R>();
  await tester.pumpWidget(
    NaTheme(
      data: NaThemeData.light(),
      child: WidgetsApp(
        color: const Color(0xFF000000),
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => Center(
            child: GestureDetector(
              key: const Key('open'),
              behavior: HitTestBehavior.opaque,
              onTap: () async => log.results.add(await open(context)),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  return log;
}

Future<void> tapKey(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}
