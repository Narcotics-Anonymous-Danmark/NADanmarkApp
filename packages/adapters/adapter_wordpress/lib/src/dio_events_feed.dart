import 'package:adapter_wordpress/src/wordpress_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class DioEventsFeed implements EventsFeedPort {
  const DioEventsFeed({required this.dio, required this.endpoints});

  final Dio dio;
  final WordPressEndpoints endpoints;

  static const WireJson _wire = WireJson();
  static const CalendarMapper _mapper = CalendarMapper();

  @override
  Future<Outcome<List<CalendarEvent>, Failure>> events({
    required EventCategory category,
  }) async {
    final url = endpoints.calendar(category: category);
    final String? body;
    try {
      final response = await dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          contentType: Headers.jsonContentType,
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
      Ok(:final value) => switch (_mapper.events(json: value)) {
        Ok(:final value) => Ok(value: value),
        Err(:final error) => Err(error: error),
      },
      Err(:final error) => Err(error: error),
    };
  }
}
