// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$JwtHeaderDtoToJson(JwtHeaderDto instance) =>
    <String, dynamic>{
      'alg': instance.alg,
      'typ': instance.typ,
      'kid': ?instance.kid,
    };

Map<String, dynamic> _$JwtClaimsDtoToJson(JwtClaimsDto instance) =>
    <String, dynamic>{
      'iss': ?instance.iss,
      'scope': ?instance.scope,
      'aud': ?instance.aud,
      'iat': ?instance.iat,
      'exp': ?instance.exp,
    };
