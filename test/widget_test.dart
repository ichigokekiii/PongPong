import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pongpong/app.dart';
import 'package:pongpong/features/multiplayer/multiplayer_models.dart';
import 'package:pongpong/features/multiplayer/multiplayer_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('start flow reaches multiplayer setup instead of scan', (
    WidgetTester tester,
  ) async {
    _setLargeTestSurface(tester);
    await tester.pumpWidget(const PhonePongApp());

    await tester.ensureVisible(find.text('START GAME'));
    expect(find.text('START GAME'), findsOneWidget);

    await tester.tap(find.text('START GAME'));
    await tester.pumpAndSettle();

    expect(find.text('SAFETY CHECK'), findsWidgets);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'M READY"));
    await tester.pumpAndSettle();

    expect(find.text('MULTIPLAYER SETUP'), findsWidgets);
    expect(find.text('HOST GAME'), findsOneWidget);
    expect(find.text('JOIN GAME'), findsOneWidget);
    expect(find.text('Shared Spatial Creation'), findsNothing);
  });

  testWidgets('host path shows QR and waits until joiner connects', (
    WidgetTester tester,
  ) async {
    _setLargeTestSurface(tester);
    late FakeSessionController hostController;

    await tester.pumpWidget(
      PhonePongApp(
        createSessionController: () {
          hostController = FakeSessionController.host();
          return hostController;
        },
      ),
    );

    await tester.ensureVisible(find.text('START GAME'));
    await tester.tap(find.text('START GAME'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'M READY"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HOST GAME'));
    await tester.pumpAndSettle();

    expect(find.text('HOST GAME'), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('Shared Spatial Creation'), findsNothing);

    hostController.simulatePeerConnected();
    await tester.pumpAndSettle();

    expect(find.text('Shared Spatial Creation'), findsWidgets);
  });

  testWidgets('join path accepts payload and reaches mirrored shared scan', (
    WidgetTester tester,
  ) async {
    _setLargeTestSurface(tester);
    late FakeSessionController joinController;

    await tester.pumpWidget(
      PhonePongApp(
        createSessionController: () {
          joinController = FakeSessionController.joiner();
          return joinController;
        },
      ),
    );

    await tester.ensureVisible(find.text('START GAME'));
    await tester.tap(find.text('START GAME'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'M READY"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JOIN GAME'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      FakeSessionController.testPayload.encode(),
    );
    await tester.tap(find.text('JOIN WITH PAYLOAD'));
    await tester.pump();

    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(find.text('Shared Spatial Creation'), findsWidgets);
    expect(find.text('Joiner mirrors scan'), findsOneWidget);
  });
}

void _setLargeTestSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class FakeSessionController extends MultiplayerSessionController {
  FakeSessionController._(this._fakeState);

  factory FakeSessionController.host() => FakeSessionController._(
        MultiplayerSessionState.initial.copyWith(
          role: SessionRole.host,
          connectionStatus: MultiplayerConnectionStatus.idle,
        ),
      );

  factory FakeSessionController.joiner() => FakeSessionController._(
        MultiplayerSessionState.initial.copyWith(
          role: SessionRole.joiner,
          connectionStatus: MultiplayerConnectionStatus.idle,
        ),
      );

  static const testPayload = PairingPayload(
    roomId: 'ROOM42',
    hostAddress: '127.0.0.1',
    port: 4242,
    token: 'TOKEN123456',
  );

  MultiplayerSessionState _fakeState;

  @override
  MultiplayerSessionState get state => _fakeState;

  @override
  PairingPayload? get payload => _fakeState.payload;

  @override
  Future<void> hostSession({
    InternetAddress? bindAddress,
    String? advertisedHostAddress,
  }) async {
    _emit(
      _fakeState.copyWith(
        role: SessionRole.host,
        connectionStatus: MultiplayerConnectionStatus.waitingForJoiner,
        payload: testPayload,
        peerConnected: false,
      ),
    );
  }

  @override
  Future<void> joinSession(PairingPayload payload) async {
    _emit(
      _fakeState.copyWith(
        role: SessionRole.joiner,
        connectionStatus: MultiplayerConnectionStatus.connected,
        payload: payload,
        peerConnected: true,
      ),
    );
  }

  @override
  Future<void> closeSession({String reason = 'Session closed'}) async {
    _emit(
      _fakeState.copyWith(
        connectionStatus: MultiplayerConnectionStatus.disconnected,
        disconnectReason: reason,
        peerConnected: false,
      ),
    );
  }

  void simulatePeerConnected() {
    _emit(
      _fakeState.copyWith(
        connectionStatus: MultiplayerConnectionStatus.connected,
        peerConnected: true,
      ),
    );
  }

  void _emit(MultiplayerSessionState nextState) {
    _fakeState = nextState;
    notifyListeners();
  }
}
