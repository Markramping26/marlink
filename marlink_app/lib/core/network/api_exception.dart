class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;

  String get friendlyErrorMessage {
    if (statusCode == 401) {
      if (message.isNotEmpty &&
          !message.toLowerCase().contains('unauthenticated') &&
          !message.toLowerCase().contains('token expired') &&
          !message.toLowerCase().contains('cannot reach server')) {
        return message;
      }
      return 'Session expired. Please log in again.';
    } else if (statusCode == 403) {
      return 'Access denied. You do not have permission for this action.';
    } else if (statusCode == 404) {
      return message.isNotEmpty ? message : 'Resource not found.';
    } else if (statusCode == 422 && errors != null && errors!.isNotEmpty) {
      final firstError = errors!.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      return message;
    } else if (statusCode == 429) {
      return message.isNotEmpty ? message : 'Too many requests. Please wait a moment.';
    } else if (statusCode != null && statusCode! >= 500) {
      return 'Server is temporarily unavailable. Please try again later.';
    }
    return message.isNotEmpty ? message : 'An unexpected error occurred. Please check your connection.';
  }
}
