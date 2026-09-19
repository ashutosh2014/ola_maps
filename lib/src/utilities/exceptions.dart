/// Base error thrown by Ola Maps HTTP helpers.
class ApiException implements Exception {
  /// Server or client message.
  final String message;

  /// Creates an API failure with [message].
  ApiException(this.message);

  @override
  String toString() => message;
}

/// HTTP 400 from an Ola Maps endpoint.
class BadRequestException extends ApiException {
  /// Creates a bad-request failure.
  BadRequestException(super.message);
}

/// HTTP 500 from an Ola Maps endpoint.
class ServerException extends ApiException {
  /// Creates a server failure.
  ServerException(super.message);
}

/// HTTP 404 from an Ola Maps endpoint.
class NotFoundException extends ApiException {
  /// Creates a not-found failure.
  NotFoundException(super.message);
}

/// HTTP 401 from an Ola Maps endpoint.
class UnauthorizedException extends ApiException {
  /// Creates an authentication failure.
  UnauthorizedException(super.message);
}

/// HTTP 422 from an Ola Maps endpoint.
class UnprocessableException extends ApiException {
  /// Creates an unprocessable-entity failure.
  UnprocessableException(super.message);
}
