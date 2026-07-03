import 'package:remote_data_kit/remote_data_kit.dart';

abstract class Failure {
  const Failure();
}

class NetworkFailure extends Failure {
  const NetworkFailure();
}

class ServerFailure extends Failure {
  final String? message;
  final int? statusCode;

  const ServerFailure({this.message, this.statusCode});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

class RateLimitFailure extends Failure {
  final Duration retryAfter;

  const RateLimitFailure({required this.retryAfter});
}

class UnknownFailure extends Failure {
  const UnknownFailure();
}

extension ExceptionToFailure on Object {
  Failure toFailure() {
    final error = this;
    if (error is NetworkException) return const NetworkFailure();
    if (error is NotFoundException) return const NotFoundFailure();
    if (error is RateLimitException) return RateLimitFailure(retryAfter: error.retryAfter);
    if (error is ServerException) {
      return ServerFailure(statusCode: error.statusCode, message: error.message);
    }
    return const UnknownFailure();
  }
}

extension FailureMessageX on Object {
  String toUserMessage() {
    final error = this;

    if (error is Failure) {
      switch (error) {
        case ServerFailure():
          return 'Server error${error.statusCode != null ? " (${error.statusCode})" : ""}. Please try again later.';
        case NetworkFailure():
          return 'No internet connection. Check your network and try again.';
        case NotFoundFailure():
          return 'No results found.';
        case RateLimitFailure():
          return 'Too many requests. Please wait ${error.retryAfter.inSeconds} seconds';
        case UnknownFailure():
          return 'An unexpected error occurred.';
      }
    }

    return 'An unexpected error occurred';
  }
}
