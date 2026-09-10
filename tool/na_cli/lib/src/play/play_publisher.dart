import 'dart:convert';

import 'package:na_cli/src/boundary/json_object.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/http/http_call.dart';
import 'package:na_cli/src/http/http_reply.dart';
import 'package:na_cli/src/play/google_access_token.dart';
import 'package:na_cli/src/play/play_track_release.dart';
import 'package:na_cli/src/ports/console.dart';
import 'package:na_cli/src/ports/http_transport.dart';

extension type const PlayPackage(String value) {
  static const PlayPackage androidApp = PlayPackage('dk.nadanmark.app');
}

extension type const EditId(String value) {}

final class PlayPublisher {
  const PlayPublisher({
    required this.http,
    required this.token,
    required this.console,
  });

  final HttpTransport http;
  final AccessToken token;
  final Console console;

  static const String _base =
      'https://androidpublisher.googleapis.com/androidpublisher/v3';
  static const String _upload =
      'https://androidpublisher.googleapis.com/upload/androidpublisher/v3';

  Future<void> publish({
    required final PlayPackage package,
    required final List<int> bundle,
    required final PlayTrackRelease release,
  }) async {
    final edit = await _createEdit(package);
    try {
      await _uploadBundle(package: package, edit: edit, bundle: bundle);
      await _assignTrack(package: package, edit: edit, release: release);
      await _call(
        method: HttpMethod.post,
        url: '$_base/applications/${package.value}/edits/${edit.value}:commit',
        headers: const {},
        body: const [],
      );
      console.out(line: 'play: committed edit ${edit.value}');
    } on CliFailure {
      await http.send(
        call: HttpCall(
          method: HttpMethod.delete,
          url: Uri.parse(
            '$_base/applications/${package.value}/edits/${edit.value}',
          ),
          headers: _headers(const {}),
          body: const [],
        ),
      );
      rethrow;
    }
  }

  Future<EditId> _createEdit(final PlayPackage package) async {
    final body = await _call(
      method: HttpMethod.post,
      url: '$_base/applications/${package.value}/edits',
      headers: const {},
      body: const [],
    );
    return switch (JsonObject.parse(text: body)) {
      JsonObjectParsed(:final object) => EditId(
        object.text(key: 'id').orElse(fallback: ''),
      ),
      JsonListParsed() || JsonMalformed() => throw const CliFailure.general(
        message: 'play: edit response is not a JSON object',
      ),
    };
  }

  Future<void> _uploadBundle({
    required final PlayPackage package,
    required final EditId edit,
    required final List<int> bundle,
  }) async {
    await _call(
      method: HttpMethod.post,
      url:
          '$_upload/applications/${package.value}/edits/${edit.value}/bundles'
          '?uploadType=media',
      headers: const {'content-type': 'application/octet-stream'},
      body: bundle,
    );
    console.out(line: 'play: uploaded bundle (${bundle.length} bytes)');
  }

  Future<void> _assignTrack({
    required final PlayPackage package,
    required final EditId edit,
    required final PlayTrackRelease release,
  }) => _call(
    method: HttpMethod.put,
    url:
        '$_base/applications/${package.value}/edits/${edit.value}'
        '/tracks/internal',
    headers: const {'content-type': 'application/json'},
    body: utf8.encode(release.render()),
  );

  Future<String> _call({
    required final HttpMethod method,
    required final String url,
    required final Map<String, String> headers,
    required final List<int> body,
  }) async {
    final reply = await http.send(
      call: HttpCall(
        method: method,
        url: Uri.parse(url),
        headers: _headers(headers),
        body: body,
      ),
    );
    if (reply.status.outcome == HttpOutcome.failure) {
      throw CliFailure.general(
        message:
            'play: ${method.name.toUpperCase()} $url failed '
            '(${reply.status.value}): ${reply.body}',
      );
    }
    return reply.body;
  }

  Map<String, String> _headers(final Map<String, String> extra) => {
    'authorization': 'Bearer ${token.value}',
    ...extra,
  };
}
