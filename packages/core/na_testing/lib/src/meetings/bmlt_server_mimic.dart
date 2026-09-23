import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_testing/src/builders/bmlt_builders.dart';
import 'package:na_testing/src/generated/recorded_bmlt.dart';

enum BmltEndpoint { meetings, municipalities, formatsDanish, formatsEnglish }

sealed class BmltReply {
  const BmltReply();
}

final class BmltRows extends BmltReply {
  const BmltRows({required this.rows});

  BmltRows.meetings({required List<BmltMeetingDto> meetings})
    : rows = List.unmodifiable(meetings.map((dto) => dto.toJson()));

  BmltRows.municipalities({
    required List<BmltMunicipalityDto> municipalities,
  }) : rows = List.unmodifiable(municipalities.map((dto) => dto.toJson()));

  BmltRows.formats({required List<BmltFormatDto> formats})
    : rows = List.unmodifiable(formats.map((dto) => dto.toJson()));

  final List<WireObject> rows;
}

final class BmltNoResults extends BmltReply {
  const BmltNoResults();
}

final class BmltServerError extends BmltReply {
  const BmltServerError({required this.statusCode});

  final int statusCode;
}

final class BmltUnreachable extends BmltReply {
  const BmltUnreachable();
}

final class BmltMalformed extends BmltReply {
  const BmltMalformed();
}

final class BmltHeld extends BmltReply {
  BmltHeld({required this.then});

  final BmltReply then;
  final Completer<void> _release = Completer<void>();

  void release() => _release.complete();
}

final class BmltServerMimic implements HttpClientAdapter {
  BmltServerMimic()
    : _replies = {
        BmltEndpoint.meetings: const BmltRows(rows: recordedDenmarkMeetings),
        BmltEndpoint.municipalities: BmltRows.municipalities(
          municipalities: recordedMunicipalityDtos(),
        ),
        BmltEndpoint.formatsDanish: const BmltRows(rows: recordedFormatsDa),
        BmltEndpoint.formatsEnglish: const BmltRows(rows: recordedFormatsEn),
      };

  final Map<BmltEndpoint, BmltReply> _replies;
  final List<Uri> requests = [];

  void serve({required BmltEndpoint endpoint, required BmltReply reply}) =>
      _replies[endpoint] = reply;

  BmltHeld hold({required BmltEndpoint endpoint}) {
    final held = BmltHeld(then: _replies[endpoint] ?? const BmltNoResults());
    _replies[endpoint] = held;
    return held;
  }

  List<Uri> requestsTo({required BmltEndpoint endpoint}) => List.unmodifiable(
    requests.where(
      (uri) => switch (_routeOf(uri: uri)) {
        _Routed(endpoint: final routed) => routed == endpoint,
        _Unrouted() => false,
      },
    ),
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    requests.add(uri);
    return switch (_routeOf(uri: uri)) {
      _Routed(:final endpoint) => _answer(
        reply: _replies[endpoint] ?? const BmltNoResults(),
        options: options,
      ),
      _Unrouted() => _answer(
        reply: const BmltServerError(statusCode: 404),
        options: options,
      ),
    };
  }

  Future<ResponseBody> _answer({
    required BmltReply reply,
    required RequestOptions options,
  }) async {
    switch (reply) {
      case BmltRows(:final rows):
        return _json(body: jsonEncode(rows), statusCode: 200);
      case BmltNoResults():
        return _json(body: '{}', statusCode: 200);
      case BmltServerError(:final statusCode):
        return _json(body: '{"error":"mimic"}', statusCode: statusCode);
      case BmltMalformed():
        return _json(body: '<html>', statusCode: 200);
      case BmltUnreachable():
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'BmltServerMimic is unreachable',
        );
      case BmltHeld(:final then, :final _release):
        await _release.future;
        return _answer(reply: then, options: options);
    }
  }

  @override
  void close({bool force = false}) {}

  static _Route _routeOf({required Uri uri}) {
    final query = uri.queryParameters;
    return switch ((
      query['switcher'],
      query['data_field_key'],
      query['lang_enum'],
    )) {
      ('GetSearchResults', null, _) => const _Routed(
        endpoint: BmltEndpoint.meetings,
      ),
      ('GetSearchResults', 'location_municipality', _) => const _Routed(
        endpoint: BmltEndpoint.municipalities,
      ),
      ('GetFormats', _, 'en') => const _Routed(
        endpoint: BmltEndpoint.formatsEnglish,
      ),
      ('GetFormats', _, 'da' || null) => const _Routed(
        endpoint: BmltEndpoint.formatsDanish,
      ),
      _ => const _Unrouted(),
    };
  }

  static ResponseBody _json({required String body, required int statusCode}) =>
      ResponseBody.fromBytes(
        utf8.encode(body),
        statusCode,
        headers: {
          Headers.contentTypeHeader: ['application/json; charset=utf-8'],
        },
      );
}

sealed class _Route {
  const _Route();
}

final class _Routed extends _Route {
  const _Routed({required this.endpoint});

  final BmltEndpoint endpoint;
}

final class _Unrouted extends _Route {
  const _Unrouted();
}
