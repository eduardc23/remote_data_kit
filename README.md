# remote_data_kit

![Versión](https://img.shields.io/badge/versión-1.0.0-blue)
![Dart](https://img.shields.io/badge/Dart-%3E%3D3.0.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.10.0-blue)
![Dio](https://img.shields.io/badge/Dio-5.x-orange)
![Licencia](https://img.shields.io/badge/licencia-MIT-green)

Paquete Dart/Flutter reutilizable que encapsula la capa de consumo de datos remotos: construcción del cliente HTTP, manejo centralizado de errores de red y modelos base genéricos para estandarizar la comunicación con cualquier API REST.
 
---

## Tabla de contenidos

- [¿Qué problema resuelve?](#qué-problema-resuelve)
- [¿Qué incluye?](#qué-incluye)
- [Estructura del paquete](#estructura-del-paquete)
- [Instalación](#instalación)
- [Uso](#uso)
  - [NetworkConstants](#networkconstants)
  - [ApiClientBuilder](#apiclientbuilder)
  - [Excepciones de red](#excepciones-de-red)
  - [DioExceptionMapper](#dioexceptionmapper)
  - [PaginatedResponse](#paginatedresponse)
- [Integración completa: ejemplo con Rick & Morty API](#integración-completa-ejemplo-con-rick--morty-api)
- [Qué NO hace este paquete](#qué-no-hace-este-paquete)
- [Versionamiento](#versionamiento)
- [Changelog](#changelog)
---

## ¿Qué problema resuelve?

Cuando una aplicación Flutter consume múltiples APIs o cuando varios proyectos de un mismo equipo necesitan comunicarse con servicios REST, suele repetirse el mismo código en cada feature y en cada proyecto:

- Configurar `Dio` con timeouts y interceptores.
- Capturar `DioException` y traducirla a errores de dominio comprensibles.
- Definir una y otra vez los mismos tipos de excepción (`NetworkException`, `ServerException`, etc.).
- Crear un modelo de respuesta paginada que varía ligeramente de un proyecto a otro.
  `remote_data_kit` extrae toda esa infraestructura a un único paquete versionado, de modo que cada proyecto solo aporte lo específico de su API: el cliente Retrofit, sus modelos de respuesta y sus propios mappers.

---

## ¿Qué incluye?

| Componente | Descripción |
|---|---|
| `ApiClientBuilder` | Construye y configura una instancia de `Dio` lista para usar |
| `DioExceptionMapper` | Traduce `DioException` a excepciones propias del dominio |
| Excepciones base | `NetworkException`, `ServerException`, `NotFoundException`, `RateLimitException` |
| `PaginatedResponse<T>` | Modelo genérico para respuestas paginadas de cualquier API |
| `NetworkConstants` | Constantes de red reutilizables (timeouts, duración de rate limit) |
 
---

## Estructura del paquete

```
remote_data_kit/
├── CHANGELOG.md
├── README.md
├── pubspec.yaml
└── lib/
    ├── remote_data_kit.dart          # Barrel file — exporta todo lo público
    └── src/
        ├── client/
        │   └── api_client_builder.dart
        ├── constants/
        │   └── network_constants.dart
        ├── exceptions/
        │   └── network_exceptions.dart
        ├── mappers/
        │   └── dio_exception_mapper.dart
        └── models/
            └── paginated_response.dart
```
 
---

## Instalación

Agrega la dependencia en el `pubspec.yaml` de tu proyecto apuntando al repositorio Git. Se recomienda fijar una etiqueta (`ref`) para garantizar builds reproducibles:

```yaml
dependencies:
  remote_data_kit:
    git:
      url: https://github.com/eduardc23/remote_data_kit.git
      ref: v1.0.0  
```

Luego ejecuta:

```bash
flutter pub get
```

E importa el paquete donde lo necesites:

```dart
import 'package:remote_data_kit/remote_data_kit.dart';
```
 
---

## Uso

### NetworkConstants

Centraliza los valores por defecto de red:

```dart
abstract final class NetworkConstants {
  static const int defaultConnectTimeout = 30000;   // ms
  static const int defaultReceiveTimeout = 30000;   // ms
  static const Duration defaultRateLimitBlock = Duration(seconds: 10);
}
```

Puedes referenciar estas constantes directamente o usarlas como valores por defecto al construir el cliente.
 
---

### ApiClientBuilder

Crea una instancia de `Dio` preconfigurada con timeouts e interceptores opcionales. Los valores por defecto provienen de `NetworkConstants`.

```dart
final dio = ApiClientBuilder.build(
  baseUrl: 'https://rickandmortyapi.com/api/',
);
```

Con configuración personalizada:

```dart
final dio = ApiClientBuilder.build(
  connectTimeout: 15000,        // sobreescribe el default
  receiveTimeout: 15000,
  interceptors: [
    LogInterceptor(responseBody: true),
    MyAuthInterceptor(),
  ],
);
```

| Parámetro | Tipo | Default | Descripción |
|---|---|---|---|
| `connectTimeout` | `int` | `30000` | Timeout de conexión en ms |
| `receiveTimeout` | `int` | `30000` | Timeout de recepción en ms |
| `interceptors` | `List<Interceptor>?` | `null` | Interceptores adicionales de Dio |
 
---

### Excepciones de red

El paquete define las siguientes excepciones de dominio. Tu capa de datos las lanzará y tu capa de repositorio las capturará para convertirlas en `Failure`:

```dart
// Sin conexión o timeout
throw NetworkException();
 
// Error del servidor (5xx)
throw ServerException(message: 'Internal error', statusCode: 500);
 
// Recurso no encontrado (404)
throw NotFoundException();
 
// Límite de peticiones excedido (429)
throw RateLimitException(retryAfter: Duration(seconds: 30));
```
 
---

### DioExceptionMapper

Traduce cualquier `DioException` a la excepción de dominio correspondiente. Se instancia una sola vez y se inyecta donde se necesite:

```dart
final mapper = DioExceptionMapper();
 
// Con duración personalizada para el rate limit
final mapper = DioExceptionMapper(
  defaultRateLimitBlock: Duration(seconds: 30),
);
```

Uso dentro de un `RemoteDataSource`:

```dart
try {
  return await apiClient.getCharacters(page: page);
} on DioException catch (e) {
  throw mapper.map(e);   // lanza NetworkException, ServerException, etc.
}
```

**Tabla de mapeo:**

| Tipo de error | Excepción resultante |
|---|---|
| Connection / send / receive timeout | `NetworkException` |
| Sin conexión / `SocketException` | `NetworkException` |
| Respuesta 404 | `NotFoundException` |
| Respuesta 429 | `RateLimitException(retryAfter)` |
| Respuesta 5xx | `ServerException(statusCode, message)` |
| Otros `DioException` | `ServerException(message)` |
 
---

### PaginatedResponse

Modelo genérico que representa cualquier respuesta paginada, independientemente de la estructura que use la API origen. Tu proyecto es responsable de mapear la respuesta cruda a este contrato:

```dart
class PaginatedResponse<T> {
  final List<T> items;
  final bool hasNextPage;
  final int? currentPage;
  final int? totalPages;
 
  const PaginatedResponse({
    required this.items,
    required this.hasNextPage,
    this.currentPage,
    this.totalPages,
  });
}
```

La API puede llamar a sus campos `results`, `data`, `items` o `registros`: eso no importa, el mapper de tu proyecto se encarga de la traducción.
 
---

## Qué NO hace este paquete

Para mantener el paquete desacoplado y reutilizable, las siguientes responsabilidades quedan **deliberadamente fuera**:

| Responsabilidad | ¿Dónde va? |
|---|---|
| Clientes Retrofit específicos de cada API | Tu app |
| Modelos de respuesta crudos (JSON) | Tu app |
| Mappers de respuesta cruda → dominio | Tu app |
| Clases `Failure` de dominio | Tu app |
| Política de reintentos (Riverpod, BLoC, etc.) | Tu app |
| Inyección de dependencias | Tu app |
 
---

## Changelog

Consulta el archivo `CHANGELOG.md` para conocer el historial de cambios del paquete.

## Licencia y Autor

- **Autor**: [Eduard](https://github.com/eduardc23)
- **Licencia**: Este proyecto está bajo la Licencia MIT.
