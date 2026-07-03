import 'package:dio/dio.dart';

import '../constants/network_constants.dart';

class ApiClientBuilder {
  static Dio build({
    String? baseUrl,
    int connectTimeout = NetworkConstants.defaultConnectTimeout,
    int receiveTimeout = NetworkConstants.defaultReceiveTimeout,
    List<Interceptor>? interceptors,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
      ),
    );

    if (interceptors != null) {
      dio.interceptors.addAll(interceptors);
    }

    return dio;
  }
}