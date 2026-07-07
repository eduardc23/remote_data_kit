/// Resultado de una llamada a la API.
/// El consumidor solo conoce esta clase, nunca DioResponse.
class ApiResponse<T> {
  final T data;
  final int statusCode;
  final Map<String, dynamic> headers;

  const ApiResponse({
    required this.data,
    required this.statusCode,
    this.headers = const {},
  });
}