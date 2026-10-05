import 'package:flutter/foundation.dart';
import '../../data/models/friend_models.dart';
import '../../data/services/friend_api_service.dart';

class FriendsController extends ChangeNotifier {
  final IFriendApiService _friendService;

  List<FriendUser> _friends = [];
  String _filterQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  FriendsController({
    IFriendApiService? friendService,
  }) : _friendService = friendService ?? FriendApiService();

  List<FriendUser> get friends => List.unmodifiable(_friends);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get friendCount => _friends.length;

  List<FriendUser> get filteredFriends {
    if (_filterQuery.trim().isEmpty) {
      return List.unmodifiable(_friends);
    }
    final q = _filterQuery.trim().toLowerCase();
    return _friends.where((f) {
      return f.displayName.toLowerCase().contains(q) ||
          f.username.toLowerCase().contains(q);
    }).toList();
  }

  void filter(String query) {
    _filterQuery = query;
    notifyListeners();
  }

  Future<void> fetchFriends({required String? token}) async {
    if (token == null || token.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _friendService.getFriends(token: token);
      _friends = list;
      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<bool> unfriend({
    required String friendId,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) return false;

    try {
      await _friendService.unfriend(friendId: friendId, token: token);
      _friends.removeWhere((f) => f.userId == friendId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
