import 'package:flutter/widgets.dart';

final class NaPage extends Page<void> {
  const NaPage({required this.child, super.key});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder<void>(
    settings: this,
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, page) =>
        FadeTransition(opacity: animation, child: page),
  );
}
