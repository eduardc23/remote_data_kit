/// Encapsula la respuesta de una llamada HTTP realizada a través de [RemoteDataKit].
///
/// [ApiResponse] es el único tipo de respuesta que el código consumidor
/// necesita conocer. Oculta por completo los tipos internos de Dio
/// (`Response<T>`, `Headers`), de modo que un cambio en la librería de red
/// subyacente no afecte al código que depende de este paquete.
///
class ApiResponse<T> {
  /// Objeto deserializado al tipo [T] definido por el consumidor.
  ///
  /// La deserialización se delega al `fromJson` que se pasa en cada
  /// llamada de [RemoteDataKit], por lo que este campo siempre llega
  /// tipado y listo para usar.
  final T data;

  /// Código de estado HTTP de la respuesta (por ejemplo, 200, 201, 404).
  ///
  /// Útil cuando la lógica del consumidor necesita distinguir entre
  /// códigos de éxito (200 vs 201) sin necesidad de inspeccionar
  /// los headers o el cuerpo de la respuesta.
  final int statusCode;

  /// Cabeceras HTTP devueltas por el servidor.
  ///
  /// Por defecto es un mapa vacío. Solo debe consultarse cuando la API
  /// transmite metadatos relevantes en los headers, como tokens de
  /// renovación, identificadores de correlación o políticas de caché.
  final Map<String, dynamic> headers;

  const ApiResponse({
    required this.data,
    required this.statusCode,
    this.headers = const {},
  });
}
