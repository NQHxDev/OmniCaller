import 'package:flutter_test/flutter_test.dart';
import 'package:client/features/calls/data/models/call_model.dart';
import 'package:client/features/calls/data/models/call_event_model.dart';
import 'package:client/features/chat/data/models/ws_models.dart';

void main() {
  group('CallModels Tests', () {
    test('CallType, CallMode, CallStatus parsing and toJson', () {
      expect(CallType.fromString('voice'), CallType.voice);
      expect(CallType.fromString('video'), CallType.video);
      expect(CallType.fromString(null), CallType.voice);
      expect(CallType.voice.toJson(), 'voice');
      expect(CallType.video.toJson(), 'video');

      expect(CallMode.fromString('direct'), CallMode.direct);
      expect(CallMode.fromString('group'), CallMode.group);
      expect(CallMode.fromString(null), CallMode.direct);
      expect(CallMode.direct.toJson(), 'direct');
      expect(CallMode.group.toJson(), 'group');

      expect(CallStatus.fromString('ringing'), CallStatus.ringing);
      expect(CallStatus.fromString('active'), CallStatus.active);
      expect(CallStatus.fromString('completed'), CallStatus.completed);
      expect(CallStatus.fromString('rejected'), CallStatus.rejected);
      expect(CallStatus.fromString('missed'), CallStatus.missed);
      expect(CallStatus.fromString('cancelled'), CallStatus.cancelled);
      expect(CallStatus.fromString('unknown_val'), CallStatus.unknown);
    });

    test('CallModel serialization and deserialization', () {
      final json = {
        'id': 'call-123',
        'room_name': 'room-456',
        'call_type': 'video',
        'mode': 'group',
        'conversation_id': 'conv-789',
        'initiated_by': 'user-1',
        'status': 'active',
        'started_at': '2026-10-07T10:00:00.000Z',
        'ended_at': '2026-10-07T10:05:00.000Z',
        'duration': 300,
        'participants': [
          {
            'id': 'p-1',
            'user_id': 'user-1',
            'status': 'joined',
            'joined_at': '2026-10-07T10:00:00.000Z',
            'left_at': '2026-10-07T10:05:00.000Z',
            'duration': 300,
          }
        ],
      };

      final model = CallModel.fromJson(json);
      expect(model.id, 'call-123');
      expect(model.roomName, 'room-456');
      expect(model.callType, CallType.video);
      expect(model.mode, CallMode.group);
      expect(model.conversationId, 'conv-789');
      expect(model.status, CallStatus.active);
      expect(model.isVideo, isTrue);
      expect(model.isGroup, isTrue);
      expect(model.duration, 300);
      expect(model.participants.length, 1);
      expect(model.participants.first.userId, 'user-1');

      final serialized = model.toJson();
      expect(serialized['id'], 'call-123');
      expect(serialized['call_type'], 'video');
      expect(serialized['mode'], 'group');
    });

    test('InitiateCallRequest & Responses parsing', () {
      const req = InitiateCallRequest(
        callType: CallType.voice,
        mode: CallMode.direct,
        conversationId: 'c-1',
        participantIds: ['u-2'],
      );

      final reqJson = req.toJson();
      expect(reqJson['call_type'], 'voice');
      expect(reqJson['participant_ids'], ['u-2']);

      final initRes = InitiateCallResponse.fromJson({
        'call': {
          'id': 'c-100',
          'room_name': 'r-100',
          'call_type': 'voice',
          'mode': 'direct',
          'initiated_by': 'u-1',
          'status': 'ringing',
          'started_at': '2026-10-07T10:00:00.000Z',
          'participants': [],
        },
        'token': 'livekit-token-abc',
      });

      expect(initRes.call.id, 'c-100');
      expect(initRes.token, 'livekit-token-abc');

      final joinRes = JoinCallResponse.fromJson({
        'call': {
          'id': 'c-100',
          'room_name': 'r-100',
          'call_type': 'voice',
          'mode': 'direct',
          'initiated_by': 'u-1',
          'status': 'active',
          'started_at': '2026-10-07T10:00:00.000Z',
          'participants': [],
        },
        'token': 'livekit-token-def',
      });

      expect(joinRes.call.status, CallStatus.active);
      expect(joinRes.token, 'livekit-token-def');

      final historyRes = CallHistoryResponse.fromJson({
        'calls': [
          {
            'id': 'c-1',
            'room_name': 'r-1',
            'call_type': 'voice',
            'mode': 'direct',
            'initiated_by': 'u-1',
            'status': 'completed',
            'started_at': '2026-10-07T10:00:00.000Z',
            'participants': [],
          }
        ],
        'total': 1,
      });

      expect(historyRes.calls.length, 1);
      expect(historyRes.total, 1);
    });

    test('UserPresenceModel parsing', () {
      final presence = UserPresenceModel.fromJson({
        'user_id': 'u-10',
        'status': 'online',
        'last_seen_at': '2026-10-07T10:00:00.000Z',
      });

      expect(presence.userId, 'u-10');
      expect(presence.status, 'online');
      expect(presence.toJson()['status'], 'online');
    });

    test('CallWsEvent & WsServerEvent parsing', () {
      final incomingJson = {
        'type': 'incoming_call',
        'call_id': 'c-200',
        'room_name': 'room-200',
        'call_type': 'video',
        'mode': 'direct',
        'initiated_by': 'u-alice',
        'initiator_name': 'Alice',
        'conversation_id': 'conv-10',
      };

      final event = CallWsEvent.fromJson(incomingJson);
      expect(event, isA<WsIncomingCallEvent>());
      final incoming = event as WsIncomingCallEvent;
      expect(incoming.callId, 'c-200');
      expect(incoming.initiatorName, 'Alice');
      expect(incoming.callType, CallType.video);

      final wsServerEvent = WsServerEvent.fromJson(incomingJson);
      expect(wsServerEvent, isA<WsIncomingCallServerEvent>());
      expect((wsServerEvent as WsIncomingCallServerEvent).event.callId, 'c-200');

      final statusJson = {
        'type': 'call_status_update',
        'call_id': 'c-200',
        'status': 'active',
      };
      final statusEvent = CallWsEvent.fromJson(statusJson) as WsCallStatusUpdateEvent;
      expect(statusEvent.status, CallStatus.active);

      final joinedJson = {
        'type': 'participant_joined',
        'call_id': 'c-200',
        'user_id': 'u-bob',
        'username': 'bob',
      };
      final joinedEvent = CallWsEvent.fromJson(joinedJson) as WsParticipantJoinedEvent;
      expect(joinedEvent.username, 'bob');

      final leftJson = {
        'type': 'participant_left',
        'call_id': 'c-200',
        'user_id': 'u-bob',
        'username': 'bob',
      };
      final leftEvent = CallWsEvent.fromJson(leftJson) as WsParticipantLeftEvent;
      expect(leftEvent.username, 'bob');

      final endedJson = {
        'type': 'call_ended',
        'call_id': 'c-200',
        'ended_by': 'u-alice',
        'duration': 120,
      };
      final endedEvent = CallWsEvent.fromJson(endedJson) as WsCallEndedEvent;
      expect(endedEvent.endedBy, 'u-alice');
      expect(endedEvent.duration, 120);
    });
  });
}
