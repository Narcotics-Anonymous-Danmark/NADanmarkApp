import 'package:dio/dio.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';

final class BmltJson {
  const BmltJson({required this.dio});

  static const WireJson _wire = WireJson();

  final Dio dio;

  Future<Outcome<Object?, Failure>> get({required String url}) async {
    final String? body;
    try {
      final response = await dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      body = response.data;
    } on DioException catch (error) {
      return Err(error: NetworkFailure(detail: '$url: ${error.type.name}'));
    }
    return switch (_wire.parse(text: body ?? '', context: url)) {
      Ok(:final value) => Ok(value: value),
      Err(:final error) => Err(error: error),
    };
  }
}
