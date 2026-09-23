@Tags(['widget'])
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';

const notchedInsets = EdgeInsets.fromLTRB(44, 47, 30, 34);

Widget onNotchedDevice(Widget child) => NaTheme(
  data: NaThemeData.light(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(
        size: Size(800, 600),
        padding: notchedInsets,
        viewPadding: notchedInsets,
      ),
      child: child,
    ),
  ),
);

void main() {
  testWidgets('the header clears the status bar and the body clears the '
      'cutouts and the home indicator', (tester) async {
    await tester.pumpWidget(
      onNotchedDevice(
        const NaPageFrame(
          header: NaHeaderBar(
            leading: NaHeaderSpacer(),
            title: 'Hjem',
            trailing: NaHeaderSpacer(),
          ),
          body: NaScrollBody(
            children: [SizedBox(key: Key('content'), height: 10)],
          ),
          bottomInset: 0,
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(NaHeaderBar)).height,
      notchedInsets.top + NaHeaderBar.height,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('content'))),
      Offset(notchedInsets.left, notchedInsets.top + NaHeaderBar.height),
    );
    expect(
      tester.widget<ListView>(find.byType(ListView)).padding,
      EdgeInsets.only(
        left: notchedInsets.left,
        right: notchedInsets.right,
        bottom: notchedInsets.bottom,
      ),
    );
  });

  testWidgets('the status bar is black with light icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      onNotchedDevice(
        const NaHeaderBar(
          leading: NaHeaderSpacer(),
          title: 'Hjem',
          trailing: NaHeaderSpacer(),
        ),
      ),
    );
    final style = tester
        .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        )
        .value;
    expect(style.statusBarColor, const Color(0xFF000000));
    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.statusBarBrightness, Brightness.dark);
    expect(
      tester
          .widget<ColoredBox>(
            find.descendant(
              of: find.byType(NaHeaderBar),
              matching: find.byType(ColoredBox),
            ),
          )
          .color,
      const Color(0xFF000000),
    );
  });

  testWidgets('the side menu footer scrolls with the entries and ends above '
      'the home indicator', (tester) async {
    await tester.pumpWidget(
      onNotchedDevice(
        NaSideMenu(
          title: 'Menu',
          entries: List.generate(
            20,
            (index) => SizedBox(height: 50, child: Text('entry $index')),
          ),
          footer: const Text('footer'),
        ),
      ),
    );
    expect(find.text('footer'), findsNothing);
    expect(
      tester.getTopLeft(find.text('entry 0')).dx,
      greaterThanOrEqualTo(notchedInsets.left),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.text('footer')).dy,
      lessThanOrEqualTo(600 - notchedInsets.bottom - Space.md),
    );
    expect(
      tester.getTopLeft(find.text('footer')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('entry 19')).dy),
    );
  });
}
