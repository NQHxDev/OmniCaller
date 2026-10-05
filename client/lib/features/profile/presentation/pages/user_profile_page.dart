import 'package:flutter/material.dart';
import '../../../../core/auth/auth_scope.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../friends/data/models/friend_models.dart';
import '../../../friends/data/services/friend_api_service.dart';
import '../../../search/data/models/user_search_models.dart';
import '../../../search/data/services/user_search_api_service.dart';
import '../widgets/user_profile_detail_view.dart';

class UserProfilePage extends StatefulWidget {
  final String username;
  final String? initialDisplayName;
  final String? initialUserId;
  final bool openedFromChat;
  final IUserSearchApiService? userApiService;
  final IFriendApiService? friendApiService;

  const UserProfilePage({
    super.key,
    required this.username,
    this.initialDisplayName,
    this.initialUserId,
    this.openedFromChat = false,
    this.userApiService,
    this.friendApiService,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late final IUserSearchApiService _userApiService;
  late final IFriendApiService _friendApiService;

  UserPublicProfile? _profile;
  FriendshipStatus _friendshipStatus = FriendshipStatus.none;
  String? _requestId;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _userApiService = widget.userApiService ?? UserSearchApiService();
    _friendApiService = widget.friendApiService ?? FriendApiService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileAndStatus();
    });
  }

  bool _isSelf(String currentUserId, String currentUsername) {
    if (_profile != null && _profile!.userId.isNotEmpty && currentUserId.isNotEmpty) {
      return _profile!.userId == currentUserId;
    }
    return widget.username.toLowerCase() == currentUsername.toLowerCase();
  }

  Future<void> _fetchProfileAndStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = AuthScope.maybeOf(context);
      final token = auth?.accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('Chưa đăng nhập hoặc phiên làm việc đã hết hạn');
      }

      final profile = await _userApiService.getUserProfile(
        username: widget.username,
        token: token,
      );

      FriendshipStatus status = FriendshipStatus.none;
      String? reqId;

      final currentUserId = auth?.currentUser?.id ?? '';
      final currentUsername = auth?.currentUser?.username ?? '';

      if (profile.userId.isNotEmpty && !_isSelf(currentUserId, currentUsername)) {
        try {
          final statusData = await _friendApiService.getFriendshipStatus(
            userId: profile.userId,
            token: token,
          );
          status = statusData.status;
          reqId = statusData.requestId;
        } catch (_) {
          status = FriendshipStatus.none;
        }
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _friendshipStatus = status;
          _requestId = reqId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e
              .toString()
              .replaceAll('ApiException: ', '')
              .replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onAddFriend() async {
    if (_profile == null || _isActionLoading) return;
    final token = AuthScope.maybeOf(context)?.accessToken;
    if (token == null) return;

    setState(() => _isActionLoading = true);
    try {
      final item = await _friendApiService.sendFriendRequest(
        friendId: _profile!.userId,
        token: token,
      );
      if (mounted) {
        setState(() {
          _friendshipStatus = FriendshipStatus.pendingSent;
          _requestId = item.requestId;
          _isActionLoading = false;
        });
        AppToast.showSuccess(
          context,
          'Đã gửi lời mời kết bạn đến ${_profile!.displayName.isNotEmpty ? _profile!.displayName : _profile!.username}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        AppToast.showError(
          context,
          e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _onCancelRequest() async {
    if (_isActionLoading) return;
    final token = AuthScope.maybeOf(context)?.accessToken;
    if (token == null) return;

    setState(() => _isActionLoading = true);
    try {
      final reqId = _requestId ?? _profile?.userId ?? '';
      await _friendApiService.cancelFriendRequest(
        requestId: reqId,
        token: token,
      );
      if (mounted) {
        setState(() {
          _friendshipStatus = FriendshipStatus.none;
          _requestId = null;
          _isActionLoading = false;
        });
        AppToast.showInfo(
          context,
          'Đã hủy lời mời kết bạn',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        AppToast.showError(
          context,
          e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _onAcceptRequest() async {
    if (_isActionLoading) return;
    final token = AuthScope.maybeOf(context)?.accessToken;
    if (token == null) return;

    setState(() => _isActionLoading = true);
    try {
      final reqId = _requestId ?? _profile?.userId ?? '';
      await _friendApiService.acceptFriendRequest(
        requestId: reqId,
        token: token,
      );
      if (mounted) {
        setState(() {
          _friendshipStatus = FriendshipStatus.accepted;
          _isActionLoading = false;
        });
        AppToast.showSuccess(
          context,
          'Đã trở thành bạn bè',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        AppToast.showError(
          context,
          e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _onRejectRequest() async {
    if (_isActionLoading) return;
    final token = AuthScope.maybeOf(context)?.accessToken;
    if (token == null) return;

    setState(() => _isActionLoading = true);
    try {
      final reqId = _requestId ?? _profile?.userId ?? '';
      await _friendApiService.rejectFriendRequest(
        requestId: reqId,
        token: token,
      );
      if (mounted) {
        setState(() {
          _friendshipStatus = FriendshipStatus.none;
          _isActionLoading = false;
        });
        AppToast.showInfo(
          context,
          'Đã từ chối lời mời kết bạn',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        AppToast.showError(
          context,
          e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _onUnfriend() async {
    if (_profile == null || _isActionLoading) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hủy kết bạn'),
        content: Text('Bạn có chắc chắn muốn hủy kết bạn với ${_profile!.displayName.isNotEmpty ? _profile!.displayName : _profile!.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Hủy kết bạn'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final token = AuthScope.maybeOf(context)?.accessToken;
    if (token == null) return;

    setState(() => _isActionLoading = true);
    try {
      await _friendApiService.unfriend(
        friendId: _profile!.userId,
        token: token,
      );
      if (mounted) {
        setState(() {
          _friendshipStatus = FriendshipStatus.none;
          _isActionLoading = false;
        });
        AppToast.showInfo(
          context,
          'Đã hủy kết bạn',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        AppToast.showError(
          context,
          e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', ''),
        );
      }
    }
  }

  void _onOpenChat() {
    if (widget.openedFromChat) {
      Navigator.of(context).pop();
      return;
    }

    if (_profile == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          userId: _profile!.userId,
          username: _profile!.username,
          displayName: _profile!.displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthScope.maybeOf(context);
    final isSelf = _isSelf(
      auth?.currentUser?.id ?? '',
      auth?.currentUser?.username ?? '',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialDisplayName ?? '@${widget.username}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: _fetchProfileAndStatus,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _profile != null
                    ? UserProfileDetailView(
                        profile: _profile!,
                        friendshipStatus: _friendshipStatus,
                        isSelf: isSelf,
                        isActionLoading: _isActionLoading,
                        onSendMessage: _onOpenChat,
                        onAddFriend: _onAddFriend,
                        onCancelRequest: _onCancelRequest,
                        onAcceptRequest: _onAcceptRequest,
                        onRejectRequest: _onRejectRequest,
                        onUnfriend: _onUnfriend,
                      )
                    : const Center(
                        child: Text('Không có dữ liệu'),
                      ),
      ),
    );
  }
}
