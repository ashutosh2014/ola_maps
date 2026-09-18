class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class UnprocessableException extends ApiException {
  UnprocessableException(super.message);
}
