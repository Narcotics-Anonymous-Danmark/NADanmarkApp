final class InotifyLimits {
  const InotifyLimits({
    required this.maxInstances,
    required this.instancesInUse,
    required this.maxWatches,
  });

  final int maxInstances;
  final int instancesInUse;
  final int maxWatches;

  static const int instanceHeadroom = 16;
  static const int minimumWatches = 524288;

  static const String fixCommand =
      'sudo sysctl -w fs.inotify.max_user_instances=1024 '
      'fs.inotify.max_user_watches=1048576';

  static const String persistentFix =
      r'printf "%s\n%s\n" fs.inotify.max_user_instances=1024 '
      'fs.inotify.max_user_watches=1048576 | '
      'sudo tee /etc/sysctl.d/60-na-inotify.conf';

  InotifyVerdict get verdict {
    final instances =
        'inotify instances in use: $instancesInUse of '
        '$maxInstances (the Dart analysis server needs headroom)';
    final reasons = [
      if (instancesInUse >= maxInstances - instanceHeadroom) instances,
      if (maxWatches < minimumWatches)
        'fs.inotify.max_user_watches is $maxWatches, below $minimumWatches',
    ];
    if (reasons.isEmpty) {
      return const InotifyHealthy();
    }
    return InotifyExhausted(
      reasons: List.unmodifiable(reasons),
      fix: [fixCommand, persistentFix],
    );
  }
}

sealed class InotifyVerdict {
  const InotifyVerdict();
}

final class InotifyHealthy extends InotifyVerdict {
  const InotifyHealthy();
}

final class InotifyExhausted extends InotifyVerdict {
  const InotifyExhausted({required this.reasons, required this.fix});

  final List<String> reasons;
  final List<String> fix;
}
