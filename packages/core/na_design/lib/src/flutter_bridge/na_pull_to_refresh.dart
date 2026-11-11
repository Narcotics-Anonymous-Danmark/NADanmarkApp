import 'package:flutter/widgets.dart';
import 'package:na_design/src/primitives/na_spinner.dart';
import 'package:na_design/src/tokens/na_spacing.dart';
import 'package:na_design/src/values/na_values.dart';

final class NaPullToRefresh extends StatefulWidget {
  const NaPullToRefresh({
    required this.activity,
    required this.busyLabel,
    required this.onRefresh,
    required this.child,
    super.key,
  });

  static const double threshold = 80;
  static const ScrollPhysics physics = AlwaysScrollableScrollPhysics(
    parent: BouncingScrollPhysics(),
  );

  final NaActivity activity;
  final NaLabel busyLabel;
  final VoidCallback onRefresh;
  final Widget child;

  @override
  State<NaPullToRefresh> createState() => _NaPullToRefreshState();
}

enum _Pull { resting, armed }

final class _NaPullToRefreshState extends State<NaPullToRefresh> {
  _Pull _pull = _Pull.resting;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) {
      return false;
    }
    final pulled =
        notification.metrics.pixels <=
        notification.metrics.minScrollExtent - NaPullToRefresh.threshold;
    switch (notification) {
      case ScrollUpdateNotification(dragDetails: DragUpdateDetails()):
        _pull = pulled ? _Pull.armed : _Pull.resting;
      case ScrollUpdateNotification() || ScrollEndNotification()
          when _pull == _Pull.armed:
        _pull = _Pull.resting;
        if (widget.activity == NaActivity.idle) {
          widget.onRefresh();
        }
      case ScrollNotification():
        break;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.activity == NaActivity.busy)
        Padding(
          key: const Key('na-refreshing'),
          padding: const EdgeInsets.all(Space.sm),
          child: Center(child: NaSpinner(label: widget.busyLabel, size: 24)),
        ),
      Expanded(
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
      ),
    ],
  );
}
