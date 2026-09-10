@Tags(['acceptance'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  group('Requirement: Supported languages and default', () {
    testWidgets('Device locale does not override the default', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      expect(find.text('Narcotics Anonymous Danmark'), findsOneWidget);
    });
  });

  group('Requirement: Immediate switch', () {
    testWidgets('Live switch on Settings', (tester) async {
      final app = await pumpApp(tester: tester, initialLocation: '/settings');
      addTearDown(app.dispose);
      await chooseOption(
        tester: tester,
        row: const Key('settings-language'),
        option: 'Engelsk',
      );
      expect(pageText('Settings'), findsOneWidget);
      expect(pageText('First day of week'), findsOneWidget);
      await openMenu(tester);
      expect(inMenu(find.text('Just for today')), findsOneWidget);
    });
  });
}
