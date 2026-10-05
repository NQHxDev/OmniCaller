class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng.',
    super.statusCode,
  });
}

class TimeoutException extends ApiException {
  const TimeoutException({
    super.message = 'Kết nối quá thời gian chờ. Vui lòng thử lại sau.',
    super.statusCode,
  });
}
