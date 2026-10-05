import 'package:flutter/foundation.dart';
import '../../data/models/friend_models.dart';
import '../../data/services/friend_api_service.dart';

class FriendRequestsController extends ChangeNotifier {
  final IFriendApiService _friendService;

  List<FriendRequestItem> _receivedRequests = [];
  List<FriendRequestItem> _sentRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  FriendRequestsController({
    IFriendApiService? friendService,
  }) : _friendService = friendService ?? FriendApiService();

  List<FriendRequestItem> get receivedRequests => List.unmodifiable(_receivedRequests);
  List<FriendRequestItem> get sentRequests => List.unmodifiable(_sentRequests);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get pendingCount => _receivedRequests.length;

  Future<void> fetchRequests({required String? token}) async {
    if (token == null || token.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _friendService.getReceivedFriendRequests(token: token),
        _friendService.getSentFriendRequests(token: token),
      ]);

      _receivedRequests = results[0];
      _sentRequests = results[1];
      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<bool> acceptRequest({
    required String requestId,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) return false;

    try {
      await _friendService.acceptFriendRequest(requestId: requestId, token: token);
      _receivedRequests.removeWhere((r) => r.requestId == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectRequest({
    required String requestId,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) return false;

    try {
      await _friendService.rejectFriendRequest(requestId: requestId, token: token);
      _receivedRequests.removeWhere((r) => r.requestId == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelRequest({
    required String requestId,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) return false;

    try {
      await _friendService.cancelFriendRequest(requestId: requestId, token: token);
      _sentRequests.removeWhere((r) => r.requestId == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendRequest({
    String? friendId,
    String? friendUsername,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) return false;

    try {
      final item = await _friendService.sendFriendRequest(
        friendId: friendId,
        friendUsername: friendUsername,
        token: token,
      );
      _sentRequests.add(item);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
