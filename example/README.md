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
