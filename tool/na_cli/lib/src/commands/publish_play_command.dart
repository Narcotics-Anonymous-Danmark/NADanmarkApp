import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/arg_reader.dart';
import 'package:na_cli/src/boundary/option_value.dart';
import 'package:na_cli/src/boundary/pkcs8_key_reader.dart';
import 'package:na_cli/src/boundary/pointycastle_signer.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/crypto/jwt.dart';
import 'package:na_cli/src/crypto/pem_normaliser.dart';
import 'package:na_cli/src/crypto/signing_key.dart';
import 'package:na_cli/src/fs/file_bytes.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/host/env_value.dart';
import 'package:na_cli/src/play/google_access_token.dart';
import 'package:na_cli/src/play/play_publisher.dart';
import 'package:na_cli/src/play/play_track_release.dart';
import 'package:na_cli/src/play/service_account.dart';
import 'package:na_cli/src/ports/environment.dart';
import 'package:na_cli/src/publish/notes_source.dart';
import 'package:na_cli/src/publish/publish_guard.dart';
import 'package:na_cli/src/release/version_store.dart';

final class PublishPlayCommand extends Command<int> {
  PublishPlayCommand({required this.context}) {
    argParser
      ..addOption('aab', help: 'Path to the app bundle.', mandatory: true)
      ..addOption('notes', help: 'Release notes file, or - for stdin.')
      ..addFlag('draft', negatable: false, help: 'Create a draft release.')
      ..addFlag('yes', negatable: false, help: 'Allow running outside CI.');
  }

  final CliContext context;

  @override
  String get name => 'play';

  @override
  String get description => 'Upload an .aab to the Play internal track.';

  @override
  String get invocation =>
      'na publish play --aab <file> [--notes <file|->] [--draft] [--yes]';

  @override
  Future<int> run() async {
    final args = ArgReader.of(command: this);
    const PublishGuard().assertConsent(
      environment: context.environment,
      yes: args.flag(name: 'yes'),
    );
    final aabPath = FilePath(
      args.option(name: 'aab').orElse(fallback: ''),
    ).resolveFrom(context.repoRoot);
    final bundle = switch (context.files.readBytes(path: aabPath)) {
      BytesRead(:final bytes) => bytes,
      NoSuchBinary() => throw CliFailure.general(
        message: '${aabPath.value} not found',
      ),
    };
    final account = _account();
    final key = _key(account);
    final version = VersionStore(context: context).read();
    final notes = NotesSource(context: context).load(
      option: args.option(name: 'notes'),
    );
    final release = PlayTrackRelease(
      version: version,
      status: switch (args.flag(name: 'draft')) {
        FlagState.on => PlayReleaseStatus.draft,
        FlagState.off => PlayReleaseStatus.completed,
      },
      notes: _notes(notes),
    );
    final token =
        await GoogleAccessToken(
          http: context.http,
          jwt: const Jwt(signer: PointycastleSigner()),
        ).fetch(
          key: key,
          clientEmail: account.clientEmail,
          now: context.clock.now(),
        );
    await PlayPublisher(
      http: context.http,
      token: token,
      console: context.console,
    ).publish(
      package: PlayPackage.androidApp,
      bundle: bundle,
      release: release,
    );
    return 0;
  }

  ServiceAccount _account() {
    final raw = switch (context.environment.lookup(
      key: const EnvKey('PLAY_SERVICE_ACCOUNT_JSON'),
    )) {
      EnvSet(:final value) => value,
      EnvUnset() => throw const CliFailure.general(
        message: 'PLAY_SERVICE_ACCOUNT_JSON is not set',
      ),
    };
    return switch (ServiceAccount.parse(raw: raw)) {
      ServiceAccountParsed(:final account) => account,
      ServiceAccountRejected(:final reason) => throw CliFailure.general(
        message: reason,
      ),
    };
  }

  SigningKey _key(final ServiceAccount account) {
    final pem = switch (const PemNormaliser().normalise(
      raw: account.privateKeyPem,
    )) {
      PemAccepted(:final document) => document,
      PemRejected(:final reason) => throw CliFailure.general(message: reason),
    };
    return switch (const Pkcs8KeyReader().read(pem: pem)) {
      SigningKeyParsed(:final key) => key,
      SigningKeyRejected(:final reason) => throw CliFailure.general(
        message: reason,
      ),
    };
  }

  PlayReleaseNotes _notes(final NotesText notes) => switch (notes) {
    NotesAbsent() => const NoNotes(),
    NotesProvided(:final text) => switch (context.environment.lookup(
      key: const EnvKey('PLAY_RELEASE_NOTES_LANGUAGE'),
    )) {
      EnvUnset() => const NoNotes(),
      EnvSet(:final value) => LocalisedNotes(language: value, text: text),
    },
  };
}
