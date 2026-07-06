# Remote Data Kit Example

Este proyecto es una aplicación de ejemplo que demuestra cómo integrar y utilizar el paquete `remote_data_kit` para consumir la API de Rick & Morty de manera estandarizada y eficiente.

---

## ¿Qué hace este proyecto?

El ejemplo implementa un flujo completo de consumo de datos:
- Configura un cliente HTTP utilizando `ApiClientBuilder`.
- Utiliza `Retrofit` para la definición de los endpoints.
- Mapea errores de red automáticamente usando `DioExceptionMapper`.
- Implementa una arquitectura por capas (Data, Repository, UI).
- Muestra una lista de personajes paginada utilizando el modelo `PaginatedResponse`.

---

## Estructura del proyecto

```
lib/
 ├── data/                              # Capa de datos
 │    ├── client/                       # Clientes de API (Retrofit)
 │    ├── datasources/                  # Fuentes de datos remotas
 │    └── models/                       # Modelos de respuesta de la API (JSON)
 ├── failures/                          # Definición de errores de dominio (Failures)
 ├── repository/                        # Implementación de repositorios
 ├── ui/                                # Interfaz de usuario (Pantallas y widgets)
 └── main.dart                          # Punto de entrada de la aplicación
```

---

## Dependencias principales

| Paquete | Propósito |
|---|---|
| `remote_data_kit` | Infraestructura de red, mapeo de errores y modelos base. |
| `dio` | Cliente HTTP potente para Dart. |
| `retrofit` | Generador de código para clientes REST inspirado en Retrofit de Java. |
| `json_annotation` | Anotaciones para la serialización de JSON. |

---

## Integración completa: ejemplo con Rick & Morty API

Este es el flujo completo de cómo un proyecto consume el paquete. Todo el código de abajo vive **en tu app**, no en el paquete.

**1. Crea el cliente Retrofit con el `Dio` del paquete:**

```dart
// character_api_client.dart
@RestApi()
abstract class CharacterApiClient {
  factory CharacterApiClient(Dio dio, {String baseUrl}) = _CharacterApiClient;

  @GET('/character')
  Future<CharacterResponseModel> getCharacters({
    @Query('page') int? page,
  });
}
```

**2. Configura el cliente en tu capa de DI (en el `main.dart` del ejemplo):**

```dart
final dio = ApiClientBuilder.build(
  baseUrl: 'https://rickandmortyapi.com/api/',
);
final apiClient = CharacterApiClient(dio);
final mapper    = const DioExceptionMapper();
```

**3. Usa las excepciones del paquete en tu DataSource:**

```dart
// character_remote_data_source.dart
class CharacterRemoteDataSourceImpl implements CharacterRemoteDataSource {
  CharacterRemoteDataSourceImpl(this._client, this._mapper);

  final CharacterApiClient _client;
  final DioExceptionMapper _mapper;   // ← viene del paquete

  @override
  Future<CharacterResponseModel> getCharacters({int? page}) async {
    try {
      return await _client.getCharacters(page: page);
    } on DioException catch (e) {
      throw _mapper.map(e);           // ← lanza excepciones del paquete
    }
  }
}
```

**4. Mapea al modelo genérico del paquete en tu Repository:**

```dart
// character_repository.dart
class CharacterRepositoryImpl implements CharacterRepository {
  final CharacterRemoteDataSource _dataSource;

  CharacterRepositoryImpl(this._dataSource);

  @override
  Future<PaginatedResponse<Character>> getCharacters({int page = 1}) async {
    try {
      final response = await _dataSource.getCharacters(page: page);
      
      return PaginatedResponse(        // ← PaginatedResponse del paquete
        items: response.results,
        hasNextPage: response.info.next != null,
        currentPage: page,
        totalPages: response.info.pages,
      );
    } catch (e) {
      throw e.toFailure();
    }
  }
}
```

---

## Cómo ejecutarlo

Sigue estos pasos para poner en marcha el ejemplo:

1. **Obtener dependencias:**
   ```bash
   flutter pub get
   ```

2. **Generar código (Retrofit y JSON):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Ejecutar la aplicación:**
   ```bash
   flutter run
   ```

---

## Licencia y Autor

- **Autor**: [Eduard](https://github.com/eduardc23)
- **Licencia**: Este proyecto está bajo la Licencia MIT.
