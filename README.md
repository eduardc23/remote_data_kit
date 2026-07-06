# Remote data kit

![Versión](https://img.shields.io/badge/versión-1.0.0-blue)
![Dart](https://img.shields.io/badge/Dart-%3E%3D3.0.0-blue)
![Dio](https://img.shields.io/badge/Dio-5.x-orange)
![Licencia](https://img.shields.io/badge/licencia-MIT-green)

Paquete Dart reutilizable que encapsula la capa de consumo de datos remotos: construcción del cliente HTTP, manejo centralizado de errores de red y modelos base genéricos para estandarizar la comunicación con cualquier API REST.

---

## Tabla de contenidos

- [¿Qué problema resuelve?](#qué-problema-resuelve)
- [¿Qué incluye?](#qué-incluye)
- [Estructura del paquete](#estructura-del-paquete)
- [Instalación](#instalación)
- [Ejemplo básico](#ejemplo-básico)
    - [Snippet integrador](#snippet-integrador)
    - [Detalle por componente](#detalle-por-componente)
        - [NetworkConstants](#networkconstants)
        - [ApiClientBuilder](#apiclientbuilder)
        - [Excepciones de red](#excepciones-de-red)
        - [DioExceptionMapper](#dioexceptionmapper)
        - [PaginatedResponse](#paginatedresponse)
- [Qué NO hace este paquete](#qué-no-hace-este-paquete)
- [Versionamiento](#versionamiento)
- [Changelog](#changelog)

---

## ¿Qué problema resuelve?

Cuando una aplicación Dart consume múltiples APIs o cuando varios proyectos de un mismo equipo necesitan comunicarse con servicios REST, suele repetirse el mismo código en cada feature y en cada proyecto:

- Configurar `Dio` con timeouts e interceptores.
- Capturar `DioException` y traducirla a errores de dominio comprensibles.
- Definir una y otra vez los mismos tipos de excepción (`NetworkException`, `ServerException`, etc.).
- Crear un modelo de respuesta paginada que varía ligeramente de un proyecto a otro.

`remote_data_kit` extrae toda esa infraestructura a un único paquete versionado, de modo que cada proyecto solo aporte lo específico de su API.

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
├── example/                     
└── lib/
    ├── remote_data_kit.dart      
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

Agrega la dependencia en el `pubspec.yaml` de tu proyecto:

```yaml
dependencies:
  remote_data_kit:
    git:
      url: https://github.com/eduardc23/remote_data_kit.git
      ref: v1.0.0
```

E importa el paquete donde lo necesites:

```dart
import 'package:remote_data_kit/remote_data_kit.dart';
```

---

## Ejemplo básico

### Snippet integrador

El siguiente ejemplo muestra cómo encadenar todos los componentes del paquete en un repositorio realista que obtiene una lista paginada de usuarios desde una API REST.

`ApiClientBuilder.build()` acepta tres parámetros opcionales además del `baseUrl`: `connectTimeout` y `receiveTimeout` (en milisegundos, con default de 30 000 ms) y una lista de `interceptors` para adjuntar lógica transversal como autenticación o logging. En el ejemplo se sobrescriben los timeouts y se inyecta un interceptor de autorización.

`PaginatedResponse<T>` provee cuatro campos listos para navegar la paginación: `items` con la lista tipada de elementos, `hasNextPage` para saber si existe una página siguiente, y los opcionales `currentPage` y `totalPages` cuando la API los incluye en su respuesta.

```dart
import 'package:dio/dio.dart';
import 'package:remote_data_kit/remote_data_kit.dart';
 
/// Repositorio que consume el endpoint /users de una API REST.
class UserRepository {
  final Dio _dio;
  final DioExceptionMapper _mapper;
 
  UserRepository()
      : _dio = ApiClientBuilder.build(
          baseUrl: 'https://api.example.com/',
          connectTimeout: 15000,  // sobrescribe el default de 30 000 ms
          receiveTimeout: 20000,
          interceptors: [
            InterceptorsWrapper(
              onRequest: (options, handler) {
                // Adjunta el token en cada solicitud de forma centralizada.
                options.headers['Authorization'] = 'Bearer <token>';
                handler.next(options);
              },
            ),
          ],
        ),
        _mapper = DioExceptionMapper();
 
  Future<PaginatedResponse<Map<String, dynamic>>> getUsers({
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/users',
        queryParameters: {'page': page},
      );
 
      return PaginatedResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      // map() inspecciona el tipo de DioException y el código HTTP para decidir
      // qué excepción de dominio lanzar: NetworkException, NotFoundException,
      // RateLimitException o ServerException. 
      throw _mapper.map(e);
    }
  }
}
 
void main() async {
  final repo = UserRepository();
 
  try {
    final result = await repo.getUsers(page: 1);
 
    // PaginatedResponse expone los campos necesarios para manejar la paginación.
    print('Página actual  : ${result.currentPage}');
    print('Total páginas  : ${result.totalPages}');
    print('¿Hay más páginas?: ${result.hasNextPage}');
    print('Usuarios en esta página: ${result.items.length}');
 
    // Navegar a la siguiente página si existe.
    if (result.hasNextPage) {
      final nextPage = (result.currentPage ?? 1) + 1;
      final nextResult = await repo.getUsers(page: nextPage);
      print('Página siguiente: ${nextResult.items}');
    }
  } on NotFoundException {
    print('Recurso no encontrado');
  } on ServerException catch (e) {
    print('Error del servidor: ${e.message} (código: ${e.statusCode})');
  } on RateLimitException catch (e) {
    print('Límite de solicitudes alcanzado. Reintenta en: ${e.retryAfter}');
  } on NetworkException {
    print('Sin conexión a internet o timeout.');
  }
}
```
 
---

### Detalle por componente

#### NetworkConstants

Centraliza los valores por defecto de red para que no queden hardcodeados en cada proyecto:

```dart
abstract final class NetworkConstants {
  static const int defaultConnectTimeout = 30000;   // ms
  static const int defaultReceiveTimeout = 30000;   // ms
  static const Duration defaultRateLimitBlock = Duration(seconds: 10);
}
```

#### ApiClientBuilder

Crea una instancia de `Dio` preconfigurada con los timeouts definidos en `NetworkConstants` e interceptores opcionales.

```dart
// Uso básico — solo con baseUrl
final dio = ApiClientBuilder.build(
  baseUrl: 'https://api.example.com/',
);

// Uso avanzado — con interceptores personalizados
final dio = ApiClientBuilder.build(
  baseUrl: 'https://api.example.com/',
  interceptors: [
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] = 'Bearer <token>';
        handler.next(options);
      },
    ),
  ],
);
```

#### Excepciones de red

El paquete expone cuatro excepciones de dominio listas para usar. Lánzalas o captúralas según la capa en la que trabajes:

```dart
// Fallo de conectividad o timeout
throw NetworkException();

// El servidor respondió con un error 5xx
throw ServerException(message: 'Internal error', statusCode: 500);

// El recurso solicitado no existe (404)
throw NotFoundException();

// El cliente superó el límite de solicitudes (429)
throw RateLimitException(retryAfter: Duration(seconds: 30));
```

#### DioExceptionMapper

Traduce cualquier `DioException` a la excepción de dominio correspondiente. Úsalo en la capa de datos para aislar el resto de la app de los detalles de Dio:

```dart
final mapper = DioExceptionMapper();

try {
  await dio.get('/endpoint');
} on DioException catch (e) {
  // map() devuelve la excepción apropiada según el tipo de error y el código HTTP.
  throw mapper.map(e);
}
```

#### PaginatedResponse

Modelo genérico que representa cualquier respuesta paginada. El parámetro de tipo `T` define el tipo de cada elemento de la lista:

```dart
// Deserializar desde JSON con un mapper personalizado
final response = PaginatedResponse<User>.fromJson(
  responseData,
  (json) => User.fromJson(json as Map<String, dynamic>),
);

print(response.data);    // List<User>
print(response.page);    // página actual
print(response.total);   // total de registros
```

---

#### PaginatedResponse

Modelo genérico que representa cualquier respuesta paginada. El parámetro de tipo `T` define el tipo de cada elemento de la lista. Expone cuatro campos:

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `items` | `List<T>` | ✅ | Elementos de la página actual |
| `hasNextPage` | `bool` | ✅ | Indica si existe una página siguiente |
| `currentPage` | `int?` | ❌ | Número de la página actual (si la API lo retorna) |
| `totalPages` | `int?` | ❌ | Total de páginas disponibles (si la API lo retorna) |

##### Diseño agnóstico al backend

Distintas APIs estructuran la paginación de formas muy diferentes:

```json
{ "info": {              { "total": 100,          { "meta": {
    "pages": 42,             "page": 1,               "total_pages": 5,
    "next": "url"            "per_page": 10,          "current": 2
  },                         "data": []           },
  "results": []          }                         "items": []
}                                                 }
```

`PaginatedResponse` no modela la estructura de ninguna API en particular, sino un contrato genérico y estable. La app es responsable de convertir la respuesta específica del backend a ese contrato mediante un mapper:

```dart
// remote_data_kit → solo define el contrato
class PaginatedResponse<T> {
  final List<T> items;
  final bool hasNextPage;
  final int? currentPage;
  final int? totalPages;
}

// Tu app → convierte la respuesta específica de tu API al contrato
class UserMapper {
  static PaginatedResponse<User> fromModel(UserResponseModel model) {
    return PaginatedResponse(
      items: model.results.map(User.fromModel).toList(),
      hasNextPage: model.info.next != null,  // lógica específica de tu API
      totalPages: model.info.pages,
      currentPage: null,                     // si tu API no retorna este dato
    );
  }
}
```

De este modo el paquete permanece desacoplado de cualquier API concreta, y cada proyecto solo aporta el mapper que traduce su respuesta al contrato.

##### Uso

```dart
final response = PaginatedResponse<User>.fromJson(
  responseData,
  (json) => User.fromJson(json as Map<String, dynamic>),
);
 
print(response.items);        // List<User> — elementos de esta página
print(response.hasNextPage);  // true / false
print(response.currentPage);  // ej. 1
print(response.totalPages);   // ej. 10
 
// Patrón típico de navegación
if (response.hasNextPage) {
  final nextPage = (response.currentPage ?? 1) + 1;
  // ... solicitar la siguiente página
}
```
 
---

## Qué NO hace este paquete

| Responsabilidad | ¿Dónde va? |
|---|---|
| Clientes Retrofit específicos | Tu app |
| Modelos de respuesta crudos (JSON) | Tu app |
| Mappers de respuesta cruda → dominio | Tu app |
| Clases `Failure` de dominio | Tu app |

---

## Changelog

Consulta el archivo `CHANGELOG.md`.

## Licencia y Autor

- **Autor**: [Eduard](https://github.com/eduardc23)
- **Licencia**: Este proyecto está bajo la Licencia MIT.