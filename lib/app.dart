import 'package:flutter/material.dart';

import 'core/accessibility/a11y_controller.dart';
import 'features/calibration/calibration_screen.dart';
import 'features/game/game_screen.dart';
import 'features/home/home_screen.dart';
import 'features/multiplayer/host_lobby_screen.dart';
import 'features/multiplayer/join_session_screen.dart';
import 'features/multiplayer/multiplayer_session_controller.dart';
import 'features/multiplayer/multiplayer_setup_screen.dart';
import 'features/results/result_screen.dart';
import 'features/safety/safety_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/settings/settings_screen.dart';
import 'theme/mario_theme.dart';

/// Route names — keep in sync with [PhonePongApp.routes].
class Routes {
  const Routes._();
  static const String home = '/';
  static const String safety = '/safety';
  static const String multiplayerSetup = '/multiplayer-setup';
  static const String hostLobby = '/multiplayer-host';
  static const String joinSession = '/multiplayer-join';
  static const String scan = '/scan';
  static const String calibration = '/calibration';
  static const String game = '/game';
  static const String result = '/result';
  static const String settings = '/settings';
}

typedef SessionControllerFactory = MultiplayerSessionController Function();

class PhonePongApp extends StatefulWidget {
  const PhonePongApp({
    super.key,
    SessionControllerFactory? createSessionController,
  }) : createSessionController =
            createSessionController ?? _defaultSessionControllerFactory;

  final SessionControllerFactory createSessionController;

  static MultiplayerSessionController _defaultSessionControllerFactory() {
    return MultiplayerSessionController();
  }

  @override
  State<PhonePongApp> createState() => _PhonePongAppState();
}

class _PhonePongAppState extends State<PhonePongApp> {
  late final A11yController _a11y;

  @override
  void initState() {
    super.initState();
    _a11y = A11yController();
  }

  @override
  void dispose() {
    _a11y.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a11y,
      builder: (context, _) {
        return MaterialApp(
          title: 'PongPong',
          debugShowCheckedModeBanner: false,
          theme: MarioTheme.build(highContrast: _a11y.highContrast),
          initialRoute: Routes.home,
          onGenerateRoute: (settings) => _route(settings),
        );
      },
    );
  }

  Route<dynamic> _route(RouteSettings settings) {
    Widget builder() {
      switch (settings.name) {
        case Routes.home:
          return HomeScreen(a11y: _a11y);
        case Routes.safety:
          return SafetyScreen(a11y: _a11y);
        case Routes.multiplayerSetup:
          return MultiplayerSetupScreen(
            a11y: _a11y,
            createSessionController: widget.createSessionController,
          );
        case Routes.hostLobby:
          return HostLobbyScreen(
            a11y: _a11y,
            sessionController:
                settings.arguments as MultiplayerSessionController,
          );
        case Routes.joinSession:
          return JoinSessionScreen(
            a11y: _a11y,
            sessionController:
                settings.arguments as MultiplayerSessionController,
          );
        case Routes.scan:
          final sessionController =
              settings.arguments is MultiplayerSessionController
                  ? settings.arguments as MultiplayerSessionController
                  : null;
          return Builder(
            builder: (context) => ScanScreen(
              multiplayerSession: sessionController,
              onScanComplete: (_) => Navigator.pushReplacementNamed(
                context,
                Routes.calibration,
                arguments: sessionController,
              ),
            ),
          );
        case Routes.calibration:
          final sessionController =
              settings.arguments is MultiplayerSessionController
                  ? settings.arguments as MultiplayerSessionController
                  : null;
          return CalibrationScreen(
            a11y: _a11y,
            sessionController: sessionController,
          );
        case Routes.game:
          final sessionController =
              settings.arguments is MultiplayerSessionController
                  ? settings.arguments as MultiplayerSessionController
                  : null;
          return GameScreen(a11y: _a11y, sessionController: sessionController);
        case Routes.result:
          final args = settings.arguments as ResultArgs?;
          return ResultScreen(
            a11y: _a11y,
            args: args ?? const ResultArgs.empty(),
          );
        case Routes.settings:
          return SettingsScreen(a11y: _a11y);
        default:
          return HomeScreen(a11y: _a11y);
      }
    }

    return PageRouteBuilder(
      settings: settings,
      transitionDuration: MarioMotion.page,
      reverseTransitionDuration: MarioMotion.page,
      pageBuilder: (_, __, ___) => builder(),
      transitionsBuilder: (_, anim, __, child) {
        // Sharp arcade: linear curve, no easing, fast cut.
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.linear),
          child: child,
        );
      },
    );
  }
}
