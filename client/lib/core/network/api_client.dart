import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_exception.dart';

typedef UnauthorizedCallback = void Function();

class ApiClient {
  final http.Client _client;
  final String _baseUrl;
  final UnauthorizedCallback? onUnauthorized;

  static UnauthorizedCallback? globalOnUnauthorized;

  ApiClient({
    http.Client? client,
    String? baseUrl,
    this.onUnauthorized,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  String get baseUrl => _baseUrl;

  Map<String, String> _buildHeaders({
    String? token,
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    Uri baseUri;
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      baseUri = Uri.parse(endpoint);
    } else {
      final cleanBase = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
      final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      baseUri = Uri.parse('$cleanBase$cleanEndpoint');
    }

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map((k, v) => MapEntry(k, v.toString()));
      final mergedParams = Map<String, String>.from(baseUri.queryParameters)..addAll(stringParams);
      return baseUri.replace(queryParameters: mergedParams);
    }
    return baseUri;
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    String? token,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    try {
      final response = await _client
          .get(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: headers),
          )
          .timeout(timeout ?? ApiConfig.timeout);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ (${e.message}).',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Lỗi kết nối mạng: ${e.message}',
      );
    } on TimeoutException {
      throw const TimeoutException();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Lỗi không xác định: $e');
    }
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    String? token,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: headers),
            body: encodedBody,
          )
          .timeout(timeout ?? ApiConfig.timeout);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ (${e.message}).',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Lỗi kết nối mạng: ${e.message}',
      );
    } on TimeoutException {
      throw const TimeoutException();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Lỗi không xác định: $e');
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    dynamic body,
    String? token,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _client
          .delete(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: headers),
            body: encodedBody,
          )
          .timeout(timeout ?? ApiConfig.timeout);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ (${e.message}).',
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Lỗi kết nối mạng: ${e.message}',
      );
    } on TimeoutException {
      throw const TimeoutException();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Lỗi không xác định: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      globalOnUnauthorized?.call();
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decoded = null;
    }

    final isSuccessStatusCode = response.statusCode >= 200 && response.statusCode < 300;

    if (decoded is Map<String, dynamic>) {
      final success = decoded['success'] == true;
      final error = decoded['error'];

      if (isSuccessStatusCode && (success || error == null)) {
        return decoded['data'] ?? decoded;
      }

      final errorMsg = error?.toString() ?? 'Yêu cầu không thành công (mã lỗi: ${response.statusCode})';
      throw ApiException(
        message: errorMsg,
        statusCode: response.statusCode,
        data: decoded['data'],
      );
    }

    if (isSuccessStatusCode) {
      return decoded;
    }

    throw ApiException(
      message: 'Lỗi từ máy chủ (mã lỗi: ${response.statusCode})',
      statusCode: response.statusCode,
    );
  }

  void close() {
    _client.close();
  }
}
