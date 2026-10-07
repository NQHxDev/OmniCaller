import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/permissions/call_permission_service.dart';
import '../../data/models/call_event_model.dart';
import '../../data/models/call_model.dart';
import '../../data/services/call_api_service.dart';
import '../../data/services/livekit_service.dart';

enum CallStateStatus {
  idle,
  ringing,      // Receiving incoming call
  outgoing,     // Calling someone else, awaiting answer
  connecting,   // Establishing WebRTC connection with LiveKit
  connected,    // Active call in progress
  ended,        // Call has ended
  error,        // Encountered an error
}

class CallController extends ChangeNotifier {
  final ICallApiService _apiService;
  final ILiveKitService _livekitService;

  CallStateStatus _state = CallStateStatus.idle;
  CallModel? _currentCall;
  String? _token;
  String? _currentUserId;

  // Metadata for current call
  String? _otherPartyName;
  String? _otherPartyAvatar;
  String? _otherPartyUserId;
  CallType _callType = CallType.voice;
  CallMode _callMode = CallMode.direct;
  String? _errorMessage;

  // Media state
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerphoneOn = true;
  bool _isFrontCamera = true;
  bool _isRemoteSpeaking = false;

  // Duration & Timer
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;
  EventsListener<RoomEvent>? _roomListener;

  CallController({
    ICallApiService? apiService,
    ILiveKitService? livekitService,
    String? token,
    String? currentUserId,
  })  : _apiService = apiService ?? CallApiService(),
        _livekitService = livekitService ?? LiveKitService(),
        _token = token,
        _currentUserId = currentUserId;

  // Getters
  CallStateStatus get state => _state;
  CallModel? get currentCall => _currentCall;
  String? get currentCallId => _currentCall?.id;
  String? get currentUserId => _currentUserId;
  String? get token => _token;
  String? get otherPartyName => _otherPartyName;
  String? get otherPartyAvatar => _otherPartyAvatar;
  String? get otherPartyUserId => _otherPartyUserId;
  CallType get callType => _callType;
  CallMode get callMode => _callMode;
  bool get isVideoCall => _callType == CallType.video;
  bool get isVoiceCall => _callType == CallType.voice;
  bool get isGroupCall => _callMode == CallMode.group;
  String? get errorMessage => _errorMessage;

  bool get isMicMuted => _isMicMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isSpeakerphoneOn => _isSpeakerphoneOn;
  bool get isFrontCamera => _isFrontCamera;
  bool get isRemoteSpeaking => _isRemoteSpeaking;

