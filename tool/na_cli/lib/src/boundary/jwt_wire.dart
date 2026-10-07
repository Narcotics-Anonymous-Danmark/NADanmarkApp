import 'package:json_annotation/json_annotation.dart';
import 'package:na_cli/src/boundary/wire_json.dart';

part 'jwt_wire.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
final class JwtHeaderDto {
  const JwtHeaderDto({required this.alg, required this.typ, this.kid});

  final String alg;
  final String typ;
  final String? kid;

  WireObject toJson() => _$JwtHeaderDtoToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
final class JwtClaimsDto {
  const JwtClaimsDto({this.iss, this.scope, this.aud, this.iat, this.exp});

  final String? iss;
  final String? scope;
  final String? aud;
  final int? iat;
  final int? exp;

  WireObject toJson() => _$JwtClaimsDtoToJson(this);
}
