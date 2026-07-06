abstract class RemoteException implements Exception {
  final String? message;
  RemoteException({this.message});
}

class NetworkException extends RemoteException {}

class ServerException extends RemoteException {
  final int? statusCode;
  ServerException({super.message, this.statusCode});
}

class NotFoundException extends RemoteException {}

class RateLimitException extends RemoteException {
  final Duration retryAfter;
  RateLimitException({required this.retryAfter});
}
