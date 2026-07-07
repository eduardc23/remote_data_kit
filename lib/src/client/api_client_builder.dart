import 'package:dio/dio.dart';

class ApiClientBuilder {
  static Dio build({
    required String baseUrl,
    required int connectTimeout,
    required int receiveTimeout,
    Map<String, String>? headers,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        headers: headers,
      ),
    );

    return dio;
  }
}
