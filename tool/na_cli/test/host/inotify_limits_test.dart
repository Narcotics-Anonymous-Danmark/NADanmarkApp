@Tags(['unit'])
library;

import 'package:na_cli/src/host/inotify_limits.dart';
import 'package:test/test.dart';

void main() {
  test('healthy when instances have headroom and watches are plenty', () {
    const limits = InotifyLimits(
      maxInstances: 1024,
      instancesInUse: 150,
      maxWatches: 1048576,
    );
    expect(limits.verdict, isA<InotifyHealthy>());
  });

  test('exhausted when fewer than 16 instances remain or watches are low', () {
    const limits = InotifyLimits(
      maxInstances: 128,
      instancesInUse: 120,
      maxWatches: 65536,
    );
    final verdict = limits.verdict as InotifyExhausted;
    expect(verdict.reasons, hasLength(2));
    expect(
      verdict.fix.first,
      contains('sudo sysctl -w fs.inotify.max_user_instances=1024'),
    );
    expect(verdict.fix.last, contains('/etc/sysctl.d/60-na-inotify.conf'));
  });
}
