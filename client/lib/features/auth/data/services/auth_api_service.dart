import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

abstract class IAuthApiService {
  Future<AuthResponseDto> login({
    required String username,
    required String password,
  });

  Future<AuthResponseDto> register({
    required String displayName,
    required String username,
    required String password,
    required String confirmPassword,
  });

  Future<RefreshTokenResponseDto> refreshToken(String refreshToken);

  Future<void> logout(String token);
}

class AuthApiService implements IAuthApiService {
  final ApiClient _apiClient;

  AuthApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<AuthResponseDto> login({
    required String username,
    required String password,
  }) async {
    final requestDto = LoginRequestDto(
      username: username,
      password: password,
    );

    final responseData = await _apiClient.post(
      ApiConfig.loginEndpoint,
      body: requestDto.toJson(),
    );

    if (responseData is Map<String, dynamic>) {
      return AuthResponseDto.fromJson(responseData);
    }

    throw const FormatException('Định dạng dữ liệu trả về không hợp lệ');
  }

  @override
  Future<AuthResponseDto> register({
    required String displayName,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    final requestDto = RegisterRequestDto(
      displayName: displayName,
      username: username,
      password: password,
      confirmPassword: confirmPassword,
    );

    final responseData = await _apiClient.post(
      ApiConfig.registerEndpoint,
      body: requestDto.toJson(),
    );

    if (responseData is Map<String, dynamic>) {
      return AuthResponseDto.fromJson(responseData);
    }

    throw const FormatException('Định dạng dữ liệu trả về không hợp lệ');
  }

  @override
  Future<RefreshTokenResponseDto> refreshToken(String refreshToken) async {
    final requestDto = RefreshTokenRequestDto(refreshToken: refreshToken);
    final responseData = await _apiClient.post(
      ApiConfig.refreshTokenEndpoint,
      body: requestDto.toJson(),
    );

    if (responseData is Map<String, dynamic>) {
      return RefreshTokenResponseDto.fromJson(responseData);
    }

    throw const FormatException('Định dạng dữ liệu trả về không hợp lệ');
  }

  @override
  Future<void> logout(String token) async {
    await _apiClient.post(
      ApiConfig.logoutEndpoint,
      token: token,
    );
  }
}
