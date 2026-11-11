import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/src/speaks/speak_builders.dart';

extension type const MimicCredentials(String userAndPassword) {
  String get header => 'Basic ${base64.encode(utf8.encode(userAndPassword))}';
}

extension type const HttpStatus(int code) {}

const MimicCredentials testWordPressCredentials = MimicCredentials('test:test');

sealed class WordPressReply {
  const WordPressReply();
}

final class SpeakGroups extends WordPressReply {
  const SpeakGroups({required this.groups});

  final List<SpeakGroupDto> groups;
}

final class WordPressEmptyObject extends WordPressReply {
  const WordPressEmptyObject();
}

final class WordPressError extends WordPressReply {
  const WordPressError({required this.status});

  final HttpStatus status;
}

final class WordPressUnreachable extends WordPressReply {
  const WordPressUnreachable();
}

final class WordPressMalformed extends WordPressReply {
  const WordPressMalformed();
}

final class WordPressHeld extends WordPressReply {
  WordPressHeld({required this.then});

  final WordPressReply then;
  final Completer<void> _release = Completer<void>();

  void release() => _release.complete();
}

enum Authorisation { accepted, rejected, missing }

final class WordPressRequest {
  const WordPressRequest({required this.uri, required this.authorisation});

  final Uri uri;
  final Authorisation authorisation;
}

final class WordPressMimic implements HttpClientAdapter {
  WordPressMimic({this.credentials = testWordPressCredentials})
    : _replies = {
        SpeakLanguage.danish: SpeakGroups(groups: sampleDanishSpeaks),
        SpeakLanguage.english: SpeakGroups(groups: sampleEnglishSpeaks),
      };

  static const String speaksPath = '/wp-json/wp/v2/speaks';

  final MimicCredentials credentials;
  final Map<SpeakLanguage, WordPressReply> _replies;
  final List<WordPressRequest> requests = [];

  void serve({
    required SpeakLanguage language,
    required WordPressReply reply,
  }) => _replies[language] = reply;

  void serveBoth({required WordPressReply reply}) {
    for (final language in SpeakLanguage.values) {
      serve(language: language, reply: reply);
    }
  }

  WordPressHeld hold({required SpeakLanguage language}) {
    final held = WordPressHeld(
      then: _replies[language] ?? const WordPressEmptyObject(),
    );
    _replies[language] = held;
    return held;
  }

  List<WordPressRequest> requestsFor({required SpeakLanguage language}) =>
      List.unmodifiable(
        requests.where(
          (request) =>
              request.uri.queryParameters['excerpt[]'] ==
              language.excerpt.value,
        ),
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    final authorisation = switch (options.headers['Authorization']) {
      final String header when header == credentials.header =>
        Authorisation.accepted,
      String() => Authorisation.rejected,
      Object() || null => Authorisation.missing,
    };
    requests.add(WordPressRequest(uri: uri, authorisation: authorisation));
    final language = SpeakLanguage.values.where(
      (language) =>
          uri.path == speaksPath &&
          uri.queryParameters['excerpt[]'] == language.excerpt.value,
    );
    if (language.isEmpty) {
      return _json(
        body: '{"code":"rest_no_route"}',
        status: const HttpStatus(404),
      );
    }
    return switch (authorisation) {
      Authorisation.accepted => _answer(
        reply: _replies[language.first] ?? const WordPressEmptyObject(),
        options: options,
      ),
      Authorisation.rejected || Authorisation.missing => _json(
        body: '{"code":"rest_forbidden"}',
        status: const HttpStatus(401),
      ),
    };
  }

  Future<ResponseBody> _answer({
    required WordPressReply reply,
    required RequestOptions options,
  }) async {
    switch (reply) {
      case SpeakGroups(:final groups):
        return _json(
          body: jsonEncode(groups.map((group) => group.toJson()).toList()),
          status: const HttpStatus(200),
        );
      case WordPressEmptyObject():
        return _json(body: '{}', status: const HttpStatus(200));
      case WordPressError(:final status):
        return _json(body: '{"code":"mimic"}', status: status);
      case WordPressMalformed():
        return _json(body: '<html>', status: const HttpStatus(200));
      case WordPressUnreachable():
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'WordPressMimic is unreachable',
        );
      case WordPressHeld(:final then, :final _release):
        await _release.future;
        return _answer(reply: then, options: options);
    }
  }

  @override
  void close({bool force = false}) {}

  static ResponseBody _json({
    required String body,
    required HttpStatus status,
  }) => ResponseBody.fromBytes(
    utf8.encode(body),
    status.code,
    headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    },
  );
}
