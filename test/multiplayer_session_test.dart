import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pongpong/features/multiplayer/multiplayer_models.dart';
import 'package:pongpong/features/multiplayer/multiplayer_session_controller.dart';

void main() {
  test('pairing payload round-trips through QR data', () {
    const payload = PairingPayload(
      roomId: 'ROOM42',
      hostAddress: '192.168.1.2',
      port: 4242,
      token: 'TOKEN123456',
      hostAddresses: <String>['192.168.1.2', '10.0.0.5'],
    );

    final decoded = PairingPayload.parse(payload.encode());

    expect(decoded.roomId, payload.roomId);
    expect(decoded.hostAddress, payload.hostAddress);
    expect(decoded.port, payload.port);
    expect(decoded.token, payload.token);
    expect(decoded.connectionAddresses, payload.connectionAddresses);
  });

  test('invalid QR payload throws format exception', () {
    expect(
      () => PairingPayload.parse('not-json'),
      throwsA(isA<FormatException>()),
    );
  });

  test('websocket handshake establishes host and join roles', () async {
    final host = MultiplayerSessionController(
      defaultBindAddress: InternetAddress.loopbackIPv4,
      advertisedHostAddress: InternetAddress.loopbackIPv4.address,
    );
    final joiner = MultiplayerSessionController();

    await host.hostSession();
    await joiner.joinSession(host.payload!);
    await _waitUntil(() => host.state.isConnected && joiner.state.isConnected);

    expect(host.state.role, SessionRole.host);
    expect(joiner.state.role, SessionRole.joiner);
    expect(host.state.peerConnected, isTrue);
    expect(joiner.state.peerConnected, isTrue);

    await host.closeSession(reason: 'Test complete.');
  });

  test('host scan updates propagate and joiner cannot mutate shared state',
      () async {
    final host = MultiplayerSessionController(
      defaultBindAddress: InternetAddress.loopbackIPv4,
      advertisedHostAddress: InternetAddress.loopbackIPv4.address,
    );
    final joiner = MultiplayerSessionController();

    await host.hostSession();
    await joiner.joinSession(host.payload!);
    await _waitUntil(() => host.state.isConnected && joiner.state.isConnected);

    host.captureCurrentStep();
    host.setWidth(2.8);
    host.captureCurrentStep();
    host.setLength(4.0);
    host.captureCurrentStep();

    await _waitUntil(
      () =>
          joiner.state.sharedScanState.area.leftBoundaryCaptured &&
          joiner.state.sharedScanState.area.rightBoundaryCaptured &&
          joiner.state.sharedScanState.area.lengthMeters == 4.0 &&
          joiner.state.sharedScanState.area.widthMeters == 2.8 &&
          joiner.state.sharedScanState.step == host.state.sharedScanState.step,
    );

    final mirroredWidth = joiner.state.sharedScanState.area.widthMeters;
    joiner.setWidth(1.8);
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(host.state.sharedScanState.area.widthMeters, 2.8);
    expect(joiner.state.sharedScanState.area.widthMeters, mirroredWidth);

    await host.closeSession(reason: 'Test complete.');
  });

  test('host confirmation advances both phones toward calibration', () async {
    final host = MultiplayerSessionController(
      defaultBindAddress: InternetAddress.loopbackIPv4,
      advertisedHostAddress: InternetAddress.loopbackIPv4.address,
    );
    final joiner = MultiplayerSessionController();

    await host.hostSession();
    await joiner.joinSession(host.payload!);
    await _waitUntil(() => host.state.isConnected && joiner.state.isConnected);

    host.confirmSharedScan();
    await _waitUntil(
      () =>
          host.state.sharedScanState.confirmed &&
          joiner.state.sharedScanState.confirmed,
    );

    expect(host.state.sharedScanState.confirmed, isTrue);
    expect(joiner.state.sharedScanState.confirmed, isTrue);

    await host.closeSession(reason: 'Test complete.');
  });

  test('join reports an error when the host is unavailable', () async {
    final joiner = MultiplayerSessionController();

    await joiner.joinSession(
      const PairingPayload(
        roomId: 'ROOM42',
        hostAddress: '127.0.0.1',
        port: 6553,
        token: 'TOKEN123456',
        hostAddresses: <String>['127.0.0.1', '192.168.1.50'],
      ),
    );

    await _waitUntil(
      () => joiner.state.connectionStatus == MultiplayerConnectionStatus.error,
    );

    expect(joiner.state.errorMessage, contains('Unable to join'));
  });

  test('join falls back to the next advertised LAN address', () async {
    final host = MultiplayerSessionController(
      defaultBindAddress: InternetAddress.loopbackIPv4,
      advertisedHostAddress: InternetAddress.loopbackIPv4.address,
    );
    final joiner = MultiplayerSessionController();

    await host.hostSession();
    await joiner.joinSession(
      PairingPayload(
        roomId: host.payload!.roomId,
        hostAddress: '192.168.10.250',
        port: host.payload!.port,
        token: host.payload!.token,
        hostAddresses: <String>[
          '192.168.10.250',
          InternetAddress.loopbackIPv4.address,
        ],
      ),
    );

    await _waitUntil(() => host.state.isConnected && joiner.state.isConnected);

    expect(joiner.state.isConnected, isTrue);

    await host.closeSession(reason: 'Test complete.');
  });

  test('disconnect during scan notifies the joiner', () async {
    final host = MultiplayerSessionController(
      defaultBindAddress: InternetAddress.loopbackIPv4,
      advertisedHostAddress: InternetAddress.loopbackIPv4.address,
    );
    final joiner = MultiplayerSessionController();

    await host.hostSession();
    await joiner.joinSession(host.payload!);
    await _waitUntil(() => host.state.isConnected && joiner.state.isConnected);

    await host.closeSession(reason: 'Host cancelled the session.');
    await _waitUntil(
      () =>
          joiner.state.connectionStatus ==
          MultiplayerConnectionStatus.disconnected,
    );

    expect(joiner.state.disconnectReason, 'Host cancelled the session.');
  });
}

Future<void> _waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (predicate()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  fail('Condition was not met before timeout.');
}
