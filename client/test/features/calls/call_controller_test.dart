import 'package:client/features/calls/data/models/call_event_model.dart';
import 'package:client/features/calls/data/models/call_model.dart';
import 'package:client/features/calls/data/services/call_api_service.dart';
import 'package:client/features/calls/data/services/livekit_service.dart';
import 'package:client/features/calls/presentation/controllers/call_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';

class MockCallApiService implements ICallApiService {
  InitiateCallResponse? mockInitiateResponse;
  JoinCallResponse? mockJoinResponse;
  CallModel? mockEndResponse;
  bool initiateCalled = false;
  bool joinCalled = false;
  bool endCalled = false;
  bool rejectCalled = false;
  bool cancelCalled = false;

  @override
  Future<InitiateCallResponse> initiateCall({
    required String token,
    required InitiateCallRequest request,
  }) async {
    initiateCalled = true;
    return mockInitiateResponse ??
        InitiateCallResponse(
          call: CallModel(
            id: 'call-1',
            roomName: 'room-1',
            callType: request.callType,
            mode: request.mode,
            initiatedBy: 'user-initiator',
            status: CallStatus.ringing,
            startedAt: DateTime.now(),
          ),
          token: 'livekit-token',
        );
  }

  @override
  Future<JoinCallResponse> joinCall({
    required String token,
    required String callId,
  }) async {
    joinCalled = true;
    return mockJoinResponse ??
        JoinCallResponse(
          call: CallModel(
            id: callId,
            roomName: 'room-1',
            callType: CallType.voice,
            mode: CallMode.direct,
            initiatedBy: 'user-initiator',
            status: CallStatus.active,
            startedAt: DateTime.now(),
          ),
          token: 'livekit-token',
        );
  }

  @override
  Future<CallModel> endCall({required String token, required String callId}) async {
    endCalled = true;
    return mockEndResponse ??
        CallModel(
          id: callId,
          roomName: 'room-1',
          callType: CallType.voice,
          mode: CallMode.direct,
          initiatedBy: 'user-initiator',
          status: CallStatus.completed,
          startedAt: DateTime.now(),
          endedAt: DateTime.now(),
          duration: 10,
        );
  }

  @override
  Future<CallModel> rejectCall({required String token, required String callId}) async {
    rejectCalled = true;
    return CallModel(
      id: callId,
      roomName: 'room-1',
      callType: CallType.voice,
      mode: CallMode.direct,
      initiatedBy: 'user-initiator',
      status: CallStatus.rejected,
      startedAt: DateTime.now(),
    );
  }

  @override
  Future<CallModel> cancelCall({required String token, required String callId}) async {
    cancelCalled = true;
    return CallModel(
      id: callId,
      roomName: 'room-1',
      callType: CallType.voice,
      mode: CallMode.direct,
      initiatedBy: 'user-initiator',
      status: CallStatus.missed,
      startedAt: DateTime.now(),
    );
  }

  @override
  Future<ActiveCallsResponse> getActiveCalls({required String token}) async {
    return const ActiveCallsResponse(calls: []);
  }

  @override
  Future<CallModel> getCall({required String token, required String callId}) async {
    return CallModel(
      id: callId,
      roomName: 'room-1',
      callType: CallType.voice,
      mode: CallMode.direct,
      initiatedBy: 'u',
      status: CallStatus.active,
      startedAt: DateTime.now(),
    );
  }

  @override
  Future<CallHistoryResponse> getCallHistory({
    required String token,
    int limit = 20,
    int offset = 0,
  }) async {
    return const CallHistoryResponse(calls: [], total: 0);
  }

  @override
  Future<UserPresenceModel> getPresence({required String token, required String userId}) async {
    return UserPresenceModel(userId: userId, status: 'online', lastSeenAt: DateTime.now());
  }

  @override
  Future<UserPresenceModel> updatePresence({required String token, required String status}) async {
    return UserPresenceModel(userId: 'u', status: status, lastSeenAt: DateTime.now());
  }
}

class MockLiveKitService implements ILiveKitService {
  bool connectCalled = false;
  bool disconnectCalled = false;
  bool micEnabled = true;
  bool camEnabled = false;
  bool speakerEnabled = true;

  @override
  Room? get room => null;

  @override
  bool get isConnected => connectCalled && !disconnectCalled;

  @override
  EventsListener<RoomEvent>? get listener => null;

  @override
  Future<void> connect({
    required String url,
    required String token,
    bool isVideoCall = false,
  }) async {
    connectCalled = true;
    disconnectCalled = false;
    camEnabled = isVideoCall;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
    connectCalled = false;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    camEnabled = enabled;
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    micEnabled = enabled;
  }

