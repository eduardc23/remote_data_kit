/// Modelo genérico que representa una respuesta paginada de cualquier API REST.
///
/// El parámetro de tipo [T] define el tipo de cada elemento dentro de [items],
/// lo que permite reutilizar este modelo con cualquier entidad de dominio sin
/// duplicar lógica de paginación.
///
/// ## Diseño agnóstico al backend
///
/// Distintas APIs estructuran la paginación de formas muy diferentes:
///
/// ```json
/// // Rick & Morty          // JSONPlaceholder       // Otra API
/// { "info": {              { "total": 100,          { "meta": {
///     "pages": 42,             "page": 1,               "total_pages": 5,
///     "next": "url"            "per_page": 10,          "current": 2
///   },                         "data": []           },
///   "results": []          }                         "items": []
/// }                                                 }
/// ```
///
/// `PaginatedResponse` no modela la estructura de ninguna API en particular,
/// sino un contrato genérico y estable. La app es responsable de convertir
/// la respuesta específica del backend a ese contrato mediante un mapper:
///
/// ```dart
/// // remote_data_kit → define el contrato
/// PaginatedResponse<Character>(
///   items: model.results.map(Character.fromModel).toList(),
///   hasNextPage: model.info.next != null,  // lógica específica de R&M
///   totalPages: model.info.pages,
///   currentPage: null,                     // R&M no lo retorna
/// );
/// ```
///
/// De este modo el paquete permanece desacoplado de cualquier API concreta,
/// y cada proyecto solo aporta el mapper que traduce su respuesta al contrato.
///
class PaginatedResponse<T> {
  /// Elementos correspondientes a la página actual.
  final List<T> items;

  /// Indica si existe al menos una página siguiente disponible.
  ///
  /// Úsalo para habilitar o deshabilitar controles de navegación en la UI,
  /// o para detener la carga incremental en un scroll infinito.
  final bool hasNextPage;

  /// Número de la página actual, si la API lo incluye en su respuesta.
  ///
  /// Puede ser `null` cuando el servidor no retorna este dato. En ese caso,
  /// lleva el control de la página actual desde la capa que realiza la solicitud.
  final int? currentPage;

  /// Total de páginas disponibles, si la API lo incluye en su respuesta.
  ///
  /// Puede ser `null` cuando el servidor no retorna este dato. En ese caso,
  /// usa [hasNextPage] como única fuente de verdad para la navegación.
  final int? totalPages;

  const PaginatedResponse({
    required this.items,
    required this.hasNextPage,
    this.currentPage,
    this.totalPages,
  });
}