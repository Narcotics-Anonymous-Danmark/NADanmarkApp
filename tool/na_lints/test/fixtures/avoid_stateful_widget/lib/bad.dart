import 'package:flutter/widgets.dart';

// expect_lint: avoid_stateful_widget
final class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => CounterState();
}

// expect_lint: avoid_stateful_widget
final class CounterState extends State<Counter> {
  @override
  Widget build(final BuildContext context) => const SizedBox();
}
