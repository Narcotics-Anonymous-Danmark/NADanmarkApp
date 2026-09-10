enum HttpMethod { get, post, put, patch, delete }

final class HttpCall {
  const HttpCall({
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
  });

  final HttpMethod method;
  final Uri url;
  final Map<String, String> headers;
  final List<int> body;
}
