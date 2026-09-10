import 'dart:convert';

import 'package:na_cli/src/boundary/json_object.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/crypto/epoch_seconds.dart';
import 'package:na_cli/src/crypto/jwt.dart';
import 'package:na_cli/src/crypto/signing_key.dart';
import 'package:na_cli/src/http/http_call.dart';
import 'package:na_cli/src/http/http_reply.dart';
import 'package:na_cli/src/ios/provisioning_profile.dart';
import 'package:na_cli/src/ports/http_transport.dart';
import 'package:na_cli/src/release/version.dart';
import 'package:na_cli/src/testflight/build_processing.dart';

extension type const AppStoreAppId(String value) {}

final class AppStoreConnectCredentials {
  const AppStoreConnectCredentials({
    required this.keyId,
    required this.issuerId,
    required this.key,
  });

  final String keyId;
  final String issuerId;
  final SigningKey key;
}

final class AppStoreConnectClient {
  const AppStoreConnectClient({
    required this.http,
    required this.jwt,
    required this.credentials,
  });

  final HttpTransport http;
  final Jwt jwt;
  final AppStoreConnectCredentials credentials;

  static const String base = 'https://api.appstoreconnect.apple.com';

  Map<String, Object> claims({required final DateTime now}) {
    final issued = EpochSeconds.of(time: now);
    return {
      'iss': credentials.issuerId,
      'iat': issued.value,
      'exp': issued.plus(duration: const Duration(minutes: 20)).value,
      'aud': 'appstoreconnect-v1',
    };
  }

  Future<AppStoreAppId> appId({
    required final BundleId bundleId,
    required final DateTime now,
  }) async {
    final body = await _get(
      url: '$base/v1/apps?filter[bundleId]=${bundleId.value}',
      now: now,
    );
    final apps = _data(body);
    if (apps.isEmpty) {
      throw CliFailure.general(
        message: 'App Store Connect has no app with bundle ${bundleId.value}',
      );
    }
    return AppStoreAppId(apps.first.text(key: 'id').orElse(fallback: ''));
  }

  Future<BuildProcessing> buildState({
    required final AppStoreAppId app,
    required final AppVersion version,
    required final DateTime now,
  }) async {
    final body = await _get(
      url:
          '$base/v1/builds?filter[app]=${app.value}'
          '&filter[version]=${version.build.value}'
          '&filter[preReleaseVersion.version]=${version.version}',
      now: now,
    );
    final builds = _data(body);
    if (builds.isEmpty) {
      return const BuildNotYetVisible();
    }
    final build = builds.first;
    return BuildProcessing.fromState(
      buildId: build.text(key: 'id').orElse(fallback: ''),
      state: build
          .object(key: 'attributes')
          .text(key: 'processingState')
          .orElse(fallback: ''),
    );
  }

  Future<void> setWhatsNew({
    required final String buildId,
    required final String whatsNew,
    required final DateTime now,
  }) async {
    final existing = _data(
      await _get(
        url:
            '$base/v1/builds/$buildId/betaBuildLocalizations'
            '?filter[locale]=en-US',
        now: now,
      ),
    );
    final attributes = {'whatsNew': whatsNew};
    if (existing.isEmpty) {
      await _send(
        method: HttpMethod.post,
        url: '$base/v1/betaBuildLocalizations',
        now: now,
        json: {
          'data': {
            'type': 'betaBuildLocalizations',
            'attributes': {...attributes, 'locale': 'en-US'},
            'relationships': {
              'build': {
                'data': {'type': 'builds', 'id': buildId},
              },
            },
          },
        },
      );
      return;
    }
    final id = existing.first.text(key: 'id').orElse(fallback: '');
    await _send(
      method: HttpMethod.patch,
      url: '$base/v1/betaBuildLocalizations/$id',
      now: now,
      json: {
        'data': {
          'type': 'betaBuildLocalizations',
          'id': id,
          'attributes': attributes,
        },
      },
    );
  }

  Future<String> _get({
    required final String url,
    required final DateTime now,
  }) => _send(method: HttpMethod.get, url: url, now: now, json: const {});

  Future<String> _send({
    required final HttpMethod method,
    required final String url,
    required final DateTime now,
    required final Map<String, Object> json,
  }) async {
    final token = jwt.sign(
      key: credentials.key,
      header: {'kid': credentials.keyId},
      claims: claims(now: now),
    );
    final reply = await http.send(
      call: HttpCall(
        method: method,
        url: Uri.parse(url),
        headers: {
          'authorization': 'Bearer ${token.value}',
          'content-type': 'application/json',
        },
        body: json.isEmpty ? const [] : utf8.encode(jsonEncode(json)),
      ),
    );
    if (reply.status.outcome == HttpOutcome.failure) {
      throw CliFailure.general(
        message:
            'app store connect: ${method.name.toUpperCase()} $url failed '
            '(${reply.status.value}): ${reply.body}',
      );
    }
    return reply.body;
  }

  List<JsonObject> _data(final String body) =>
      switch (JsonObject.parse(text: body)) {
        JsonObjectParsed(:final object) => object.objects(key: 'data'),
        JsonListParsed() || JsonMalformed() => const [],
      };
}
