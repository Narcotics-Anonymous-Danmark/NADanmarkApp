import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/release/semantic_version.dart';
import 'package:na_cli/src/release/version.dart';

sealed class BuildChoice {
  const BuildChoice();

  factory BuildChoice.from({required final OptionValue option}) =>
      switch (option) {
        OptionOmitted() => const FirstBuild(),
        OptionGiven(:final value) => ExplicitBuild(
          build: BuildNumber(int.tryParse(value) ?? 0),
        ),
      };

  BuildNumber get number => switch (this) {
    ExplicitBuild(:final build) => build,
    FirstBuild() => const BuildNumber(1),
  };
}

final class ExplicitBuild extends BuildChoice {
  const ExplicitBuild({required this.build});

  final BuildNumber build;
}

final class FirstBuild extends BuildChoice {
  const FirstBuild();
}

sealed class VersionRequest {
  const VersionRequest();

  factory VersionRequest.from({
    required final OptionValue positional,
    required final OptionValue bump,
    required final OptionValue build,
  }) {
    final choice = BuildChoice.from(option: build);
    return switch ((positional, bump)) {
      (OptionGiven(:final value), OptionOmitted()) => SetVersion(
        text: value,
        build: choice,
      ),
      (OptionOmitted(), OptionGiven(:final value)) => BumpVersion(
        kindText: value,
        build: choice,
      ),
      (OptionGiven(), OptionGiven()) => const KeepCurrentVersion(
        conflict: 'give either a version or --bump, not both',
      ),
      (OptionOmitted(), OptionOmitted()) => switch (build) {
        OptionOmitted() => const KeepCurrentVersion(conflict: ''),
        OptionGiven() => const KeepCurrentVersion(
          conflict: '--build needs a version or --bump',
        ),
      },
    };
  }

  VersionResolution resolve({required final AppVersion current}) =>
      switch (this) {
        KeepCurrentVersion(:final conflict) =>
          conflict.isEmpty
              ? VersionResolved(version: current)
              : VersionRequestRejected(reasons: [conflict]),
        SetVersion(:final text, :final build) => switch (SemanticVersion.parse(
          text: text,
        )) {
          SemanticVersionRejected(:final reason) => VersionRequestRejected(
            reasons: [reason],
          ),
          SemanticVersionParsed(:final version) => _validated(
            AppVersion(version: version, build: build.number),
          ),
        },
        BumpVersion(:final kindText, :final build) => switch (BumpKind.parse(
          text: kindText,
        )) {
          BumpKindRejected(:final reason) => VersionRequestRejected(
            reasons: [reason],
          ),
          BumpKindParsed(:final kind) => _validated(
            AppVersion(
              version: current.version.bump(kind: kind),
              build: build.number,
            ),
          ),
        },
      };

  VersionResolution _validated(final AppVersion candidate) =>
      switch (candidate.validate()) {
        AppVersionAccepted(:final version) => VersionResolved(version: version),
        AppVersionRejected(:final reasons) => VersionRequestRejected(
          reasons: reasons,
        ),
      };
}

final class KeepCurrentVersion extends VersionRequest {
  const KeepCurrentVersion({required this.conflict});

  final String conflict;
}

final class SetVersion extends VersionRequest {
  const SetVersion({required this.text, required this.build});

  final String text;
  final BuildChoice build;
}

final class BumpVersion extends VersionRequest {
  const BumpVersion({required this.kindText, required this.build});

  final String kindText;
  final BuildChoice build;
}

sealed class VersionResolution {
  const VersionResolution();
}

final class VersionResolved extends VersionResolution {
  const VersionResolved({required this.version});

  final AppVersion version;
}

final class VersionRequestRejected extends VersionResolution {
  const VersionRequestRejected({required this.reasons});

  final List<String> reasons;
}
