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