import 'package:na_kernel/na_kernel.dart';

final class TestTime {
  TestTime({
    required Instant startAt,
    required TimeZoneId zone,
    required this.utcOffset,
  }) : _now = startAt,
       _zone = zone;

  factory TestTime.copenhagen({required Instant startAt}) => TestTime(
    startAt: startAt,
    zone: TimeZoneId.copenhagen,
    utcOffset: const Duration(hours: 2),
  );

  final Duration utcOffset;
  final TimeZoneId _zone;
  Instant _now;
  final List<_ScheduledAction> _scheduled = [];
  final List<void Function(Instant now)> _tickListeners = [];
  int _nextId = 0;

  Instant get now => _now;

  TimeZoneId get zone => _zone;

  DateTime get localDateTime => _now.utc.add(utcOffset);

  void advance({required Duration by}) {
    final target = _now.plus(duration: by);
    _fireDue(until: target);
    _now = target;
    for (final listener in List.of(_tickListeners)) {
      listener(_now);
    }
  }

  ScheduledHandle schedule({
    required Duration delay,
    required void Function() action,
    required Repeat repeat,
  }) {
    final id = _nextId++;
    _scheduled.add(
      _ScheduledAction(
        id: id,
        dueAt: _now.plus(duration: delay),
        period: delay,
        action: action,
        repeat: repeat,
      ),
    );
    return ScheduledHandle(id: id, owner: this);
  }

  void cancel({required int id}) =>
      _scheduled.removeWhere((entry) => entry.id == id);

  void addTickListener({required void Function(Instant now) listener}) =>
      _tickListeners.add(listener);

  void removeTickListener({required void Function(Instant now) listener}) =>
      _tickListeners.remove(listener);

  int get pendingActions => _scheduled.length;

  void _fireDue({required Instant until}) {
    var due = _dueBefore(until: until);
    while (due.isNotEmpty) {
      final next = due.first;
      _now = next.dueAt;
      _scheduled.remove(next);
      switch (next.repeat) {
        case Repeat.once:
          break;
        case Repeat.periodic:
          _scheduled.add(next.rescheduled());
      }
      next.action();
      due = _dueBefore(until: until);
    }
  }

  List<_ScheduledAction> _dueBefore({required Instant until}) =>
      (_scheduled
          .where(
            (entry) => entry.dueAt.compareTo(other: until) != Comparison.after,
          )
          .toList()
        ..sort((a, b) => a.dueAt.utc.compareTo(b.dueAt.utc)));
}

enum Repeat { once, periodic }

final class ScheduledHandle {
  const ScheduledHandle({required this.id, required this.owner});

  final int id;
  final TestTime owner;

  void cancel() => owner.cancel(id: id);
}

final class _ScheduledAction {
  const _ScheduledAction({
    required this.id,
    required this.dueAt,
    required this.period,
    required this.action,
    required this.repeat,
  });

  final int id;
  final Instant dueAt;
  final Duration period;
  final void Function() action;
  final Repeat repeat;

  _ScheduledAction rescheduled() => _ScheduledAction(
    id: id,
    dueAt: dueAt.plus(duration: period),
    period: period,
    action: action,
    repeat: repeat,
  );
}