  @override
  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    speakerEnabled = enabled;
  }

  @override
  Future<void> switchCamera() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermissionStatus') {
          return 1; // PermissionStatus.granted
        }
        if (methodCall.method == 'requestPermissions') {
          final args = methodCall.arguments as List<dynamic>? ?? [];
          final result = <int, int>{};
          for (final perm in args) {
            if (perm is int) {
              result[perm] = 1; // PermissionStatus.granted
            }
          }
          return result;
        }
        return 1;
      },
    );
  });

  group('CallController Tests', () {
    late MockCallApiService mockApi;
    late MockLiveKitService mockLivekit;
    late CallController controller;

    setUp(() {
      mockApi = MockCallApiService();
      mockLivekit = MockLiveKitService();
      controller = CallController(
        apiService: mockApi,
        livekitService: mockLivekit,
        token: 'auth-token',
        currentUserId: 'my-user-id',
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial state is idle', () {
      expect(controller.state, CallStateStatus.idle);
      expect(controller.currentCall, isNull);
      expect(controller.formattedDuration, '00:00');
      expect(controller.isMicMuted, isFalse);
    });

    test('Incoming call updates state to ringing', () {
      controller.handleIncomingCall(
        const WsIncomingCallEvent(
          callId: 'call-99',
          roomName: 'room-99',
          callType: CallType.video,
          mode: CallMode.direct,
          initiatedBy: 'user-caller',
          initiatorName: 'Alice',
        ),
      );

      expect(controller.state, CallStateStatus.ringing);
      expect(controller.currentCallId, 'call-99');
      expect(controller.otherPartyName, 'Alice');
      expect(controller.isVideoCall, isTrue);
    });

    test('Rejecting incoming call calls api and sets state to ended', () async {
      controller.handleIncomingCall(
        const WsIncomingCallEvent(
          callId: 'call-99',
          roomName: 'room-99',
          callType: CallType.voice,
          mode: CallMode.direct,
          initiatedBy: 'user-caller',
          initiatorName: 'Alice',
        ),
      );

      await controller.rejectCall();
      expect(mockApi.rejectCalled, isTrue);
      expect(controller.state, CallStateStatus.ended);
    });

    test('Accepting incoming call calls joinCall and sets state to connected', () async {
      controller.handleIncomingCall(
        const WsIncomingCallEvent(
          callId: 'call-99',
          roomName: 'room-99',
          callType: CallType.voice,
          mode: CallMode.direct,
          initiatedBy: 'user-caller',
          initiatorName: 'Alice',
        ),
      );

      final result = await controller.acceptCall();
      expect(result, isTrue);
      expect(mockApi.joinCalled, isTrue);
      expect(mockLivekit.connectCalled, isTrue);
      expect(controller.state, CallStateStatus.connected);
    });

    test('Toggling media controls updates flags and calls LiveKit service', () async {
      expect(controller.isMicMuted, isFalse);
      await controller.toggleMicrophone();
      expect(controller.isMicMuted, isTrue);
      expect(mockLivekit.micEnabled, isFalse);

      await controller.toggleCamera();
      expect(controller.isCameraOff, isTrue);
      expect(mockLivekit.camEnabled, isFalse);

      final initialSpeaker = controller.isSpeakerphoneOn;
      await controller.toggleSpeakerphone();
      expect(controller.isSpeakerphoneOn, !initialSpeaker);
    });

    test('WebSocket status updates update controller state correctly', () {
      controller.handleIncomingCall(
        const WsIncomingCallEvent(
          callId: 'call-99',
          roomName: 'room-99',
          callType: CallType.voice,
          mode: CallMode.direct,
          initiatedBy: 'user-caller',
          initiatorName: 'Alice',
        ),
      );

      controller.handleCallStatusUpdate(
        const WsCallStatusUpdateEvent(
          callId: 'call-99',
          status: CallStatus.completed,
        ),
      );

      expect(controller.state, CallStateStatus.ended);
    });

    test('Call ended event sets state to ended', () {
      controller.handleIncomingCall(
        const WsIncomingCallEvent(
          callId: 'call-99',
          roomName: 'room-99',
          callType: CallType.voice,
          mode: CallMode.direct,
          initiatedBy: 'user-caller',
          initiatorName: 'Alice',
        ),
      );

      controller.handleCallEnded(
        const WsCallEndedEvent(
          callId: 'call-99',
          endedBy: 'user-caller',
          duration: 45,
        ),
      );

      expect(controller.state, CallStateStatus.ended);
    });
  });
}
