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
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/publish/notes_source.dart';
import 'package:na_cli/src/publish/publish_guard.dart';
import 'package:na_cli/src/release/release_inputs.dart';
import 'package:na_cli/src/release/version_store.dart';
import 'package:na_cli/src/testflight/app_store_connect_client.dart';
import 'package:na_cli/src/testflight/testflight_publisher.dart';
import 'package:na_cli/src/tools/shell.dart';

final class PublishTestflightCommand extends Command<int> {
  PublishTestflightCommand({required this.context}) {
    argParser
      ..addOption('ipa', help: 'Path to the ipa.', mandatory: true)
      ..addOption('notes', help: 'What to test file, or - for stdin.')
      ..addFlag(
        'no-wait',
        negatable: false,
        help: 'Do not wait for processing.',
      )
      ..addOption('wait-minutes', help: 'Processing timeout (default 45).')
      ..addFlag('yes', negatable: false, help: 'Allow running outside CI.');
  }

  final CliContext context;

  @override
  String get name => 'testflight';

  @override
  String get description => 'Upload an .ipa to TestFlight.';

  @override
  String get invocation =>
      'na publish testflight --ipa <file> [--notes <file|->] [--no-wait] '
      '[--wait-minutes n] [--yes]';

  @override
  Future<int> run() async {
    final args = ArgReader.of(command: this);
    const PublishGuard().assertConsent(
      environment: context.environment,
      yes: args.flag(name: 'yes'),
    );
    final inputs = ReleaseInputs(context: context);
    final keyId = inputs.secret(key: 'APP_STORE_CONNECT_KEY_ID');
    final pem = _pem(inputs.secret(key: 'APP_STORE_CONNECT_PRIVATE_KEY'));
    await _installKey(keyId: keyId, pem: pem);
    final client = AppStoreConnectClient(
      http: context.http,
      jwt: const Jwt(signer: PointycastleSigner()),
      credentials: AppStoreConnectCredentials(
        keyId: keyId,
        issuerId: inputs.secret(key: 'APP_STORE_CONNECT_ISSUER_ID'),
        key: _key(pem),
      ),
    );
    final publisher = TestflightPublisher(context: context, client: client);
    await publisher.upload(
      ipa: FilePath(
        args.option(name: 'ipa').orElse(fallback: ''),
      ).resolveFrom(context.repoRoot),
    );
    await publisher.awaitProcessing(
      version: VersionStore(context: context).read(),
      policy: switch (args.flag(name: 'no-wait')) {
        FlagState.on => const NoWait(),
        FlagState.off => WaitForProcessing(
          limit: Duration(
            minutes: int.parse(
              args.option(name: 'wait-minutes').orElse(fallback: '45'),
            ),
          ),
        ),
      },
      notes: NotesSource(context: context).load(
        option: args.option(name: 'notes'),
      ),
    );
    return 0;
  }

  PemDocument _pem(final String raw) =>
      switch (const PemNormaliser().normalise(raw: raw)) {
        PemAccepted(:final document) => document,
        PemRejected(:final reason) => throw CliFailure.general(message: reason),
      };

  SigningKey _key(final PemDocument pem) =>
      switch (const Pkcs8KeyReader().read(pem: pem)) {
        SigningKeyParsed(:final key) => key,
        SigningKeyRejected(:final reason) => throw CliFailure.general(
          message: reason,
        ),
      };

  Future<void> _installKey({
    required final String keyId,
    required final PemDocument pem,
  }) async {
    final dir = context.files.homeDirectory.joinAll([
      '.appstoreconnect',
      'private_keys',
    ]);
    final path = dir.join('AuthKey_$keyId.p8');
    context.files.writeText(path: path, text: pem.render());
    await Shell(context: context).captureOrFail(
      command: CommandLine.at(
        executable: const Executable('chmod'),
        arguments: ['600', path.value],
        workingDirectory: context.repoRoot,
      ),
    );
  }
}
