
class ApiConfig {
  /// Default LAN IP & Port for connecting from real physical devices
  static const String defaultHost = '192.168.1.162';
  static const String emulatorHost = '10.0.2.2';
  static const int defaultPort = 3000;
  static const int defaultLiveKitPort = 7880;

  /// Build-time environment variables:
  /// --dart-define=API_BASE_URL=http://192.168.1.162:3000
  /// or --dart-define=API_HOST=192.168.1.162 --dart-define=API_PORT=3000
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _envLiveKitUrl = String.fromEnvironment('LIVEKIT_URL');
  static const String _envHost = String.fromEnvironment('API_HOST');
  static const String _envPort = String.fromEnvironment('API_PORT');

  /// Dynamic runtime override support
  static String? _customBaseUrl;
  static String? _customLiveKitUrl;

  static void setBaseUrl(String url) {
    _customBaseUrl = url;
  }

  static void resetBaseUrl() {
    _customBaseUrl = null;
  }

  static void setLiveKitUrl(String url) {
    _customLiveKitUrl = url;
  }

  static void resetLiveKitUrl() {
    _customLiveKitUrl = null;
  }

  /// Get effective host (detects if running on Android Emulator)
  static String get resolvedHost {
    if (_envHost.isNotEmpty) {
      return _envHost;
    }
    return defaultHost;
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    final host = resolvedHost;
    final port = _envPort.isNotEmpty ? _envPort : '$defaultPort';

    return 'http://$host:$port';
  }

  static String get livekitUrl {
    if (_customLiveKitUrl != null && _customLiveKitUrl!.isNotEmpty) {
      return _customLiveKitUrl!;
    }

    if (_envLiveKitUrl.isNotEmpty) {
      return _envLiveKitUrl;
    }

    final host = resolvedHost;
    final isHttps = baseUrl.startsWith('https://');
    final scheme = isHttps ? 'wss' : 'ws';
    return '$scheme://$host:$defaultLiveKitPort';
  }

  static String wsUrl(String token) {
    final httpBase = baseUrl;
    final wsBase = httpBase.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    return '$wsBase/ws?token=$token';
  }

  static const Duration timeout = Duration(seconds: 15);

  // Auth endpoints
  static const String registerEndpoint = '/api/auth/register';
  static const String loginEndpoint = '/api/auth/login';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String refreshTokenEndpoint = '/api/auth/refresh';
  
  // User & Search endpoints
  static const String searchUsersEndpoint = '/api/users/search';
  static String userProfileEndpoint(String username) => '/api/users/${username.trim().toLowerCase()}';

  // Friend endpoints
  static const String friendsEndpoint = '/api/friends';
  static const String friendRequestsEndpoint = '/api/friends/requests';
  static const String friendRequestsReceivedEndpoint = '/api/friends/requests/received';
  static const String friendRequestsSentEndpoint = '/api/friends/requests/sent';
  static String acceptFriendRequestEndpoint(String requestId) => '/api/friends/requests/$requestId/accept';
  static String rejectFriendRequestEndpoint(String requestId) => '/api/friends/requests/$requestId/reject';
  static String cancelFriendRequestEndpoint(String requestId) => '/api/friends/requests/$requestId/cancel';
  static String unfriendEndpoint(String friendId) => '/api/friends/$friendId';
  static String friendshipStatusEndpoint(String userId) => '/api/friends/status/$userId';

  // Chat & Message endpoints
  static const String conversationsEndpoint = '/api/conversations';
  static const String directConversationEndpoint = '/api/conversations/direct';
  static String conversationMessagesEndpoint(String conversationId) => '/api/conversations/$conversationId/messages';
  static const String sendMessageEndpoint = '/api/messages';

  // Group endpoints
  static const String groupsEndpoint = '/api/groups';
  static String groupDetailEndpoint(String groupId) => '/api/groups/$groupId';

  // Call endpoints
  static const String callsInitiateEndpoint = '/api/calls/initiate';
  static const String callHistoryEndpoint = '/api/calls/history';
  static const String activeCallsEndpoint = '/api/calls/active';
  static String callJoinEndpoint(String callId) => '/api/calls/$callId/join';
  static String callEndEndpoint(String callId) => '/api/calls/$callId/end';
  static String callRejectEndpoint(String callId) => '/api/calls/$callId/reject';
  static String callCancelEndpoint(String callId) => '/api/calls/$callId/cancel';
  static String callDetailEndpoint(String callId) => '/api/calls/$callId';
  static const String presenceEndpoint = '/api/presence';
  static String userPresenceEndpoint(String userId) => '/api/presence/$userId';

  static const String healthEndpoint = '/health';
}
