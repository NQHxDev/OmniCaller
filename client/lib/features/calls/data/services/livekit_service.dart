import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

abstract class ILiveKitService {
  Room? get room;
  bool get isConnected;
  EventsListener<RoomEvent>? get listener;

  Future<void> connect({
    required String url,
    required String token,
    bool isVideoCall = false,
  });

  Future<void> setMicrophoneEnabled(bool enabled);
  Future<void> setCameraEnabled(bool enabled);
  Future<void> switchCamera();
  Future<void> setSpeakerphoneEnabled(bool enabled);
  Future<void> disconnect();
  Future<void> dispose();
}

class LiveKitService implements ILiveKitService {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _speakerphoneEnabled = true;

  @override
  Room? get room => _room;

  @override
  bool get isConnected => _room?.connectionState == ConnectionState.connected;

  @override
  EventsListener<RoomEvent>? get listener => _listener;

  @override
  Future<void> connect({
    required String url,
    required String token,
    bool isVideoCall = false,
  }) async {
    try {
      await disconnect();

      const roomOptions = RoomOptions(
        adaptiveStream: false,
        dynacast: false,
        defaultCameraCaptureOptions: CameraCaptureOptions(
          maxFrameRate: 24,
          params: VideoParametersPresets.h360_169,
        ),
        defaultVideoPublishOptions: VideoPublishOptions(
          simulcast: false,
          videoCodec: 'VP8',
        ),
        defaultAudioCaptureOptions: AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
      );

      _room = Room(roomOptions: roomOptions);
      _listener = _room!.createListener();

      await _room!.connect(
        url,
        token,
        connectOptions: const ConnectOptions(
          autoSubscribe: true,
          protocolVersion: ProtocolVersion.v11,
        ),
      );

      // Setup initial publishing
      try {
        await _room!.localParticipant?.setMicrophoneEnabled(true);
      } catch (e) {
        debugPrint('setMicrophoneEnabled on connect error: $e');
      }

      if (isVideoCall) {
        try {
          await _room!.localParticipant?.setCameraEnabled(true);
        } catch (e) {
          debugPrint('setCameraEnabled on connect error: $e');
        }
      } else {
        try {
          await _room!.localParticipant?.setCameraEnabled(false);
        } catch (_) {}
      }

      // Configure speakerphone
      await setSpeakerphoneEnabled(isVideoCall || _speakerphoneEnabled);
    } catch (e) {
      debugPrint('LiveKitService connect error: $e');
      await disconnect();
      rethrow;
    }
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(enabled);
    } catch (e) {
      debugPrint('setMicrophoneEnabled error: $e');
    }
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    try {
      await _room?.localParticipant?.setCameraEnabled(enabled);
    } catch (e) {
      debugPrint('setCameraEnabled error: $e');
    }
  }

  @override
  Future<void> switchCamera() async {
    try {
      final videoTrack = _room?.localParticipant?.videoTrackPublications
          .map((e) => e.track)
          .whereType<LocalVideoTrack>()
          .firstOrNull;

      if (videoTrack != null) {
        final options = videoTrack.currentOptions;
        final currentPosition = options is CameraCaptureOptions
            ? options.cameraPosition
            : CameraPosition.front;
        final nextPosition = currentPosition == CameraPosition.front
            ? CameraPosition.back
            : CameraPosition.front;
        await videoTrack.setCameraPosition(nextPosition);
      }
    } catch (e) {
      debugPrint('switchCamera error: $e');
    }
  }

  @override
  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    _speakerphoneEnabled = enabled;
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(enabled);
    } catch (e) {
      debugPrint('setSpeakerphoneEnabled error: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      if (_listener != null) {
        await _listener!.dispose();
        _listener = null;
      }
      if (_room != null) {
        await _room!.disconnect();
        await _room!.dispose();
        _room = null;
      }
    } catch (e) {
      debugPrint('LiveKitService disconnect error: $e');
      _room = null;
      _listener = null;
    }
  }

  @override
  Future<void> dispose() async {
    await disconnect();
  }
}
