import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';
import 'package:na_testing/src/container/test_container.dart';

Future<void> pumpFeature({
  required WidgetTester tester,
  required TestContainer harness,
  required Widget child,
  Language language = Language.danish,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: NaTheme(
        data: NaThemeData.light(),
        child: WidgetsApp(
          color: NaColors.light.primary,
          locale: language.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: supportedLocales,
          onGenerateRoute: (settings) => PageRouteBuilder<void>(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
