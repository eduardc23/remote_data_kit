import 'dart:io';

import 'package:dio/dio.dart';
import 'package:remote_data_kit/remote_data_kit.dart';
import 'package:remote_data_kit/src/client/api_client_builder.dart';
import 'package:remote_data_kit/src/constants/network_constants.dart';
import 'package:remote_data_kit/src/mappers/dio_exception_mapper.dart';
import 'package:test/test.dart';

void main() {
  // ─────────────────────────────────────────────
  // ApiClientBuilder
  // ─────────────────────────────────────────────
  group('ApiClientBuilder', () {
    test('construye un cliente Dio con la configuración proporcionada', () {
      // Act
      final client = ApiClientBuilder.build(
        baseUrl: 'https://example.com',
        connectTimeout: 5000,
        receiveTimeout: 7000,
      );

      // Assert
      expect(client.options.baseUrl, 'https://example.com');
      expect(client.options.connectTimeout, const Duration(milliseconds: 5000));
      expect(client.options.receiveTimeout, const Duration(milliseconds: 7000));
    });

    test('Aplica headers cuando se proporcionan', () {
      // Act
      final client = ApiClientBuilder.build(
        baseUrl: 'https://example.com',
        connectTimeout: 5000,
        receiveTimeout: 7000,
        headers: {'X-Test': 'true'},
      );

      // Assert
      expect(client.options.headers['X-Test'], 'true');
    });
  });

  // ─────────────────────────────────────────────
  // DioExceptionMapper
  // ─────────────────────────────────────────────
  group('DioExceptionMapper', () {
    late DioExceptionMapper mapper;

    setUp(() {
      mapper = const DioExceptionMapper();
    });

    test('convierte un timeout de conexión en NetworkException', () {
      // Arrange
      final exception = DioException(
        requestOptions: RequestOptions(path: '/users'),
        type: DioExceptionType.connectionTimeout,
      );

      // Act
      final result = mapper.map(exception);

      // Assert
      expect(result, isA<NetworkException>());
    });

    test('convierte un timeout de recepción en NetworkException', () {
      // Arrange
      final exception = DioException(
        requestOptions: RequestOptions(path: '/users'),
        type: DioExceptionType.receiveTimeout,
      );

      // Act
      final result = mapper.map(exception);

      // Assert
      expect(result, isA<NetworkException>());
    });

    test('convierte un error de conexión en NetworkException', () {
      // Arrange
      final exception = DioException(
        requestOptions: RequestOptions(path: '/users'),
        type: DioExceptionType.connectionError,
        error: const SocketException('Fallo de conexión'),
      );

      // Act
      final result = mapper.map(exception);

      // Assert
      expect(result, isA<NetworkException>());
    });

    test('convierte una respuesta 404 en NotFoundException', () {
      // Arrange
      final exception = DioException(
        requestOptions: RequestOptions(path: '/users/1'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/users/1'),
          statusCode: 404,
        ),
      );

      // Act
      final result = mapper.map(exception);

      // Assert
      expect(result, isA<NotFoundException>());
    });

    test(
      'convierte una respuesta 429 en RateLimitException y lee el header retry-after',
      () {
        // Arrange
        final exception = DioException(
          requestOptions: RequestOptions(path: '/users'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/users'),
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['45'],
            }),
          ),
        );

        // Act
        final result = mapper.map(exception);

        // Assert
        expect(result, isA<RateLimitException>());
        expect(
          (result as RateLimitException).retryAfter,
          const Duration(seconds: 45),
        );
      },
    );

    test(
      'usa la duración de bloqueo por defecto cuando el header retry-after no está presente',
      () {
        // Arrange
        final exception = DioException(
          requestOptions: RequestOptions(path: '/users'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/users'),
            statusCode: 429,
          ),
        );

        // Act
        final result = mapper.map(exception);

        // Assert
        expect(result, isA<RateLimitException>());
        expect(
          (result as RateLimitException).retryAfter,
          NetworkConstants.defaultRateLimitBlock,
        );
      },
    );

    test(
      'convierte respuestas 5xx en ServerException y conserva el código de estado',
      () {
        // Arrange
        final exception = DioException(
          requestOptions: RequestOptions(path: '/users'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/users'),
            statusCode: 500,
          ),
        );

        // Act
        final result = mapper.map(exception);

        // Assert
        expect(result, isA<ServerException>());
        expect((result as ServerException).statusCode, 500);
      },
    );

    test(
      'conserva una RateLimitException existente envuelta en un DioException',
      () {
        // Arrange
        final errorOriginal = RateLimitException(
          retryAfter: Duration(seconds: 8),
        );
        final exception = DioException(
          requestOptions: RequestOptions(path: '/users'),
          type: DioExceptionType.unknown,
          error: errorOriginal,
        );

        // Act
        final result = mapper.map(exception);

        // Assert — verifica que sea la misma instancia, no solo igual en valor.
        expect(result, same(errorOriginal));
      },
    );

    test(
      'convierte errores desconocidos sin excepción de dominio en ServerException',
      () {
        // Arrange
        final exception = DioException(
          requestOptions: RequestOptions(path: '/users'),
          type: DioExceptionType.unknown,
          error: Exception('error inesperado'),
        );

        // Act
        final result = mapper.map(exception);

        // Assert
        expect(result, isA<ServerException>());
      },
    );
  });

  // ─────────────────────────────────────────────
  // PaginatedResponse
  // ─────────────────────────────────────────────
  group('PaginatedResponse', () {
    test(
      'almacena los metadatos de paginación y los elementos correctamente',
      () {
        // Arrange & Act
        const response = PaginatedResponse<String>(
          items: ['a', 'b'],
          hasNextPage: true,
          currentPage: 2,
          totalPages: 5,
        );

        // Assert
        expect(response.items, ['a', 'b']);
        expect(response.hasNextPage, isTrue);
        expect(response.currentPage, 2);
        expect(response.totalPages, 5);
      },
    );

    test('permite que currentPage y totalPages sean nulos', () {
      // Arrange & Act
      const response = PaginatedResponse<String>(
        items: ['a'],
        hasNextPage: true,
      );

      // Assert — verifica que los campos opcionales no requieran un valor
      // cuando el backend no los incluye en su respuesta.
      expect(response.currentPage, isNull);
      expect(response.totalPages, isNull);
    });

    test('maneja correctamente una lista de elementos vacía', () {
      // Arrange & Act
      const response = PaginatedResponse<String>(items: [], hasNextPage: false);

      // Assert
      expect(response.items, isEmpty);
      expect(response.hasNextPage, isFalse);
    });
  });

  // ─────────────────────────────────────────────
  // RemoteDataKit (Fachada)
  // ─────────────────────────────────────────────
  group('RemoteDataKit', () {
    test('create inicializa el cliente con los valores por defecto', () {
      final kit = RemoteDataKit.create(baseUrl: 'https://example.com');
      final dio = kit.internalDio;

      expect(dio.options.baseUrl, 'https://example.com');
      expect(
        dio.options.connectTimeout,
        const Duration(milliseconds: NetworkConstants.defaultConnectTimeout),
      );
      expect(
        dio.options.receiveTimeout,
        const Duration(milliseconds: NetworkConstants.defaultReceiveTimeout),
      );
    });

    test('create aplica headers personalizados', () {
      final kit = RemoteDataKit.create(
        baseUrl: 'https://example.com',
        headers: {'Authorization': 'Bearer token'},
      );
      
      expect(kit.internalDio.options.headers['Authorization'], 'Bearer token');
    });
  });
}
