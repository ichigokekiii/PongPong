import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pongpong/features/multiplayer/multiplayer_models.dart';
import 'package:pongpong/features/scan/scan_controller.dart';

class MultiplayerSessionController extends ChangeNotifier {
  MultiplayerSessionController({
    InternetAddress? defaultBindAddress,
    String? advertisedHostAddress,
  })  : _defaultBindAddress = defaultBindAddress,
        _advertisedHostAddress = advertisedHostAddress;

  final InternetAddress? _defaultBindAddress;
  final String? _advertisedHostAddress;

  MultiplayerSessionState _state = MultiplayerSessionState.initial;
  HttpServer? _server;
  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  StreamSubscription<HttpRequest>? _serverSubscription;
  PairingPayload? _lastJoinPayload;

  MultiplayerSessionState get state => _state;

  PairingPayload? get payload => _state.payload;

  bool get isHost => _state.isHost;

  Future<void> hostSession({
    InternetAddress? bindAddress,
    String? advertisedHostAddress,
  }) async {
    await _disposeTransport();
    _state = MultiplayerSessionState.initial.copyWith(
      role: SessionRole.host,
      connectionStatus: MultiplayerConnectionStatus.hosting,
      clearErrorMessage: true,
      clearDisconnectReason: true,
    );
    notifyListeners();

    try {
      final server = await HttpServer.bind(
        bindAddress ?? _defaultBindAddress ?? InternetAddress.anyIPv4,
        0,
        shared: true,
      );
      _server = server;
      final advertisedAddresses =
          await _resolveAdvertisedHostAddresses(advertisedHostAddress);
      final sessionPayload = PairingPayload(
        roomId: _generateToken(length: 6).toUpperCase(),
        hostAddress: advertisedAddresses.first,
        port: server.port,
        token: _generateToken(length: 12),
        hostAddresses: advertisedAddresses,
      );
      _serverSubscription = server.listen(_handleIncomingRequest);
      _state = _state.copyWith(
        connectionStatus: MultiplayerConnectionStatus.waitingForJoiner,
        payload: sessionPayload,
        peerConnected: false,
        localCalibrationReady: false,
        peerCalibrationReady: false,
      );
      notifyListeners();
    } catch (error) {
      _setError('Unable to host a multiplayer session.', error);
    }
  }

  Future<void> joinSession(PairingPayload payload) async {
    await _disposeTransport();
    _lastJoinPayload = payload;
    _state = MultiplayerSessionState.initial.copyWith(
      role: SessionRole.joiner,
      connectionStatus: MultiplayerConnectionStatus.joining,
      payload: payload,
      clearErrorMessage: true,
      clearDisconnectReason: true,
    );
    notifyListeners();

    try {
      final socket = await _connectToPairingPayload(payload);
      await _attachSocket(socket);
      _sendMessage(<String, dynamic>{
        'type': 'join_request',
        'roomId': payload.roomId,
        'token': payload.token,
      });
    } catch (error) {
      _setError('Unable to join the host session.', error);
    }
  }

  Future<void> retryJoin() async {
    if (_lastJoinPayload == null) {
      return;
    }

    await joinSession(_lastJoinPayload!);
  }

  void setWidth(double value) {
    if (!_state.canControlScan) {
      return;
    }

    _pushSharedScan(
      _state.sharedScanState.copyWith(
        area: _state.sharedScanState.area.copyWith(widthMeters: value),
      ),
    );
  }

  void setLength(double value) {
    if (!_state.canControlScan) {
      return;
    }

    _pushSharedScan(
      _state.sharedScanState.copyWith(
        area: _state.sharedScanState.area.copyWith(lengthMeters: value),
      ),
    );
  }

  void captureCurrentStep() {
    if (!_state.canControlScan) {
      return;
    }

    final step = _state.sharedScanState.step;
    if (step == ScanStep.confirm) {
      return;
    }

    final area = _state.sharedScanState.area;
    final nextState = switch (step) {
      ScanStep.left => _state.sharedScanState.copyWith(
          step: ScanStep.right,
          area: area.copyWith(leftBoundaryCaptured: true),
        ),
      ScanStep.right => _state.sharedScanState.copyWith(
          step: ScanStep.length,
          area: area.copyWith(rightBoundaryCaptured: true),
        ),
      ScanStep.length => _state.sharedScanState.copyWith(
          step: ScanStep.confirm,
          area: area.copyWith(lengthCaptured: true),
        ),
      ScanStep.confirm => _state.sharedScanState,
    };

    _pushSharedScan(nextState);
  }

