import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/user_search_models.dart';
import '../../data/services/user_search_api_service.dart';

class UserSearchController extends ChangeNotifier {
  final IUserSearchApiService _searchService;
  
  String _query = '';
  bool _isLoading = false;
  String? _errorMessage;
  List<UserSearchResult> _results = [];
  SearchPagination? _pagination;
  Timer? _debounceTimer;

  UserSearchController({
    IUserSearchApiService? searchService,
  }) : _searchService = searchService ?? UserSearchApiService();

  String get query => _query;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserSearchResult> get results => List.unmodifiable(_results);
  SearchPagination? get pagination => _pagination;
  bool get hasQuery => _query.trim().isNotEmpty;
  bool get hasResults => _results.isNotEmpty;

  void onQueryChanged(String newQuery, {required String? token}) {
    _query = newQuery;
    _debounceTimer?.cancel();

    if (newQuery.trim().isEmpty) {
      _isLoading = false;
      _errorMessage = null;
      _results = [];
      _pagination = null;
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      search(query: newQuery.trim(), token: token);
    });
  }

  Future<void> search({
    required String query,
    required String? token,
    int page = 1,
    int pageSize = 10,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      clear();
      return;
    }

    if (token == null || token.isEmpty) {
      _errorMessage = 'Chưa đăng nhập hoặc phiên làm việc đã hết hạn';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _searchService.searchUsers(
        query: trimmedQuery,
        token: token,
        page: page,
        pageSize: pageSize,
      );

      _results = response.users;
      _pagination = response.pagination;
      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
      _results = [];
      _isLoading = false;
    }

    notifyListeners();
  }

  void clear() {
    _debounceTimer?.cancel();
    _query = '';
    _isLoading = false;
    _errorMessage = null;
    _results = [];
    _pagination = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
