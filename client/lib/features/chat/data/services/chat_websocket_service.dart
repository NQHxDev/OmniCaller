import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../../../core/config/api_config.dart';
import '../models/ws_models.dart';

abstract class IChatWebSocketService {
  Stream<WsServerEvent> get events;
  bool get isConnected;

  Future<void> connect({required String token});
  void send(WsClientEvent event);
  void disconnect();
  void dispose();
}

class ChatWebSocketService implements IChatWebSocketService {
  static final ChatWebSocketService _instance = ChatWebSocketService._internal();

  factory ChatWebSocketService() => _instance;

  ChatWebSocketService._internal();

  ChatWebSocketService.custom();

  WebSocket? _socket;
  final StreamController<WsServerEvent> _eventsController = StreamController<WsServerEvent>.broadcast();
  StreamSubscription? _socketSubscription;
  bool _isDisposed = false;
  bool _isConnecting = false;
  String? _lastToken;
  Timer? _reconnectTimer;

  @override
  Stream<WsServerEvent> get events => _eventsController.stream;

  @override
  bool get isConnected => _socket != null && _socket!.readyState == WebSocket.open;

  @override
  Future<void> connect({required String token}) async {
    if (_isDisposed) return;
    if (isConnected && _lastToken == token) return;
    if (_isConnecting) return;

    if (_socket != null && _lastToken != token) {
      disconnect();
    }

    _lastToken = token;
    _isConnecting = true;

    try {
      final wsUrl = ApiConfig.wsUrl(token);
      _socket = await WebSocket.connect(wsUrl);
      _isConnecting = false;

      if (_isDisposed) {
        _socket?.close();
        _socket = null;
        return;
      }

      _socketSubscription = _socket!.listen(
        (data) {
          _handleIncomingData(data);
        },
        onError: (err) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _isConnecting = false;
      _handleDisconnect();
    }
  }

  void _handleIncomingData(dynamic data) {
    try {
      final text = data is String ? data : utf8.decode(data as List<int>);
      final json = jsonDecode(text) as Map<String, dynamic>;
      final event = WsServerEvent.fromJson(json);
      if (event != null && !_eventsController.isClosed) {
        _eventsController.add(event);
      }
    } catch (_) {
      // Ignore corrupted message frames
    }
  }

  void _handleDisconnect() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket = null;
    _isConnecting = false;

    if (!_isDisposed && _lastToken != null && _lastToken!.isNotEmpty) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (!_isDisposed && _lastToken != null) {
          connect(token: _lastToken!);
        }
      });
    }
  }

  @override
  void send(WsClientEvent event) {
    if (!isConnected) return;
    try {
      final jsonStr = jsonEncode(event.toJson());
      _socket?.add(jsonStr);
    } catch (_) {}
  }

  @override
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
    _isConnecting = false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    disconnect();
    _eventsController.close();
  }
}
