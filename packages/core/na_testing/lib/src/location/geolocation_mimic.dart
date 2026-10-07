import 'dart:async';

import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/src/builders/test_values.dart';
import 'package:na_testing/src/time/test_time.dart';

enum PromptAnswer { grant, refuse, ignore }

sealed class FixDelivery {
  const FixDelivery();
}

final class FixAtOnce extends FixDelivery {
  const FixAtOnce({required this.fix});

  final PositionFix fix;
}

final class FixAfter extends FixDelivery {
  const FixAfter({required this.delay, required this.fix});

  final Duration delay;
  final PositionFix fix;
}

final class FixNever extends FixDelivery {
  const FixNever();
}

final class GeolocationMimic implements GeolocationPort {
  GeolocationMimic({
    required this.time,
    required this.currentAccess,
    required this.promptAnswer,
    required this.delivery,
  });

  final TestTime time;
  LocationAccess currentAccess;
  PromptAnswer promptAnswer;
  FixDelivery delivery;
  CallCount accessCalls = const CallCount(0);
  CallCount requestCalls = const CallCount(0);
  CallCount positionCalls = const CallCount(0);

  CallCount get calls => accessCalls + requestCalls + positionCalls;

  @override
  Future<LocationAccess> access() async {
    accessCalls = accessCalls.next;
    return currentAccess;
  }

  @override
  Future<LocationAccess> requestAccess() {
    requestCalls = requestCalls.next;
    return switch (promptAnswer) {
      PromptAnswer.grant => Future.value(
        currentAccess = LocationAccess.granted,
      ),
      PromptAnswer.refuse => Future.value(
        currentAccess = LocationAccess.refused,
      ),
      PromptAnswer.ignore => Completer<LocationAccess>().future,
    };
  }

  @override
  Future<PositionFix> currentPosition() {
    positionCalls = positionCalls.next;
    return switch (delivery) {
      FixAtOnce(:final fix) => Future.value(fix),
      FixAfter(:final delay, :final fix) => _later(delay: delay, fix: fix),
      FixNever() => Completer<PositionFix>().future,
    };
  }

  Future<PositionFix> _later({
    required Duration delay,
    required PositionFix fix,
  }) {
    final arrived = Completer<PositionFix>();
    time.schedule(
      delay: delay,
      action: () => arrived.complete(fix),
      repeat: Repeat.once,
    );
    return arrived.future;
  }
}
