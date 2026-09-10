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
      late Color primary;
      await tester.pumpWidget(
        anApp(
          home: Builder(
            builder: (context) {
              primary = NaTheme.of(context).colors.primary;
              return const Text('home');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(primary, NaColors.light.primary);
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
