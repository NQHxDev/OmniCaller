import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/features/chat/data/models/chat_models.dart';
import 'package:client/features/chat/presentation/widgets/call_log_bubble.dart';

void main() {
  group('CallLogBubble and CallLogMetadata Tests', () {
    test('CallLogMetadata correctly formats duration and display subtitle status', () {
      // Completed Voice call
      final meta1 = CallLogMetadata.tryParse(jsonEncode({
        'call_id': 'call-1',
        'call_type': 'voice',
        'status': 'completed',
        'duration': 185, // 3m 5s
      }));
      expect(meta1!.formatDuration(), '3 phút 5 giây');
      expect(meta1.titleText(true), 'Cuộc gọi thoại');
      expect(meta1.displayText(true), 'Cuộc gọi thoại - Đã kết thúc');

      // Ongoing Voice call
      final ongoingVoice = CallLogMetadata.tryParse(jsonEncode({
        'call_id': 'call-og-1',
        'call_type': 'voice',
        'status': 'active',
      }));
      expect(ongoingVoice!.isOngoing, isTrue);
      expect(ongoingVoice.displayText(true), 'Cuộc gọi thoại - Đang diễn ra');

      // Completed Video call
      final meta3 = CallLogMetadata.tryParse(jsonEncode({
        'call_id': 'call-3',
        'call_type': 'video',
        'status': 'completed',
        'duration': 45, // 45s
      }));
      expect(meta3!.formatDuration(), '45 giây');
      expect(meta3.titleText(true), 'Cuộc gọi video');
      expect(meta3.displayText(true), 'Cuộc gọi video - Đã kết thúc');

      // Ongoing Video call
      final ongoingVideo = CallLogMetadata.tryParse(jsonEncode({
        'call_id': 'call-og-2',
        'call_type': 'video',
        'status': 'ongoing',
      }));
      expect(ongoingVideo!.isOngoing, isTrue);
      expect(ongoingVideo.displayText(true), 'Cuộc gọi video - Đang diễn ra');

      // Video call: hours only (e.g. 1h 0m 0s)
      final meta4 = CallLogMetadata.tryParse(jsonEncode({
        'call_id': 'call-4',
        'call_type': 'video',
        'status': 'completed',
        'duration': 3600, // 1h 0m
      }));
      expect(meta4!.formatDuration(), '1 giờ');

      // Video call: hours and minutes
      final meta5 = CallLogMetadata.tryParse(jsonEncode({
        'call_id': 'call-5',
        'call_type': 'video',
        'status': 'completed',
        'duration': 3720, // 1h 2m
      }));
      expect(meta5!.formatDuration(), '1 giờ 2 phút');

      // Missed call
      final missedMeta = CallLogMetadata.tryParse(jsonEncode({
        'call_id': 'c-2',
        'call_type': 'video',
        'status': 'missed',
      }));
      expect(missedMeta!.isVideo, isTrue);
      expect(missedMeta.isMissed, isTrue);
      expect(missedMeta.displayText(true), 'Cuộc gọi video bị nhỡ');
      expect(missedMeta.displayText(false), 'Cuộc gọi nhỡ');
    });

    testWidgets('CallLogBubble renders completed voice call log with duration on separate line', (tester) async {
      final msg = MessageModel(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderUsername: 'alice',
        senderDisplayName: 'Alice',
        messageType: MessageType.callLog,
        content: jsonEncode({
          'call_id': 'c-1',
          'call_type': 'voice',
          'mode': 'direct',
          'status': 'completed',
          'duration': 120,
        }),
        createdAt: DateTime(2026, 10, 7, 14, 30),
        updatedAt: DateTime(2026, 10, 7, 14, 32),
      );

      bool callBackClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallLogBubble(
              message: msg,
              isMine: true,
              onCallBack: () => callBackClicked = true,
            ),
          ),
        ),
      );

      // Verify title and duration are separate widgets
      expect(find.text('Cuộc gọi thoại'), findsOneWidget);
      expect(find.text('2 phút'), findsOneWidget);
      expect(find.text('Nhấn để gọi lại'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      expect(callBackClicked, isTrue);
    });

    testWidgets('CallLogBubble renders completed video call log with hours and minutes on separate line', (tester) async {
      final msg = MessageModel(
        id: 'msg-v1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderUsername: 'alice',
        senderDisplayName: 'Alice',
        messageType: MessageType.callLog,
        content: jsonEncode({
          'call_id': 'c-v1',
          'call_type': 'video',
          'mode': 'direct',
          'status': 'completed',
          'duration': 3720,
        }),
        createdAt: DateTime(2026, 10, 7, 14, 30),
        updatedAt: DateTime(2026, 10, 7, 15, 32),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallLogBubble(
              message: msg,
              isMine: true,
            ),
          ),
        ),
      );

      expect(find.text('Cuộc gọi video'), findsOneWidget);
      expect(find.text('1 giờ 2 phút'), findsOneWidget);
    });

    testWidgets('CallLogBubble renders missed call log UI', (tester) async {
      final msg = MessageModel(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'user-2',
        senderUsername: 'bob',
        senderDisplayName: 'Bob',
        messageType: MessageType.callLog,
        content: jsonEncode({
          'call_id': 'c-2',
          'call_type': 'video',
          'mode': 'direct',
          'status': 'missed',
        }),
        createdAt: DateTime(2026, 10, 7, 15, 0),
        updatedAt: DateTime(2026, 10, 7, 15, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallLogBubble(
              message: msg,
              isMine: false,
            ),
          ),
        ),
      );

      expect(find.text('Cuộc gọi nhỡ'), findsOneWidget);
    });
  });
}