  void goBack() {
    if (!_state.canControlScan) {
      return;
    }

    final step = _state.sharedScanState.step;
    if (step == ScanStep.left) {
      return;
    }

    _pushSharedScan(
      _state.sharedScanState.copyWith(
        step: ScanStep.values[step.index - 1],
      ),
    );
  }

  void confirmSharedScan() {
    if (!_state.canControlScan) {
      return;
    }

    final confirmedState = _state.sharedScanState.copyWith(confirmed: true);
    _state = _state.copyWith(sharedScanState: confirmedState);
    notifyListeners();
    _sendMessage(<String, dynamic>{
      'type': 'scan_confirmed',
      'sharedScanState': confirmedState.toJson(),
    });
  }

  void markCalibrationReady() {
    if (!_state.isConnected || _state.localCalibrationReady) {
      return;
    }

    _state = _state.copyWith(localCalibrationReady: true);
    notifyListeners();
    _sendMessage(<String, dynamic>{'type': 'calibration_ready'});
  }

  Future<void> closeSession({String reason = 'Session closed'}) async {
    _sendMessage(<String, dynamic>{'type': 'session_closed', 'reason': reason});
    await _disposeTransport();
    _state = MultiplayerSessionState.initial.copyWith(
      role: _state.role,
      connectionStatus: MultiplayerConnectionStatus.disconnected,
      disconnectReason: reason,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_disposeTransport());
    super.dispose();
  }

  Future<void> _handleIncomingRequest(HttpRequest request) async {
    if (_socket != null) {
      await WebSocketTransformer.upgrade(request).then((socket) async {
        await socket.close(WebSocketStatus.policyViolation, 'Session is full');
      });
      return;
    }

    try {
      final socket = await WebSocketTransformer.upgrade(request);
      await _attachSocket(socket);
    } catch (error) {
      _setError('Unable to accept the join request.', error);
    }
  }

  Future<void> _attachSocket(WebSocket socket) async {
    await _socketSubscription?.cancel();
    _socket = socket;
    _socketSubscription = socket.listen(
      _handleRawMessage,
      onDone: _handleSocketDone,
      onError: (Object error) {
        _setError('The session connection dropped.', error);
      },
      cancelOnError: true,
    );
  }

  void _handleRawMessage(dynamic rawMessage) {
    if (rawMessage is! String) {
      return;
    }

    final dynamic decoded = jsonDecode(rawMessage);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    final type = decoded['type'] as String?;
    switch (type) {
      case 'join_request':
        _handleJoinRequest(decoded);
        break;
      case 'join_accepted':
        _handleJoinAccepted(decoded);
        break;
      case 'scan_update':
        _applySharedScan(
          Map<String, dynamic>.from(
            decoded['sharedScanState'] as Map? ?? <String, dynamic>{},
          ),
        );
        break;
      case 'scan_confirmed':
        final payload = Map<String, dynamic>.from(
          decoded['sharedScanState'] as Map? ?? <String, dynamic>{},
        );
        final sharedScan = SharedScanState.fromJson(payload);
        _state = _state.copyWith(sharedScanState: sharedScan);
        notifyListeners();
        break;
      case 'calibration_ready':
        _state = _state.copyWith(peerCalibrationReady: true);
        notifyListeners();
        break;
      case 'session_closed':
        final reason = decoded['reason'] as String? ?? 'Session closed';
        _handleRemoteDisconnect(reason);
        break;
      case null:
        break;
    }
  }

