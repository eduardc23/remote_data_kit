import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/network_constants.dart';
import '../exceptions/network_exceptions.dart';

/// Traduce un [DioException] a una excepción de dominio del paquete,
/// desacoplando el resto de la aplicación de los detalles internos de Dio.
///
/// El método principal [map] aplica las siguientes reglas de conversión,
/// en orden de prioridad:
///
/// | Condición                              | Excepción resultante  |
/// |----------------------------------------|-----------------------|
/// | Timeout de conexión, recepción o envío | [NetworkException]    |
/// | Error de conexión o [SocketException]  | [NetworkException]    |
/// | Respuesta HTTP 404                     | [NotFoundException]   |
/// | Respuesta HTTP 429                     | [RateLimitException]  |
/// | Cualquier otra respuesta HTTP          | [ServerException]     |
/// | Error desconocido con [RateLimitException] dentro | [RateLimitException] |
/// | Cualquier otro error desconocido       | [ServerException]     |
///
/// Ejemplo de uso:
/// ```dart
/// final mapper = DioExceptionMapper();
///
/// try {
///   await dio.get('/endpoint');
/// } on DioException catch (e) {
///   throw mapper.map(e);
/// }
/// ```
class DioExceptionMapper {
  /// Duración de bloqueo que se aplica cuando una respuesta 429 no incluye
  /// el header `retry-after` o su valor no puede interpretarse como entero.
  ///
  /// Por defecto usa [NetworkConstants.defaultRateLimitBlock].
  final Duration defaultRateLimitBlock;

  /// Crea un [DioExceptionMapper].
  ///
  /// Se puede inyectar un [defaultRateLimitBlock] personalizado para
  /// sobrescribir el valor definido en [NetworkConstants], lo que facilita
  /// el testing sin depender de constantes globales.
  const DioExceptionMapper({
    this.defaultRateLimitBlock = NetworkConstants.defaultRateLimitBlock,
  });

  /// Convierte [e] en la excepción de dominio correspondiente.
  ///
  /// Evalúa el tipo de error y el código HTTP de la respuesta para determinar
  /// qué excepción retornar. Consulta la tabla de conversión en la documentación
  /// de la clase para conocer todas las reglas aplicadas.
  Exception map(DioException e) {
    if (_isTimeout(e)) return NetworkException();
    if (_isConnectionError(e)) return NetworkException();

    if (e.type == DioExceptionType.badResponse) {
      return _mapBadResponse(e);
    }

    if (e.error is RateLimitException) {
      return e.error as RateLimitException;
    }
    return ServerException(message: e.message);
  }

  /// Devuelve `true` si el error corresponde a cualquier tipo de timeout:
  /// de conexión ([DioExceptionType.connectionTimeout]),
  /// de recepción ([DioExceptionType.receiveTimeout]) o
  /// de envío ([DioExceptionType.sendTimeout]).
  bool _isTimeout(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout;

  /// Devuelve `true` si el error indica que no fue posible establecer
  /// la conexión, ya sea por tipo [DioExceptionType.connectionError]
  /// o porque el error subyacente es un [SocketException].
  bool _isConnectionError(DioException e) =>
      e.type == DioExceptionType.connectionError || e.error is SocketException;

  /// Interpreta una respuesta HTTP con código de error y retorna la excepción
  /// de dominio correspondiente según el código de estado:
  ///
  /// - `404` → [NotFoundException]
  /// - `429` → [RateLimitException] con la duración resuelta por [_resolveBlockDuration]
  /// - Cualquier otro código → [ServerException] con el mensaje y código de estado
  Exception _mapBadResponse(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 404) return NotFoundException();
    if (statusCode == 429) {
      final retryAfterHeader = e.response?.headers.value('retry-after');
      return RateLimitException(
        retryAfter: _resolveBlockDuration(retryAfterHeader),
      );
    }
    return ServerException(message: e.message, statusCode: statusCode);
  }

  /// Determina la duración de bloqueo a partir del valor del header `retry-after`.
  ///
  /// Si [retryAfterHeader] es `null` o no puede convertirse a entero,
  /// retorna [defaultRateLimitBlock] como valor de reserva.
  Duration _resolveBlockDuration(String? retryAfterHeader) {
    if (retryAfterHeader == null) return defaultRateLimitBlock;
    final seconds = int.tryParse(retryAfterHeader);
    return seconds != null ? Duration(seconds: seconds) : defaultRateLimitBlock;
  }
}
