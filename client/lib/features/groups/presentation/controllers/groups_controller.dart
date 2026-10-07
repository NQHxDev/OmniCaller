import 'package:flutter/foundation.dart';
import '../../data/models/group_models.dart';
import '../../data/services/group_api_service.dart';

class GroupsController extends ChangeNotifier {
  final IGroupApiService _groupService;

  bool _isLoading = false;
  bool _isCreating = false;
  String? _errorMessage;
  List<GroupProfileResponse> _groups = [];

  GroupsController({IGroupApiService? groupService})
      : _groupService = groupService ?? GroupApiService();

  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get errorMessage => _errorMessage;
  List<GroupProfileResponse> get groups => _groups;

  Future<GroupProfileResponse?> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
    String? avatarUrl,
    String? bannerUrl,
    required String token,
  }) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newGroup = await _groupService.createGroup(
        name: name,
        memberIds: memberIds,
        description: description,
        avatarUrl: avatarUrl,
        bannerUrl: bannerUrl,
        token: token,
      );
      _groups = [newGroup, ..._groups];
      _isCreating = false;
      notifyListeners();
      return newGroup;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isCreating = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchUserGroups({required String token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _groups = await _groupService.getUserGroups(token: token);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
