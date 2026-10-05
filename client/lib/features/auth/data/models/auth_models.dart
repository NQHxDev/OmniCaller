class LoginRequestDto {
  final String username;
  final String password;

  const LoginRequestDto({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'username': username.trim().toLowerCase(),
    'password': password,
  };
}

class RegisterRequestDto {
  final String displayName;
  final String username;
  final String password;
  final String confirmPassword;

  const RegisterRequestDto({
    required this.displayName,
    required this.username,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'display_name': displayName.trim(),
    'username': username.trim().toLowerCase(),
    'password': password,
    'confirm_password': confirmPassword,
  };
}

class AuthResponseDto {
  final String userId;
  final String username;
  final String displayName;
  final String accessToken;
  final String refreshToken;

  const AuthResponseDto({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'display_name': displayName,
    'access_token': accessToken,
    'refresh_token': refreshToken,
  };
}

class RefreshTokenRequestDto {
  final String refreshToken;

  const RefreshTokenRequestDto({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() => {
    'refresh_token': refreshToken,
  };
}

class RefreshTokenResponseDto {
  final String accessToken;
  final String refreshToken;

  const RefreshTokenResponseDto({
    required this.accessToken,
    required this.refreshToken,
  });

  factory RefreshTokenResponseDto.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponseDto(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
  };
}
