@Tags(['unit'])
library;

import 'dart:convert';

import 'package:na_cli/src/http/http_call.dart';
import 'package:na_cli/src/http/http_reply.dart';
import 'package:test/test.dart';

import '../support/a_context.dart';
import '../support/builders.dart';
import '../support/file_system_mimic.dart';
import '../support/json_shapes.dart';
import '../support/run_cli.dart';
import '../support/simple_mimics.dart';
import '../support/test_keys.dart';

const String v3 = 'https://androidpublisher.googleapis.com/androidpublisher/v3';
const String upload =
    'https://androidpublisher.googleapis.com/upload/androidpublisher/v3';

void main() {
  late ConsoleMimic console;
  late FileSystemMimic files;

  setUp(() {
    console = ConsoleMimic();
    files = FileSystemMimic(
      files: {
        appPubspecPath: aPubspec(name: 'na_app', version: '2.0.0+1120000001'),
        '/repo/dist/app.aab': 'BUNDLE',
        '/repo/NOTES.md':
            'x\n<!-- release-notes:start -->\nFixed things\n'
            '<!-- release-notes:end -->\n',
      },
    );
  });

  Map<String, String> environment({final String notesLanguage = 'da-DK'}) => {
    'CI': 'true',
    'PLAY_SERVICE_ACCOUNT_JSON': jsonEncode({
      'client_email': 'ci@x.iam.gserviceaccount.com',
      'private_key': rsaPkcs8Pem,
    }),
    if (notesLanguage.isNotEmpty) 'PLAY_RELEASE_NOTES_LANGUAGE': notesLanguage,
  };

  HttpReply ok(final String body) =>
      HttpReply(status: const HttpStatus(200), body: body);

  test('refuses to publish outside CI without --yes', () async {
    final code = await runCli(
      context: aContext(files: files, console: console),
      arguments: ['publish', 'play', '--aab', 'dist/app.aab'],
    );
    expect(code.value, 64);
  });

  test('play uploads through the edits API and commits', () async {
    final http = HttpTransportMimic(
      replies: [
        ok('{"access_token":"tok"}'),
        ok('{"id":"edit-1"}'),
        ok('{}'),
        ok('{}'),
        ok('{}'),
      ],
    );
    final code = await runCli(
      context: aContext(
        files: files,
        console: console,
        http: http,
        environment: environment(),
      ),
      arguments: [
        'publish',
        'play',
        '--aab',
        'dist/app.aab',
        '--notes',
        'NOTES.md',
        '--draft',
      ],
    );
    expect(code.value, 0);
    const bundles =
        '$upload/applications/dk.nadanmark.app/edits/edit-1/bundles';
    expect(http.calls.map((final c) => '${c.method.name} ${c.url}'), [
      'post https://oauth2.googleapis.com/token',
      'post $v3/applications/dk.nadanmark.app/edits',
      'post $bundles?uploadType=media',
      'put $v3/applications/dk.nadanmark.app/edits/edit-1/tracks/internal',
      'post $v3/applications/dk.nadanmark.app/edits/edit-1:commit',
    ]);
    expect(http.calls[1].headers['authorization'], 'Bearer tok');
    expect(utf8.decode(http.calls[2].body), 'BUNDLE');
    expect(http.calls[2].headers['content-type'], 'application/octet-stream');
    final track =
        jsonDecode(utf8.decode(http.calls[3].body)) as Map<String, Object?>;
    final release = singleObjectIn(list: track['releases']);
    expect(release['status'], 'draft');
    expect(release['versionCodes'], ['1120000001']);
    expect(release['releaseNotes'], [
      {'language': 'da-DK', 'text': 'Fixed things'},
    ]);
    final token = Uri.splitQueryString(utf8.decode(http.calls[0].body));
    expect(token['grant_type'], 'urn:ietf:params:oauth:grant-type:jwt-bearer');
    expect(token['assertion'], isNotEmpty);
  });

  test('play deletes the edit when the track update fails', () async {
    final http = HttpTransportMimic(
      replies: [
        ok('{"access_token":"tok"}'),
        ok('{"id":"edit-1"}'),
        ok('{}'),
        const HttpReply(status: HttpStatus(400), body: 'bad'),
      ],
    );
    final code = await runCli(
      context: aContext(
        files: files,
        console: console,
        http: http,
        environment: environment(notesLanguage: ''),
      ),
      arguments: ['publish', 'play', '--aab', 'dist/app.aab', '--yes'],
    );
    expect(code.value, 1);
    expect(http.calls.last.method, HttpMethod.delete);
    expect(http.calls.last.url.toString(), endsWith('/edits/edit-1'));
    expect(console.errLines.single, contains('tracks/internal failed (400)'));
  });
}
