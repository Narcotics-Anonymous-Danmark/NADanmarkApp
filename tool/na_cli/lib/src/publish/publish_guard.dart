import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/host/env_value.dart';
import 'package:na_cli/src/ports/environment.dart';

enum PublishConsent { granted, withheld }

final class PublishGuard {
  const PublishGuard();

  PublishConsent consent({
    required final Environment environment,
    required final FlagState yes,
  }) {
    final ci = [
      'CI',
      'GITHUB_ACTIONS',
    ].map((final key) => environment.lookup(key: EnvKey(key)));
    if (yes == FlagState.on || ci.any((final v) => v is EnvSet)) {
      return PublishConsent.granted;
    }
    return PublishConsent.withheld;
  }

  void assertConsent({
    required final Environment environment,
    required final FlagState yes,
  }) {
    switch (consent(environment: environment, yes: yes)) {
      case PublishConsent.granted:
        return;
      case PublishConsent.withheld:
        throw const CliFailure.usage(
          message: 'publishing is for CI; pass --yes to run it locally',
        );
    }
  }
}
