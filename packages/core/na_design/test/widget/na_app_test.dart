@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';

import '../support/static_router.dart';

Widget anApp({required Widget home}) => NaApp(
  title: 'NA Danmark',
  theme: NaThemeData.light(),
  routerConfig: aStaticRouter(home: home),
  localizationsDelegates: const [DefaultWidgetsLocalizations.delegate],
  supportedLocales: const [Locale('da'), Locale('en')],
  locale: const Locale('da'),
);

void main() {
  group('NaApp', () {
    testWidgets('renders the routed home under the theme', (tester) async {
      await tester.pumpWidget(anApp(home: const Text('home')));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(
        NaTheme.of(tester.element(find.text('home'))).colors.primary,
        NaColors.light.primary,
      );
    });

    testWidgets('applies the body text style by default', (tester) async {
      await tester.pumpWidget(anApp(home: const Text('styled')));
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.text('styled'));
      final style = DefaultTextStyle.of(
        tester.element(find.text('styled')),
      ).style;
      expect(text.data, 'styled');
      expect(style.fontSize, NaThemeData.light().typography.body.fontSize);
    });
  });
}
