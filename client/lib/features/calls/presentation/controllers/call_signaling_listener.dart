import 'dart:async';
import 'package:flutter/material.dart';
import 'package:client/features/chat/data/models/ws_models.dart';
import 'package:client/features/chat/data/services/chat_websocket_service.dart';
import '../pages/incoming_call_page.dart';
import '../pages/outgoing_call_page.dart';
import 'call_controller.dart';
import '../../data/models/call_model.dart';

class CallSignalingListener {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final CallController callController;
  final IChatWebSocketService wsService;
  StreamSubscription? _wsSubscription;

  CallSignalingListener({
    required this.callController,
    IChatWebSocketService? wsService,
  }) : wsService = wsService ?? ChatWebSocketService() {
    _startListening();
  }

  void _startListening() {
    _wsSubscription?.cancel();
    _wsSubscription = wsService.events.listen((event) {
      _handleWsEvent(event);
    });
  }

  void _handleWsEvent(WsServerEvent event) {
    if (event is WsIncomingCallServerEvent) {
      callController.handleIncomingCall(event.event);
      _showIncomingCallUI();
    } else if (event is WsCallStatusUpdateServerEvent) {
      callController.handleCallStatusUpdate(event.event);
    } else if (event is WsParticipantJoinedServerEvent) {
      callController.handleParticipantJoined(event.event);
    } else if (event is WsParticipantLeftServerEvent) {
      callController.handleParticipantLeft(event.event);
    } else if (event is WsCallEndedServerEvent) {
      callController.handleCallEnded(event.event);
    }
  }

  void _showIncomingCallUI() {
    final navState = navigatorKey.currentState;
    if (navState != null) {
      navState.push(
        MaterialPageRoute(
          builder: (_) => IncomingCallPage(controller: callController),
        ),
      );
    }
  }

  /// Launch an outgoing voice/video call and open OutgoingCallPage
  Future<bool> startCall({
    required BuildContext context,
    required CallType callType,
    required CallMode mode,
    required List<String> participantIds,
    String? conversationId,
    String? calleeName,
    String? calleeAvatar,
    String? calleeUserId,
  }) async {
    final navState = Navigator.of(context);
    
    // Navigate to OutgoingCallPage first
    navState.push(
      MaterialPageRoute(
        builder: (_) => OutgoingCallPage(controller: callController),
      ),
    );

    final success = await callController.startOutgoingCall(
      callType: callType,
      mode: mode,
      participantIds: participantIds,
      conversationId: conversationId,
      calleeName: calleeName,
      calleeAvatar: calleeAvatar,
      calleeUserId: calleeUserId,
    );

    if (!success) {
      if (context.mounted && callController.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(callController.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    return success;
  }

  void dispose() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
  }
}