  void _handleJoinRequest(Map<String, dynamic> message) {
    if (!_state.isHost || _state.payload == null) {
      return;
    }

    final roomId = message['roomId'] as String? ?? '';
    final token = message['token'] as String? ?? '';
    if (roomId != _state.payload!.roomId || token != _state.payload!.token) {
      _sendMessage(<String, dynamic>{
        'type': 'session_closed',
        'reason': 'Join request was rejected.',
      });
      _socket?.close(WebSocketStatus.policyViolation, 'Invalid join token');
      return;
    }

    _state = _state.copyWith(
      connectionStatus: MultiplayerConnectionStatus.connected,
      peerConnected: true,
      clearErrorMessage: true,
      clearDisconnectReason: true,
    );
    notifyListeners();
    _sendMessage(<String, dynamic>{
      'type': 'join_accepted',
      'sharedScanState': _state.sharedScanState.toJson(),
    });
  }

  void _handleJoinAccepted(Map<String, dynamic> message) {
    final payload = message['sharedScanState'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    _state = _state.copyWith(
      connectionStatus: MultiplayerConnectionStatus.connected,
      peerConnected: true,
      sharedScanState: SharedScanState.fromJson(payload),
      clearErrorMessage: true,
      clearDisconnectReason: true,
    );
    notifyListeners();
  }

  void _applySharedScan(Map<String, dynamic> payload) {
    _state =
        _state.copyWith(sharedScanState: SharedScanState.fromJson(payload));
    notifyListeners();
  }

  void _pushSharedScan(SharedScanState sharedScanState) {
    _state = _state.copyWith(sharedScanState: sharedScanState);
    notifyListeners();
    _sendMessage(<String, dynamic>{
      'type': 'scan_update',
      'sharedScanState': sharedScanState.toJson(),
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    final socket = _socket;
    if (socket == null || socket.closeCode != null) {
      return;
    }

    socket.add(jsonEncode(message));
  }

  void _handleSocketDone() {
    if (_state.connectionStatus == MultiplayerConnectionStatus.disconnected) {
      return;
    }

    final reason = _state.disconnectReason ??
        'The other phone left the multiplayer session.';
    _state = _state.copyWith(
      connectionStatus: MultiplayerConnectionStatus.disconnected,
      peerConnected: false,
      disconnectReason: reason,
    );
    notifyListeners();
  }

  void _handleRemoteDisconnect(String reason) {
    _state = _state.copyWith(
      connectionStatus: MultiplayerConnectionStatus.disconnected,
      peerConnected: false,
      disconnectReason: reason,
    );
    notifyListeners();
  }

  void _setError(String message, Object error) {
    _state = _state.copyWith(
      connectionStatus: MultiplayerConnectionStatus.error,
      errorMessage: '$message ${error.toString()}',
      peerConnected: false,
    );
    notifyListeners();
  }

  Future<void> _disposeTransport() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _socket?.close();
    _socket = null;
    await _serverSubscription?.cancel();
    _serverSubscription = null;
    await _server?.close(force: true);
    _server = null;
  }

  Future<WebSocket> _connectToPairingPayload(PairingPayload payload) async {
    Object? lastError;
    for (final address in payload.connectionAddresses) {
      try {
        return await WebSocket.connect(
          'ws://$address:${payload.port}',
        ).timeout(const Duration(seconds: 3));
      } catch (error) {
        lastError = error;
      }
    }

    throw SocketException(
      'Unable to reach host on ${payload.connectionAddresses.join(', ')}${lastError == null ? '' : ' ($lastError)'}',
    );
  }

  Future<List<String>> _resolveAdvertisedHostAddresses(
    String? advertisedHostAddress,
  ) async {
    final candidates = <String>[];

    void addCandidate(String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty || candidates.contains(trimmed)) {
        return;
      }
      candidates.add(trimmed);
    }

    addCandidate(advertisedHostAddress);
    addCandidate(_advertisedHostAddress);

    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (_looksLikeLanAddress(address.address)) {
          addCandidate(address.address);
        }
      }
    }

    addCandidate(InternetAddress.loopbackIPv4.address);
    return candidates;
  }

  bool _looksLikeLanAddress(String address) {
    return address.startsWith('192.168.') ||
        address.startsWith('10.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(address);
  }

  String _generateToken({required int length}) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var index = 0; index < length; index++) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }
}
