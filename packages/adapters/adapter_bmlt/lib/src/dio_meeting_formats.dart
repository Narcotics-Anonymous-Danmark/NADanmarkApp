import 'package:adapter_bmlt/src/bmlt_endpoints.dart';
import 'package:adapter_bmlt/src/bmlt_json.dart';
import 'package:dio/dio.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class DioMeetingFormats implements MeetingFormatsPort {
  DioMeetingFormats({required Dio dio, required this.endpoints})
    : _json = BmltJson(dio: dio);

  final BmltEndpoints endpoints;
  final BmltJson _json;

  static const BmltMapper _mapper = BmltMapper();

  @override
  Future<Outcome<List<FormatRow>, Failure>> formatRows() async {
    final languages = await Future.wait([
      _rows(url: endpoints.danishFormats),
      _rows(url: endpoints.englishFormats),
    ]);
    final failures = languages.whereType<Err<List<FormatRow>, Failure>>();
    if (failures.isNotEmpty) {
      return Err(error: failures.first.error);
    }
    return Ok(
      value: List.unmodifiable(
        languages.whereType<Ok<List<FormatRow>, Failure>>().expand(
          (ok) => ok.value,
        ),
      ),
    );
  }

  Future<Outcome<List<FormatRow>, Failure>> _rows({
    required String url,
  }) async => switch (await _json.get(url: url)) {
    Ok(:final value) => switch (_mapper.formatRows(json: value)) {
      Ok(:final value) => Ok(value: value),
      Err(:final error) => Err(error: error),
    },
    Err(:final error) => Err(error: error),
  };
}
