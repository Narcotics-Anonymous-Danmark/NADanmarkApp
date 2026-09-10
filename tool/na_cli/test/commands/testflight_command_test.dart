@Tags(['unit'])
library;

import 'dart:convert';

import 'package:na_cli/src/http/http_reply.dart';
import 'package:test/test.dart';

import '../support/a_context.dart';
import '../support/builders.dart';
import '../support/file_system_mimic.dart';
import '../support/json_shapes.dart';
import '../support/process_runner_mimic.dart';
import '../support/run_cli.dart';
import '../support/simple_mimics.dart';
import '../support/test_keys.dart';

void main() {
  late ConsoleMimic console;
  late FileSystemMimic files;

  final environment = {
    'GITHUB_ACTIONS': 'true',
    'APP_STORE_CONNECT_KEY_ID': 'KEY1',
    'APP_STORE_CONNECT_ISSUER_ID': 'issuer-1',
    'APP_STORE_CONNECT_PRIVATE_KEY': ecPkcs8Pem.replaceAll('\n', r'\n'),
  };

  setUp(() {
    console = ConsoleMimic();
    files = FileSystemMimic(
      files: {
        appPubspecPath: aPubspec(name: 'na_app', version: '2.0.0+1120000001'),
        '/repo/dist/app.ipa': 'IPA',
        '/repo/notes.txt': 'What to test',
      },
    );
  });

  HttpReply ok(final Object body) =>
      HttpReply(status: const HttpStatus(200), body: jsonEncode(body));

  test('uploads with altool, waits for VALID and posts what to test', () async {
    final http = HttpTransportMimic(
      replies: [
        ok({
          'data': [
            {'id': 'app-1'},
          ],
        }),
        ok({'data': <Object>[]}),
        ok({
          'data': [
            {
              'id': 'build-9',
              'attributes': {'processingState': 'PROCESSING'},
            },
          ],
        }),
        ok({
          'data': [
            {
              'id': 'build-9',
              'attributes': {'processingState': 'VALID'},
            },
          ],
        }),
        ok({'data': <Object>[]}),
        ok({
          'data': {'id': 'loc-1'},
        }),
      ],
    );
    final runner = ProcessRunnerMimic();
    final sleeper = SleeperMimic();
    final code = await runCli(
      context: aContext(
        files: files,
        console: console,
        processes: runner,
        http: http,
        sleeper: sleeper,
        environment: environment,
      ),
      arguments: [
        'publish',
        'testflight',
        '--ipa',
        'dist/app.ipa',
        '--notes',
        'notes.txt',
      ],
    );
    expect(code.value, 0);
    const upload =
        'xcrun altool --upload-app -f /repo/dist/app.ipa -t ios '
        '--apiKey KEY1 --apiIssuer issuer-1';
    expect(runner.passedThroughDisplays, [upload]);
    expect(
      runner.displays,
      contains(
        'chmod 600 /home/tester/.appstoreconnect/private_keys/AuthKey_KEY1.p8',
      ),
    );
    expect(
      files.texts['/home/tester/.appstoreconnect/private_keys/AuthKey_KEY1.p8'],
      startsWith('-----BEGIN PRIVATE KEY-----\n'),
    );
    expect(sleeper.sleeps, hasLength(2));
    expect(
      Uri.decodeFull(http.calls[0].url.toString()),
      contains('filter[bundleId]=dk.nadanmark.ios.app'),
    );
    expect(
      Uri.decodeFull(http.calls[1].url.toString()),
      contains(
        'filter[app]=app-1&filter[version]=1'
        '&filter[preReleaseVersion.version]=2.0.0',
      ),
    );
    expect(
      http.calls[5].url.toString(),
      endsWith('/v1/betaBuildLocalizations'),
    );
    final body =
        jsonDecode(utf8.decode(http.calls[5].body)) as Map<String, Object?>;
    final data = objectIn(value: body['data']);
    expect(data['attributes'], {'whatsNew': 'What to test', 'locale': 'en-US'});
    expect(http.calls[0].headers['authorization'], startsWith('Bearer '));
  });

  test('falls back to iTMSTransporter and honours --no-wait', () async {
    final runner = ProcessRunnerMimic(
      responses: [whenRun(match: 'xcrun altool', exitCode: 1)],
    );
    final http = HttpTransportMimic();
    final code = await runCli(
      context: aContext(
        files: files,
        console: console,
        processes: runner,
        http: http,
        environment: environment,
      ),
      arguments: [
        'publish',
        'testflight',
        '--ipa',
        'dist/app.ipa',
        '--no-wait',
      ],
    );
    expect(code.value, 0);
    expect(
      runner.passedThroughDisplays[1],
      startsWith(
        'xcrun iTMSTransporter -m upload -assetFile /repo/dist/app.ipa',
      ),
    );
    expect(http.calls, isEmpty);
  });

  test('an INVALID build fails', () async {
    final http = HttpTransportMimic(
      replies: [
        ok({
          'data': [
            {'id': 'app-1'},
          ],
        }),
        ok({
          'data': [
            {
              'id': 'b',
              'attributes': {'processingState': 'INVALID'},
            },
          ],
        }),
      ],
    );
    final code = await runCli(
      context: aContext(
        files: files,
        console: console,
        http: http,
        environment: environment,
      ),
      arguments: ['publish', 'testflight', '--ipa', 'dist/app.ipa'],
    );
    expect(code.value, 1);
    expect(console.errLines.single, contains('INVALID'));
  });

  test('times out when the build never becomes valid', () async {
    final http = HttpTransportMimic(
      replies: [
        ok({
          'data': [
            {'id': 'app-1'},
          ],
        }),
      ],
    );
    final clock = FixedClock(current: DateTime.utc(2026, 9, 10, 12));
    final ticking = aContext(
      files: files,
      console: console,
      http: http,
      environment: environment,
      clock: clock,
      sleeper: SleeperMimic(
        onSleep: () =>
            clock.current = clock.current.add(const Duration(minutes: 10)),
      ),
    );
    final code = await runCli(
      context: ticking,
      arguments: [
        'publish',
        'testflight',
        '--ipa',
        'dist/app.ipa',
        '--wait-minutes',
        '1',
      ],
    );
    expect(code.value, 1);
    expect(console.errLines.single, contains('not processed within 1 minutes'));
  });
}
