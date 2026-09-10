sealed class BuildProcessing {
  const BuildProcessing();

  factory BuildProcessing.fromState({
    required final String buildId,
    required final String state,
  }) {
    if (state == 'VALID') {
      return BuildValid(buildId: buildId);
    }
    if (state == 'INVALID' || state == 'FAILED') {
      return BuildRejected(buildId: buildId, state: state);
    }
    return BuildStillProcessing(buildId: buildId, state: state);
  }
}

final class BuildNotYetVisible extends BuildProcessing {
  const BuildNotYetVisible();
}

final class BuildStillProcessing extends BuildProcessing {
  const BuildStillProcessing({required this.buildId, required this.state});

  final String buildId;
  final String state;
}

final class BuildValid extends BuildProcessing {
  const BuildValid({required this.buildId});

  final String buildId;
}

final class BuildRejected extends BuildProcessing {
  const BuildRejected({required this.buildId, required this.state});

  final String buildId;
  final String state;
}
