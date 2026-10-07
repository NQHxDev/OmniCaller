import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/features/calls/data/models/call_event_model.dart';
import 'package:client/features/calls/data/models/call_model.dart';
import 'package:client/features/calls/presentation/controllers/call_controller.dart';
import 'package:client/features/calls/presentation/pages/active_call_page.dart';
import 'package:client/features/calls/presentation/pages/incoming_call_page.dart';
import 'package:client/features/calls/presentation/pages/outgoing_call_page.dart';
import 'package:client/features/calls/presentation/widgets/call_controls_bar.dart';
import 'package:client/features/calls/presentation/widgets/call_timer_widget.dart';
import 'package:client/features/calls/presentation/widgets/speaking_avatar_widget.dart';
import 'call_controller_test.dart';

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

  group('Call Widgets & Pages Tests', () {
    testWidgets('CallTimerWidget displays duration correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CallTimerWidget(duration: '02:30'),
          ),
        ),
      );

      expect(find.text('02:30'), findsOneWidget);
    });

    testWidgets('SpeakingAvatarWidget renders idle and speaking soundwave states', (tester) async {
      // Idle state: no SoundwaveRipplePainter
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeakingAvatarWidget(
              name: 'Alice',
              isSpeaking: false,
              radius: 64,
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is SoundwaveRipplePainter),
        findsNothing,
      );

      // Speaking state: SoundwaveRipplePainter soundwave ripples active
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeakingAvatarWidget(
              name: 'Alice',
              isSpeaking: true,
              radius: 64,
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is SoundwaveRipplePainter),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('CallControlsBar triggers callbacks on tap', (tester) async {
      bool micToggled = false;
      bool camToggled = false;
      bool switchCamToggled = false;
      bool speakerToggled = false;
      bool endCallToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallControlsBar(
              isMicMuted: false,
              isCameraOff: false,
              isSpeakerphoneOn: true,
              isVideoCall: true,
              onToggleMic: () => micToggled = true,
              onToggleCamera: () => camToggled = true,
              onSwitchCamera: () => switchCamToggled = true,
              onToggleSpeaker: () => speakerToggled = true,
              onEndCall: () => endCallToggled = true,
            ),
          ),
        ),
      );

      // Tap Mute Mic (tooltip 'Mute')
      await tester.tap(find.byTooltip('Mute'));
      expect(micToggled, isTrue);

      // Tap Cam (tooltip 'Turn Cam Off')
      await tester.tap(find.byTooltip('Turn Cam Off'));
      expect(camToggled, isTrue);

      // Tap Switch Cam (tooltip 'Switch Camera')
      await tester.tap(find.byTooltip('Switch Camera'));
      expect(switchCamToggled, isTrue);

      // Tap Speaker (tooltip 'Speaker On')
      await tester.tap(find.byTooltip('Speaker On'));
      expect(speakerToggled, isTrue);

      // Tap End Call
      await tester.tap(find.byTooltip('End Call'));
      expect(endCallToggled, isTrue);
    });

    testWidgets('IncomingCallPage displays caller info and buttons', (tester) async {
      final mockApi = MockCallApiService();
      final mockLivekit = MockLiveKitService();
      final controller = CallController(
        apiService: mockApi,
        livekitService: mockLivekit,
        token: 'test-token',
        currentUserId: 'my-id',
      );

      controller.handleIncomingCall(
        const WsIncomingCallEvent(
          callId: 'call-1',
          roomName: 'room-1',
          callType: CallType.voice,
          mode: CallMode.direct,
          initiatedBy: 'user-alice',
          initiatorName: 'Alice',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: IncomingCallPage(controller: controller),
        ),
      );

      expect(find.text('Incoming Voice Call'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Ringing...'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);

      // Tap Decline
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();
      expect(mockApi.rejectCalled, isTrue);

      controller.dispose();
    });

    testWidgets('OutgoingCallPage displays callee info and cancel button', (tester) async {
      final mockApi = MockCallApiService();
      final mockLivekit = MockLiveKitService();
      final controller = CallController(
        apiService: mockApi,
        livekitService: mockLivekit,
        token: 'test-token',
        currentUserId: 'my-id',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OutgoingCallPage(controller: controller),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      controller.dispose();
    });

    testWidgets('ActiveCallPage renders voice call UI and updates speaking ripples', (tester) async {
      final mockApi = MockCallApiService();
      final mockLivekit = MockLiveKitService();
      final controller = CallController(
        apiService: mockApi,
        livekitService: mockLivekit,
        token: 'test-token',
        currentUserId: 'my-id',
      );

      controller.handleIncomingCall(
        const WsIncomingCallEvent(
          callId: 'call-1',
          roomName: 'room-1',
          callType: CallType.voice,
          mode: CallMode.direct,
          initiatedBy: 'user-bob',
          initiatorName: 'Bob',
        ),
      );
      await controller.acceptCall();

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveCallPage(controller: controller),
        ),
      );

      expect(find.text('Voice Call'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.byType(CallTimerWidget), findsOneWidget);
      expect(find.byType(SpeakingAvatarWidget), findsOneWidget);
      expect(find.byType(CallControlsBar), findsOneWidget);

      // Initially not speaking
      expect(controller.isRemoteSpeaking, isFalse);

      // Simulate remote participant speaking
      controller.setRemoteSpeakingForTesting(true);
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.isRemoteSpeaking, isTrue);
      expect(find.text('Đang nói...'), findsOneWidget);

      controller.dispose();
    });
  });
}
