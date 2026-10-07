import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/call_model.dart';

abstract class ICallApiService {
  Future<InitiateCallResponse> initiateCall({
    required String token,
    required InitiateCallRequest request,
  });

  Future<JoinCallResponse> joinCall({
    required String token,
    required String callId,
  });

  Future<CallModel> endCall({
    required String token,
    required String callId,
  });

  Future<CallModel> rejectCall({
    required String token,
    required String callId,
  });

  Future<CallModel> cancelCall({
    required String token,
    required String callId,
  });

  Future<CallHistoryResponse> getCallHistory({
    required String token,
    int limit = 20,
    int offset = 0,
  });

  Future<ActiveCallsResponse> getActiveCalls({
    required String token,
  });

  Future<CallModel> getCall({
    required String token,
    required String callId,
  });

  Future<UserPresenceModel> updatePresence({
    required String token,
    required String status,
  });

  Future<UserPresenceModel> getPresence({
    required String token,
    required String userId,
  });
}

class CallApiService implements ICallApiService {
  final ApiClient _apiClient;

  CallApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<InitiateCallResponse> initiateCall({
    required String token,
    required InitiateCallRequest request,
  }) async {
    final responseData = await _apiClient.post(
      ApiConfig.callsInitiateEndpoint,
      body: request.toJson(),
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return InitiateCallResponse.fromJson(responseData);
    }
    throw const FormatException('Invalid response from initiateCall API');
  }

  @override
  Future<JoinCallResponse> joinCall({
    required String token,
    required String callId,
  }) async {
    final responseData = await _apiClient.post(
      ApiConfig.callJoinEndpoint(callId),
      body: {},
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return JoinCallResponse.fromJson(responseData);
    }
    throw const FormatException('Invalid response from joinCall API');
  }

  @override
  Future<CallModel> endCall({
    required String token,
    required String callId,
  }) async {
    final responseData = await _apiClient.post(
      ApiConfig.callEndEndpoint(callId),
      body: {},
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return CallModel.fromJson(responseData);
    }
    throw const FormatException('Invalid response from endCall API');
  }

  @override
  Future<CallModel> rejectCall({
    required String token,
    required String callId,
  }) async {
    final responseData = await _apiClient.post(
      ApiConfig.callRejectEndpoint(callId),
      body: {},
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return CallModel.fromJson(responseData);
    }
    throw const FormatException('Invalid response from rejectCall API');
  }

  @override
  Future<CallModel> cancelCall({
    required String token,
    required String callId,
  }) async {
    final responseData = await _apiClient.post(
      ApiConfig.callCancelEndpoint(callId),
      body: {},
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return CallModel.fromJson(responseData);
    }
    throw const FormatException('Invalid response from cancelCall API');
  }

  @override
  Future<CallHistoryResponse> getCallHistory({
    required String token,
    int limit = 20,
    int offset = 0,
  }) async {
    final endpoint = '${ApiConfig.callHistoryEndpoint}?limit=$limit&offset=$offset';
    final responseData = await _apiClient.get(
      endpoint,
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return CallHistoryResponse.fromJson(responseData);
    }
    throw const FormatException('Invalid response from getCallHistory API');
  }

  @override
  Future<ActiveCallsResponse> getActiveCalls({
    required String token,
  }) async {
    final responseData = await _apiClient.get(
      ApiConfig.activeCallsEndpoint,
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return ActiveCallsResponse.fromJson(responseData);
    }
    throw const FormatException('Invalid response from getActiveCalls API');
  }

  @override
  Future<CallModel> getCall({
    required String token,
    required String callId,
  }) async {
    final responseData = await _apiClient.get(
      ApiConfig.callDetailEndpoint(callId),
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return CallModel.fromJson(responseData);
    }
    throw const FormatException('Invalid response from getCall API');
  }

  @override
  Future<UserPresenceModel> updatePresence({
    required String token,
    required String status,
  }) async {
    final responseData = await _apiClient.put(
      ApiConfig.presenceEndpoint,
      body: {'status': status},
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return UserPresenceModel.fromJson(responseData);
    }
    throw const FormatException('Invalid response from updatePresence API');
  }

  @override
  Future<UserPresenceModel> getPresence({
    required String token,
    required String userId,
  }) async {
    final responseData = await _apiClient.get(
      ApiConfig.userPresenceEndpoint(userId),
      token: token,
    );

    if (responseData is Map<String, dynamic>) {
      return UserPresenceModel.fromJson(responseData);
    }
    throw const FormatException('Invalid response from getPresence API');
  }
}