  Duration get callDuration => _callDuration;
  String get formattedDuration {
    final minutes = _callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (_callDuration.inHours > 0) {
      final hours = _callDuration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Room? get room => _livekitService.room;
  ILiveKitService get livekitService => _livekitService;

  void updateAuth({required String token, required String currentUserId}) {
    _token = token;
    _currentUserId = currentUserId;
  }

  /// Initiate an outgoing call
  Future<bool> startOutgoingCall({
    required CallType callType,
    required CallMode mode,
    required List<String> participantIds,
    String? conversationId,
    String? calleeName,
    String? calleeAvatar,
    String? calleeUserId,
  }) async {
    if (_token == null || _token!.isEmpty) {
      _errorMessage = 'Authentication token is missing';
      _setState(CallStateStatus.error);
      return false;
    }

    // Check & request permissions
    if (callType == CallType.video) {
      final granted = await CallPermissionService.requestVideoCallPermissions();
      if (!granted) {
        _errorMessage = 'Camera and Microphone permissions are required';
        _setState(CallStateStatus.error);
        return false;
      }
    } else {
      final granted = await CallPermissionService.requestAudioCallPermissions();
      if (!granted) {
        _errorMessage = 'Microphone permission is required';
        _setState(CallStateStatus.error);
        return false;
      }
    }

    _callType = callType;
    _callMode = mode;
    _otherPartyName = calleeName ?? 'Recipient';
    _otherPartyAvatar = calleeAvatar;
    _otherPartyUserId = calleeUserId ?? (participantIds.isNotEmpty ? participantIds.first : null);
    _isMicMuted = false;
    _isCameraOff = (callType == CallType.voice);
    _isSpeakerphoneOn = (callType == CallType.video);
    _isFrontCamera = true;
    _isRemoteSpeaking = false;
    _callDuration = Duration.zero;

    _setState(CallStateStatus.outgoing);

    try {
      final request = InitiateCallRequest(
        callType: callType,
        mode: mode,
        conversationId: conversationId,
        participantIds: participantIds,
      );

      final response = await _apiService.initiateCall(
        token: _token!,
        request: request,
      );

      _currentCall = response.call;

      // Connect to LiveKit room immediately as initiator
      await _connectToLiveKit(response.token);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to initiate call: $e';
      _setState(CallStateStatus.error);
      return false;
    }
  }

  /// Handle an incoming call event from WebSocket
  void handleIncomingCall(WsIncomingCallEvent event) {
    if (_state != CallStateStatus.idle && _state != CallStateStatus.ended && _state != CallStateStatus.error) {
      // Busy in another call
      return;
    }

    _callType = event.callType;
    _callMode = event.mode;
    _otherPartyName = event.initiatorName;
    _otherPartyUserId = event.initiatedBy;
    _currentCall = CallModel(
      id: event.callId,
      roomName: event.roomName,
      callType: event.callType,
      mode: event.mode,
      conversationId: event.conversationId,
      initiatedBy: event.initiatedBy,
      status: CallStatus.ringing,
      startedAt: DateTime.now(),
    );

    _isMicMuted = false;
    _isCameraOff = (event.callType == CallType.voice);
    _isSpeakerphoneOn = (event.callType == CallType.video);
    _isRemoteSpeaking = false;
    _callDuration = Duration.zero;

    _setState(CallStateStatus.ringing);
  }

  /// Accept incoming call
  Future<bool> acceptCall() async {
    if (_state != CallStateStatus.ringing || _currentCall == null || _token == null) {
      return false;
    }

    // Check permissions
    if (_callType == CallType.video) {
      final granted = await CallPermissionService.requestVideoCallPermissions();
      if (!granted) {
        _errorMessage = 'Camera and Microphone permissions are required';
        _setState(CallStateStatus.error);
        return false;
      }
    } else {
      final granted = await CallPermissionService.requestAudioCallPermissions();
      if (!granted) {
        _errorMessage = 'Microphone permission is required';
        _setState(CallStateStatus.error);
        return false;
      }
    }

    _setState(CallStateStatus.connecting);

    try {
      final joinResponse = await _apiService.joinCall(
        token: _token!,
        callId: _currentCall!.id,
      );

      _currentCall = joinResponse.call;
      await _connectToLiveKit(joinResponse.token);
      _setState(CallStateStatus.connected);
      _startDurationTimer();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to join call: $e';
      _setState(CallStateStatus.error);
      return false;
    }
  }

  /// Reject incoming call
  Future<void> rejectCall() async {
    if (_currentCall != null && _token != null) {
      try {
        await _apiService.rejectCall(token: _token!, callId: _currentCall!.id);
      } catch (_) {}
    }
    await _cleanupCall();
    _setState(CallStateStatus.ended);
  }

  /// Cancel outgoing call before answer
  Future<void> cancelCall() async {
    if (_currentCall != null && _token != null) {
      try {
        await _apiService.cancelCall(token: _token!, callId: _currentCall!.id);
      } catch (_) {}
    }
    await _cleanupCall();
    _setState(CallStateStatus.ended);
  }

  /// End active call
  Future<void> endCall() async {
    if (_currentCall != null && _token != null) {
      try {
        await _apiService.endCall(token: _token!, callId: _currentCall!.id);
      } catch (_) {}
    }
    await _cleanupCall();
    _setState(CallStateStatus.ended);
  }

  /// Handle WebSocket status updates
  void handleCallStatusUpdate(WsCallStatusUpdateEvent event) {
    if (_currentCall == null || _currentCall!.id != event.callId) return;

    if (event.status == CallStatus.active && _state == CallStateStatus.outgoing) {
      _setState(CallStateStatus.connected);
      _startDurationTimer();
    } else if (event.status == CallStatus.rejected ||
        event.status == CallStatus.missed ||
        event.status == CallStatus.cancelled ||
        event.status == CallStatus.completed) {
      _cleanupCall();
      _setState(CallStateStatus.ended);
    }
  }

  /// Handle Participant joined event
  void handleParticipantJoined(WsParticipantJoinedEvent event) {
    if (_currentCall == null || _currentCall!.id != event.callId) return;
    if (_state == CallStateStatus.outgoing || _state == CallStateStatus.connecting) {
      _setState(CallStateStatus.connected);
      _startDurationTimer();
    }
    notifyListeners();
  }

  /// Handle Participant left event
  void handleParticipantLeft(WsParticipantLeftEvent event) {
    if (_currentCall == null || _currentCall!.id != event.callId) return;
    notifyListeners();
  }

  /// Handle Call ended event
  void handleCallEnded(WsCallEndedEvent event) {
    if (_currentCall == null || _currentCall!.id != event.callId) return;
    _cleanupCall();
    _setState(CallStateStatus.ended);
  }

  /// Connect to LiveKit server with token
  Future<void> _connectToLiveKit(String livekitToken) async {
    final livekitUrl = ApiConfig.livekitUrl;
    await _livekitService.connect(
      url: livekitUrl,
      token: livekitToken,
      isVideoCall: isVideoCall,
    );

    _setupLiveKitListeners();

    if (_state == CallStateStatus.outgoing) {
      // Keep outgoing until participant joins or status becomes active
    } else {
      _setState(CallStateStatus.connected);
      _startDurationTimer();
    }
  }

  void _setupLiveKitListeners() {
    _roomListener?.dispose();
    _roomListener = _livekitService.listener;

    _roomListener
      ?..on<ParticipantConnectedEvent>((_) {
        if (_state == CallStateStatus.outgoing) {
          _setState(CallStateStatus.connected);
          _startDurationTimer();
        }
        notifyListeners();
      })
      ..on<ParticipantDisconnectedEvent>((_) {
        notifyListeners();
      })
      ..on<TrackSubscribedEvent>((_) {
        notifyListeners();
      })
      ..on<TrackUnsubscribedEvent>((_) {
        notifyListeners();
      })
      ..on<TrackMutedEvent>((_) {
        notifyListeners();
      })
      ..on<TrackUnmutedEvent>((_) {
        notifyListeners();
      })
      ..on<LocalTrackPublishedEvent>((_) {
        notifyListeners();
      })
      ..on<LocalTrackUnpublishedEvent>((_) {
        notifyListeners();
      })
      ..on<ActiveSpeakersChangedEvent>((event) {
        final remoteSpeaking = event.speakers.any((p) => p is RemoteParticipant) ||
            (_livekitService.room?.remoteParticipants.values.any((p) => p.isSpeaking) ?? false);
        if (_isRemoteSpeaking != remoteSpeaking) {
          _isRemoteSpeaking = remoteSpeaking;
          notifyListeners();
        }
      })
      ..on<RoomDisconnectedEvent>((_) {
        if (_state == CallStateStatus.connected || _state == CallStateStatus.connecting) {
          _cleanupCall();
          _setState(CallStateStatus.ended);
        }
      });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  Future<void> toggleMicrophone() async {
    _isMicMuted = !_isMicMuted;
    await _livekitService.setMicrophoneEnabled(!_isMicMuted);
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    await _livekitService.setCameraEnabled(!_isCameraOff);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    if (_isCameraOff) return;
    _isFrontCamera = !_isFrontCamera;
    await _livekitService.switchCamera();
    notifyListeners();
  }

  Future<void> toggleSpeakerphone() async {
    _isSpeakerphoneOn = !_isSpeakerphoneOn;
    await _livekitService.setSpeakerphoneEnabled(_isSpeakerphoneOn);
    notifyListeners();
  }

  @visibleForTesting
  void setRemoteSpeakingForTesting(bool speaking) {
    _isRemoteSpeaking = speaking;
    notifyListeners();
  }

  Future<void> _cleanupCall() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _roomListener?.dispose();
    _roomListener = null;
    _isRemoteSpeaking = false;
    await _livekitService.disconnect();
  }

  void reset() {
    _cleanupCall();
    _state = CallStateStatus.idle;
    _currentCall = null;
    _errorMessage = null;
    _otherPartyName = null;
    _otherPartyAvatar = null;
    _otherPartyUserId = null;
    _isRemoteSpeaking = false;
    _callDuration = Duration.zero;
    notifyListeners();
  }

  void _setState(CallStateStatus newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanupCall();
    super.dispose();
  }
}
