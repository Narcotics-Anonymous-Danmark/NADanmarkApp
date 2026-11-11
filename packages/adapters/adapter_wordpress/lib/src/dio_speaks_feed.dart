import 'package:adapter_wordpress/src/wordpress_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class DioSpeaksFeed implements SpeaksFeedPort {
  const DioSpeaksFeed({required this.dio, required this.endpoints});

  final Dio dio;
  final WordPressEndpoints endpoints;

  static const WireJson _wire = WireJson();
  static const SpeaksMapper _mapper = SpeaksMapper();

  @override
  Future<Outcome<List<FeedGroup>, Failure>> feed({
    required SpeakLanguage language,
  }) async {
    final url = endpoints.speaks(language: language);
    final String? body;
    try {
      final response = await dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: endpoints.credentials.headers,
        ),
      );
      body = response.data;
    } on DioException catch (error) {
      return Err(
        error: NetworkFailure(
          detail: '$url: ${error.type.name} ${error.response?.statusCode ?? ''}'
              .trim(),
        ),
      );
    }
    return switch (_wire.parse(text: body ?? '', context: url)) {
      Ok(:final value) => switch (_mapper.groups(
        json: value,
        language: language,
      )) {
        Ok(:final value) => Ok(value: value),
        Err(:final error) => Err(error: error),
      },
      Err(:final error) => Err(error: error),
    };
  }
}
