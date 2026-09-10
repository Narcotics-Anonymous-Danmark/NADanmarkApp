import 'package:na_cli/src/http/http_call.dart';
import 'package:na_cli/src/http/http_reply.dart';

abstract interface class HttpTransport {
  Future<HttpReply> send({required HttpCall call});
}
