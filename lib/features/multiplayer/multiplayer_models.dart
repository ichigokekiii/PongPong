import 'dart:convert';

import 'package:pongpong/features/scan/scanned_area_model.dart';

enum SessionRole { host, joiner }

enum MultiplayerConnectionStatus {
  idle,
  hosting,
  waitingForJoiner,
  joining,
  connected,
  disconnected,
  error,
}

class PairingPayload {
  const PairingPayload({
    required this.roomId,
    required this.hostAddress,
    required this.port,
    required this.token,
  });

  final String roomId;
  final String hostAddress;
  final int port;
  final String token;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'roomId': roomId,
      'hostAddress': hostAddress,
      'port': port,
      'token': token,
    };
  }

  String encode() => jsonEncode(toJson());

  factory PairingPayload.fromJson(Map<String, dynamic> json) {
    return PairingPayload(
      roomId: json['roomId'] as String? ?? '',
      hostAddress: json['hostAddress'] as String? ?? '',
      port: json['port'] as int? ?? 0,
      token: json['token'] as String? ?? '',
    );
  }

  static PairingPayload parse(String raw) {
    final dynamic decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('QR payload is not a JSON object.');
    }

    final payload = PairingPayload.fromJson(decoded);
    if (payload.roomId.isEmpty ||
        payload.hostAddress.isEmpty ||
        payload.port <= 0 ||
        payload.token.isEmpty) {
      throw const FormatException('QR payload is missing required fields.');
    }

    return payload;
  }
}

class SharedScanState {
  const SharedScanState({
    required this.step,
    required this.area,
    this.confirmed = false,
  });

  final ScanStep step;
  final ScannedAreaModel area;
  final bool confirmed;

  SharedScanState copyWith({
    ScanStep? step,
    ScannedAreaModel? area,
    bool? confirmed,
  }) {
    return SharedScanState(
      step: step ?? this.step,
      area: area ?? this.area,
      confirmed: confirmed ?? this.confirmed,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'step': step.name,
      'area': area.toJson(),
      'confirmed': confirmed,
    };
  }

  factory SharedScanState.fromJson(Map<String, dynamic> json) {
    return SharedScanState(
      step: ScanStepPresentation.fromName(json['step'] as String? ?? ''),
      area: ScannedAreaModel.fromJson(
        (json['area'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      confirmed: json['confirmed'] as bool? ?? false,
    );
  }
}

class MultiplayerSessionState {
  const MultiplayerSessionState({
    this.role,
    this.connectionStatus = MultiplayerConnectionStatus.idle,
    this.payload,
    required this.sharedScanState,
    this.peerConnected = false,
    this.localCalibrationReady = false,
    this.peerCalibrationReady = false,
    this.errorMessage,
    this.disconnectReason,
  });

  final SessionRole? role;
  final MultiplayerConnectionStatus connectionStatus;
  final PairingPayload? payload;
  final SharedScanState sharedScanState;
  final bool peerConnected;
  final bool localCalibrationReady;
  final bool peerCalibrationReady;
  final String? errorMessage;
  final String? disconnectReason;

  bool get isHost => role == SessionRole.host;
  bool get isJoiner => role == SessionRole.joiner;
  bool get isConnected => connectionStatus == MultiplayerConnectionStatus.connected;
  bool get canControlScan => isHost && isConnected;
  bool get readyForGame =>
      isConnected && localCalibrationReady && peerCalibrationReady;

  MultiplayerSessionState copyWith({
    SessionRole? role,
    MultiplayerConnectionStatus? connectionStatus,
    PairingPayload? payload,
    SharedScanState? sharedScanState,
    bool? peerConnected,
    bool? localCalibrationReady,
    bool? peerCalibrationReady,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? disconnectReason,
    bool clearDisconnectReason = false,
  }) {
    return MultiplayerSessionState(
      role: role ?? this.role,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      payload: payload ?? this.payload,
      sharedScanState: sharedScanState ?? this.sharedScanState,
      peerConnected: peerConnected ?? this.peerConnected,
      localCalibrationReady:
          localCalibrationReady ?? this.localCalibrationReady,
      peerCalibrationReady: peerCalibrationReady ?? this.peerCalibrationReady,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      disconnectReason: clearDisconnectReason
          ? null
          : disconnectReason ?? this.disconnectReason,
    );
  }

  static const initial = MultiplayerSessionState(
    sharedScanState: SharedScanState(
      step: ScanStep.leftBoundary,
      area: ScannedAreaModel(
        leftReachMeters: 1.2,
        rightReachMeters: 1.3,
        lengthMeters: 3.0,
      ),
    ),
  );
}
