import 'package:dio/dio.dart';
import '../client/api_client_builder.dart';
import '../constants/network_constants.dart';
import '../mappers/dio_exception_mapper.dart';
import '../models/api_response.dart';

/// Fachada principal del paquete [remote_data_kit].
///
/// Actúa como único punto de entrada para el consumo de APIs HTTP,
/// encapsulando por completo los detalles de implementación internos
/// (Dio, BaseOptions, DioException). El código consumidor no requiere
/// conocer ni depender de ninguna de estas tecnologías.
class RemoteDataKit {
  final Dio _dio;
  final DioExceptionMapper _mapper;

  RemoteDataKit._({
    required Dio dio,
    required DioExceptionMapper mapper,
  })  : _dio = dio,
        _mapper = mapper;

  /// Crea una instancia configurada de [RemoteDataKit].
  ///
  /// - [baseUrl]: URL base que se antepone a todas las rutas de los métodos HTTP.
  /// - [connectTimeoutMs]: tiempo máximo en milisegundos para establecer la
  ///   conexión. Por defecto usa [NetworkConstants.defaultConnectTimeout].
  /// - [receiveTimeoutMs]: tiempo máximo en milisegundos para recibir la
  ///   respuesta completa. Por defecto usa [NetworkConstants.defaultReceiveTimeout].
  /// - [headers]: cabeceras HTTP estáticas que se envían en cada solicitud,
  ///   como `Accept`, `Content-Type` o identificadores de versión de la app.
  factory RemoteDataKit.create({
    required String baseUrl,
    int connectTimeoutMs = NetworkConstants.defaultConnectTimeout,
    int receiveTimeoutMs = NetworkConstants.defaultReceiveTimeout,
    Map<String, String>? headers,
  }) {
    final dio = ApiClientBuilder.build(
      baseUrl: baseUrl,
      connectTimeout: connectTimeoutMs,
      receiveTimeout: receiveTimeoutMs,
      headers: headers,
    );

    return RemoteDataKit._(dio: dio, mapper: const DioExceptionMapper());
  }

  /// Ejecuta una solicitud HTTP GET.
  ///
  /// - [path]: ruta relativa al [baseUrl] configurado.
  /// - [queryParameters]: parámetros que se adjuntan a la URL como query string.
  /// - [fromJson]: función de deserialización que convierte la respuesta JSON
  ///   en el tipo [T] esperado.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return ApiResponse(
        data: fromJson(response.data),
        statusCode: response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      throw _mapper.map(e);
    }
  }

  /// Ejecuta una solicitud HTTP POST.
  ///
  /// - [path]: ruta relativa al [baseUrl] configurado.
  /// - [body]: cuerpo de la solicitud, generalmente un mapa o modelo serializado.
  /// - [queryParameters]: parámetros opcionales en la URL.
  /// - [fromJson]: función de deserialización para el tipo [T] de respuesta.
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: body,
        queryParameters: queryParameters,
      );
      return ApiResponse(
        data: fromJson(response.data),
        statusCode: response.statusCode ?? 201,
      );
    } on DioException catch (e) {
      throw _mapper.map(e);
    }
  }

  /// Ejecuta una solicitud HTTP PUT.
  ///
  /// - [path]: ruta relativa al [baseUrl] configurado.
  /// - [body]: cuerpo con los datos a actualizar.
  /// - [fromJson]: función de deserialización para el tipo [T] de respuesta.
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: body);
      return ApiResponse(
        data: fromJson(response.data),
        statusCode: response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      throw _mapper.map(e);
    }
  }

  /// Ejecuta una solicitud HTTP DELETE.
  ///
  /// - [path]: ruta relativa al [baseUrl] configurado.
  /// - [fromJson]: función de deserialización para el tipo [T] de respuesta.
  Future<ApiResponse<T>> delete<T>(
    String path, {
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await _dio.delete(path);
      return ApiResponse(
        data: fromJson(response.data),
        statusCode: response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      throw _mapper.map(e);
    }
  }

  /// Expone la instancia interna de Dio.
  ///
  /// Uso avanzado exclusivamente. Este getter está pensado para
  /// integraciones que requieren acceso directo al cliente HTTP subyacente,
  /// como la inicialización de clientes Retrofit dentro del mismo paquete.
  Dio get internalDio => _dio;
}
