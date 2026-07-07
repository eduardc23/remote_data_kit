## [2.0.0] - 2026-07-07

### Añadido
- `RemoteDataKit` como fachada principal del paquete, actuando como único punto de entrada para el consumo de APIs HTTP.
- `ApiResponse<T>` como modelo genérico para encapsular respuestas HTTP sin exponer tipos internos de Dio.
- Métodos HTTP genéricos en `RemoteDataKit`: `get`, `post`, `put` y `delete`, con soporte para deserialización mediante `fromJson`.

### Cambiado
- `ApiClientBuilder` pasa a ser un detalle de implementación interno; el consumidor ya no lo instancia directamente.
- `DioExceptionMapper` pasa a ser un detalle de implementación interno; las excepciones de red se obtienen únicamente a través de `NetworkException`.
- Los `headers` estáticos ahora se configuran como `Map<String, String>` directamente en `RemoteDataKit.create`, en lugar de mediante interceptores.

### Ruptura de compatibilidad
- El consumidor ya no debe instalar ni importar `dio` directamente; toda interacción ocurre a través de `RemoteDataKit`.
- `ApiClientBuilder` y `DioExceptionMapper` dejaron de ser parte de la API pública.

---


## [1.0.0] - 2026-07-03

### Añadido
- `ApiClientBuilder` para la construcción y configuración de clientes `Dio` 5.x con soporte para interceptores.
- `DioExceptionMapper` para traducir `DioException` a excepciones de dominio con duración configurable para rate limiting.
- Jerarquía de excepciones de red:
    - `NetworkException`
    - `ServerException`
    - `NotFoundException`
    - `RateLimitException`
- `PaginatedResponse<T>` como modelo genérico para respuestas paginadas.
- `NetworkConstants` para centralizar constantes de red, como timeouts y duración por defecto del rate limit.