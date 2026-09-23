import 'package:adapter_bmlt/src/bmlt_endpoints.dart';
import 'package:adapter_bmlt/src/bmlt_json.dart';
import 'package:dio/dio.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class DioMeetingSearch implements MeetingSearchPort {
  DioMeetingSearch({required Dio dio, required this.endpoints})
    : _json = BmltJson(dio: dio);

  final BmltEndpoints endpoints;
  final BmltJson _json;

  static const BmltMapper _reader = BmltMapper();

  @override
  Future<Outcome<List<Meeting>, Failure>> denmarkMeetings() async =>
      switch (await _json.get(url: endpoints.allDenmarkMeetings)) {
        Ok(:final value) => _widen(outcome: _reader.meetings(json: value)),
        Err(:final error) => Err(error: error),
      };

  @override
  Future<Outcome<List<MunicipalityName>, Failure>>
  denmarkMunicipalities() async => switch (await _json.get(
    url: endpoints.denmarkMunicipalities,
  )) {
    Ok(:final value) => _widen(outcome: _reader.municipalities(json: value)),
    Err(:final error) => Err(error: error),
  };

  static Outcome<T, Failure> _widen<T>({
    required Outcome<T, DecodeFailure> outcome,
  }) => switch (outcome) {
    Ok(:final value) => Ok(value: value),
    Err(:final error) => Err(error: error),
  };
}
