import 'package:http/http.dart' as http;
import 'package:na_cli/src/http/http_call.dart';
import 'package:na_cli/src/http/http_reply.dart';
import 'package:na_cli/src/ports/http_transport.dart';

final class HttpClientTransport implements HttpTransport {
  const HttpClientTransport();

  @override
  Future<HttpReply> send({required final HttpCall call}) async {
    final request = http.Request(_methodName(call.method), call.url)
      ..headers.addAll(call.headers)
      ..bodyBytes = call.body;
    final client = http.Client();
    try {
      final streamed = await client.send(request);
      final response = await http.Response.fromStream(streamed);
      return HttpReply(
        status: HttpStatus(response.statusCode),
        body: response.body,
      );
    } finally {
      client.close();
    }
  }

  String _methodName(final HttpMethod method) => switch (method) {
    HttpMethod.get => 'GET',
    HttpMethod.post => 'POST',
    HttpMethod.put => 'PUT',
    HttpMethod.patch => 'PATCH',
    HttpMethod.delete => 'DELETE',
  };
}
