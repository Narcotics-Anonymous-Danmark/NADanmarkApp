extension type const HttpStatus(int value) {
  HttpOutcome get outcome =>
      value >= 200 && value < 300 ? HttpOutcome.success : HttpOutcome.failure;
}

enum HttpOutcome { success, failure }

final class HttpReply {
  const HttpReply({required this.status, required this.body});

  final HttpStatus status;
  final String body;
}
