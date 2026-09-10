@Tags(['unit'])
library;

import 'package:test/test.dart';

import '../support/a_context.dart';
import '../support/builders.dart';
import '../support/file_system_mimic.dart';
import '../support/run_cli.dart';
import '../support/simple_mimics.dart';

void main() {
  late FileSystemMimic files;
  late ConsoleMimic console;

  setUp(() {
    files = FileSystemMimic(
      files: {
        appPubspecPath: aPubspec(name: 'na_app', version: '2.0.0+1120000001'),
      },
    );
    console = ConsoleMimic();
  });

  Future<int> run(
    final List<String> args, {
    final Map<String, String> environment = const {},
  }) async => (await runCli(
    context: aContext(files: files, console: console, environment: environment),
    arguments: ['release', 'version', ...args],
  )).value;

  test('--print shows the current version without writing', () async {
    expect(await run(['--print']), 0);
    expect(
      console.outLines.single,
      'version 2.0.0 build 1 code 1120000001 tag 2.0.0',
    );
    expect(files.texts[appPubspecPath], contains('2.0.0+1120000001'));
  });

  test('--json without a version prints the current values', () async {
    expect(await run(['--json']), 0);
    expect(
      console.outLines.single,
      '{"version":"2.0.0","build":1,"versionCode":1120000001,"tag":"2.0.0"}',
    );
  });

  test('setting a version rewrites app/pubspec.yaml', () async {
    expect(await run(['2.1.0', '--build', '3']), 0);
    expect(files.texts[appPubspecPath], contains('version: 2.1.0+1120100003'));
    expect(console.outLines.single, contains('tag 2.1.0-b3'));
  });

  test('--bump derives from the current version', () async {
    expect(await run(['--bump', 'patch']), 0);
    expect(files.texts[appPubspecPath], contains('version: 2.0.1+1120001001'));
  });

  test('--github-output appends the four keys', () async {
    expect(
      await run(
        ['--github-output'],
        environment: {'GITHUB_OUTPUT': '/tmp/out'},
      ),
      0,
    );
    expect(
      files.texts['/tmp/out'],
      'version=2.0.0\nbuild=1\nversion_code=1120000001\ntag=2.0.0\n',
    );
  });

  test('invalid input is a usage error', () async {
    expect(await run(['2.0']), 64);
    expect(console.errLines.single, contains('is not x.y.z'));
  });
}
