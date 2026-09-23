import 'dart:async';

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/src/builders/bmlt_builders.dart';
import 'package:na_testing/src/generated/recorded_bmlt.dart';

final class PortGate {
  final Completer<void> _opened = Completer<void>();

  void open() => _opened.complete();

  Future<void> get opened => _opened.future;
}

final class MeetingSearchMimic implements MeetingSearchPort {
  MeetingSearchMimic({required this.meetings, required this.municipalities});

  factory MeetingSearchMimic.recorded() => MeetingSearchMimic(
    meetings: switch (const BmltMapper().meetings(
      json: recordedDenmarkMeetings,
    )) {
      Ok(:final value) => Ok(value: value),
      Err(:final error) => Err(error: error),
    },
    municipalities: Ok(
      value: List.unmodifiable(
        recordedDenmarkMunicipalities.map(MunicipalityName.new),
      ),
    ),
  );

  Outcome<List<Meeting>, Failure> meetings;
  Outcome<List<MunicipalityName>, Failure> municipalities;
  final List<PortGate> _meetingGates = [];
  final List<PortGate> _municipalityGates = [];
  int meetingCalls = 0;
  int municipalityCalls = 0;

  PortGate holdMeetings() => _gate(into: _meetingGates);

  PortGate holdMunicipalities() => _gate(into: _municipalityGates);

  @override
  Future<Outcome<List<Meeting>, Failure>> denmarkMeetings() async {
    meetingCalls += 1;
    await _pass(gates: _meetingGates);
    return meetings;
  }

  @override
  Future<Outcome<List<MunicipalityName>, Failure>>
  denmarkMunicipalities() async {
    municipalityCalls += 1;
    await _pass(gates: _municipalityGates);
    return municipalities;
  }

  static PortGate _gate({required List<PortGate> into}) {
    final gate = PortGate();
    into.add(gate);
    return gate;
  }

  static Future<void> _pass({required List<PortGate> gates}) async {
    if (gates.isEmpty) {
      return;
    }
    await gates.removeAt(0).opened;
  }
}

final class MeetingFormatsMimic implements MeetingFormatsPort {
  MeetingFormatsMimic({required this.rows});

  factory MeetingFormatsMimic.recorded() =>
      MeetingFormatsMimic(rows: Ok(value: recordedFormatRows()));

  Outcome<List<FormatRow>, Failure> rows;
  final List<PortGate> _gates = [];
  int calls = 0;

  PortGate hold() {
    final gate = PortGate();
    _gates.add(gate);
    return gate;
  }

  @override
  Future<Outcome<List<FormatRow>, Failure>> formatRows() async {
    calls += 1;
    if (_gates.isNotEmpty) {
      await _gates.removeAt(0).opened;
    }
    return rows;
  }
}
