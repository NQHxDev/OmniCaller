import 'dart:convert';
import 'package:client/core/network/api_client.dart';
import 'package:client/features/calls/data/models/call_model.dart';
import 'package:client/features/calls/data/services/call_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('CallApiService Tests', () {
    test('initiateCall sends POST /api/calls/initiate and returns InitiateCallResponse', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/calls/initiate');
        expect(request.headers['Authorization'], 'Bearer test_token');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['call_type'], 'voice');
        expect(body['mode'], 'direct');
        expect(body['participant_ids'], ['u-callee']);

        return http.Response(
          jsonEncode({
            'call': {
              'id': 'call-100',
              'room_name': 'room-100',
              'call_type': 'voice',
              'mode': 'direct',
              'conversation_id': null,
              'initiated_by': 'u-initiator',
              'status': 'ringing',
              'started_at': '2026-10-07T10:00:00Z',
              'participants': [],
            },
            'token': 'livekit-initiator-jwt',
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = CallApiService(apiClient: ApiClient(client: mockClient));
      final res = await service.initiateCall(
        token: 'test_token',
        request: const InitiateCallRequest(
          callType: CallType.voice,
          mode: CallMode.direct,
          participantIds: ['u-callee'],
        ),
      );

      expect(res.call.id, 'call-100');
      expect(res.call.callType, CallType.voice);
      expect(res.token, 'livekit-initiator-jwt');
    });

    test('joinCall sends POST /api/calls/:id/join and returns JoinCallResponse', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/calls/call-100/join');
        expect(request.headers['Authorization'], 'Bearer test_token');

        return http.Response(
          jsonEncode({
            'call': {
              'id': 'call-100',
              'room_name': 'room-100',
              'call_type': 'video',
              'mode': 'direct',
              'initiated_by': 'u-initiator',
              'status': 'active',
              'started_at': '2026-10-07T10:00:00Z',
              'participants': [],
            },
            'token': 'livekit-joiner-jwt',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = CallApiService(apiClient: ApiClient(client: mockClient));
      final res = await service.joinCall(
        token: 'test_token',
        callId: 'call-100',
      );

      expect(res.call.id, 'call-100');
      expect(res.call.status, CallStatus.active);
      expect(res.token, 'livekit-joiner-jwt');
    });

    test('endCall sends POST /api/calls/:id/end and returns CallModel', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/calls/call-100/end');
        expect(request.headers['Authorization'], 'Bearer test_token');

        return http.Response(
          jsonEncode({
            'id': 'call-100',
            'room_name': 'room-100',
            'call_type': 'voice',
            'mode': 'direct',
            'initiated_by': 'u-initiator',
            'status': 'completed',
            'started_at': '2026-10-07T10:00:00Z',
            'ended_at': '2026-10-07T10:05:00Z',
            'duration': 300,
            'participants': [],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = CallApiService(apiClient: ApiClient(client: mockClient));
      final res = await service.endCall(
        token: 'test_token',
        callId: 'call-100',
      );

      expect(res.id, 'call-100');
      expect(res.status, CallStatus.completed);
      expect(res.duration, 300);
    });

    test('rejectCall and cancelCall send POST requests', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path == '/api/calls/c-1/reject' ||
              request.url.path == '/api/calls/c-1/cancel',
          isTrue,
        );

        return http.Response(
          jsonEncode({
            'id': 'c-1',
            'room_name': 'r-1',
            'call_type': 'voice',
            'mode': 'direct',
            'initiated_by': 'u-initiator',
            'status': request.url.path.contains('reject') ? 'rejected' : 'missed',
            'started_at': '2026-10-07T10:00:00Z',
            'participants': [],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = CallApiService(apiClient: ApiClient(client: mockClient));
      final rejectRes = await service.rejectCall(token: 't', callId: 'c-1');
      expect(rejectRes.status, CallStatus.rejected);

      final cancelRes = await service.cancelCall(token: 't', callId: 'c-1');
      expect(cancelRes.status, CallStatus.missed);
    });

    test('getCallHistory, getActiveCalls, and getCall send GET requests', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        if (request.url.path == '/api/calls/history') {
          return http.Response(
            jsonEncode({
              'calls': [
                {
                  'id': 'c-1',
                  'room_name': 'r-1',
                  'call_type': 'voice',
                  'mode': 'direct',
                  'initiated_by': 'u-initiator',
                  'status': 'completed',
                  'started_at': '2026-10-07T10:00:00Z',
                  'participants': [],
                }
              ],
              'total': 1,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.url.path == '/api/calls/active') {
          return http.Response(
            jsonEncode({
              'calls': [],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.url.path == '/api/calls/c-1') {
          return http.Response(
            jsonEncode({
              'id': 'c-1',
              'room_name': 'r-1',
              'call_type': 'voice',
              'mode': 'direct',
              'initiated_by': 'u-initiator',
              'status': 'active',
              'started_at': '2026-10-07T10:00:00Z',
              'participants': [],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = CallApiService(apiClient: ApiClient(client: mockClient));
      final history = await service.getCallHistory(token: 't');
      expect(history.calls.length, 1);

      final active = await service.getActiveCalls(token: 't');
      expect(active.calls, isEmpty);

      final detail = await service.getCall(token: 't', callId: 'c-1');
      expect(detail.id, 'c-1');
    });

    test('updatePresence and getPresence send requests', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'PUT' && request.url.path == '/api/presence') {
          return http.Response(
            jsonEncode({
              'user_id': 'u-1',
              'status': 'in_call',
              'last_seen_at': '2026-10-07T10:00:00Z',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.method == 'GET' && request.url.path == '/api/presence/u-1') {
          return http.Response(
            jsonEncode({
              'user_id': 'u-1',
              'status': 'online',
              'last_seen_at': '2026-10-07T10:00:00Z',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = CallApiService(apiClient: ApiClient(client: mockClient));
      final updated = await service.updatePresence(token: 't', status: 'in_call');
      expect(updated.status, 'in_call');

      final presence = await service.getPresence(token: 't', userId: 'u-1');
      expect(presence.status, 'online');
    });
  });
}
