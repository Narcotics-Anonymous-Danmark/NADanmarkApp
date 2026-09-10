import 'package:feature_settings/feature_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:na_design/na_design.dart';
import 'package:na_l10n/na_l10n.dart';

final class NaDanmarkApp extends ConsumerWidget {
  const NaDanmarkApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) => NaApp(
    title: 'NA Danmark',
    theme: NaThemeData.light(),
    routerConfig: router,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: supportedLocales,
    locale: ref.watch(currentLanguageProvider).locale,
  );
}
