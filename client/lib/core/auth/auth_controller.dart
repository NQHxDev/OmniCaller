import 'package:flutter/foundation.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class UserProfile {
  final String id;
  final String username;
  final String displayName;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
  });
}

class AuthController extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unauthenticated;
  UserProfile? _currentUser;
  String? _token;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  UserProfile? get currentUser => _currentUser;
  String? get token => _token;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    // Hook ready for backend API integration
    _status = AuthStatus.authenticated;
    _currentUser = UserProfile(
      id: 'usr_1',
      username: username,
      displayName: username,
    );
    _token = 'auth_token_placeholder';
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String username,
    required String password,
  }) async {
    // Hook ready for backend API integration
    _status = AuthStatus.authenticated;
    _currentUser = UserProfile(
      id: 'usr_1',
      username: username,
      displayName: username,
    );
    _token = 'auth_token_placeholder';
    notifyListeners();
    return true;
  }

  void logout() {
    _status = AuthStatus.unauthenticated;
    _currentUser = null;
    _token = null;
    notifyListeners();
  }
}
