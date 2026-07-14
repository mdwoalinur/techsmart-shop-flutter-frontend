enum ApiExceptionType {
  network,
  timeout,
  unauthorized,
  server,
  invalidResponse,
  request,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
    this.responseBody,
  });

  final ApiExceptionType type;
  final String message;
  final int? statusCode;
  final Object? cause;
  final Object? responseBody;

  @override
  String toString() => 'ApiException($type, $statusCode): $message';
}

String userSafeApiMessage(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    if (error.statusCode == 403) {
      return 'You do not have permission to perform this action.';
    }
    if (error.type == ApiExceptionType.network) {
      return 'Unable to connect to the server. Please try again.';
    }
    return error.message;
  }
  return 'The request could not be completed. Please try again.';
}
