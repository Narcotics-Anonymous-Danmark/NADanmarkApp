import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';

final class NaApp extends StatelessWidget {
  const NaApp({
    required this.title,
    required this.theme,
    required this.routerConfig,
    required this.localizationsDelegates,
    required this.supportedLocales,
    required this.locale,
    super.key,
  });

  final String title;
  final NaThemeData theme;
  final RouterConfig<Object> routerConfig;
  final Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates;
  final Iterable<Locale> supportedLocales;
  final Locale locale;

  @override
  Widget build(BuildContext context) => NaTheme(
    data: theme,
    child: WidgetsApp.router(
      title: title,
      color: theme.colors.primary,
      routerConfig: routerConfig,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
      textStyle: theme.typography.body,
    ),
  );
}
