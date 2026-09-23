@Tags(['widget'])
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';

const popover = Key('popover');
const close = Key('popover-close');

Future<void> pumpOpener(WidgetTester tester) async {
  await tester.pumpWidget(
    NaTheme(
      data: NaThemeData.light(),
      child: WidgetsApp(
        color: const Color(0xFF000000),
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => Center(
            child: NaButton(
              label: 'Open',
              onPressed: () => showNaPopover(
                context: context,
                popoverKey: popover,
                closeKey: close,
                title: 'Mødeformater',
                closeLabel: 'Luk',
                child: const Text('Åben Møde'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

Future<void> pressSystemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(
      const MethodCall('popRoute'),
    ),
    (data) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows its title and content within the size limits', (
    tester,
  ) async {
    await pumpOpener(tester);
    expect(find.text('Mødeformater'), findsOneWidget);
    expect(find.text('Åben Møde'), findsOneWidget);
    final size = tester.getSize(
      find
          .descendant(
            of: find.byKey(popover),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(size.width, lessThanOrEqualTo(NaPopover.maxWidth));
    expect(size.height, lessThanOrEqualTo(screen.height * 0.7));
  });

  testWidgets('closes on the close button', (tester) async {
    await pumpOpener(tester);
    await tester.tap(find.byKey(close));
    await tester.pumpAndSettle();
    expect(find.byKey(popover), findsNothing);
  });

  testWidgets('closes on the barrier', (tester) async {
    await pumpOpener(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(popover), findsNothing);
  });

  testWidgets('closes on system back', (tester) async {
    await pumpOpener(tester);
    await pressSystemBack(tester);
    expect(find.byKey(popover), findsNothing);
    expect(find.text('OPEN'), findsOneWidget);
  });

  testWidgets('the close button is labelled for assistive technology', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpOpener(tester);
    expect(
      tester.getSemantics(find.byKey(close)),
      matchesSemantics(label: 'Luk', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });
}
