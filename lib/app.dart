import 'package:flutter/material.dart';

import 'core/accessibility/a11y_controller.dart';
import 'features/calibration/calibration_screen.dart';
import 'features/game/game_screen.dart';
import 'features/home/home_screen.dart';
import 'features/results/result_screen.dart';
import 'features/safety/safety_screen.dart';
import 'features/scan/scanned_area_model.dart';
import 'features/scan/spatial_scan_screen.dart';
import 'features/settings/settings_screen.dart';
import 'theme/mario_theme.dart';

/// Route names — keep in sync with [PhonePongApp.routes].
class Routes {
  const Routes._();
  static const String home = '/';
  static const String safety = '/safety';
  static const String scan = '/scan';
  static const String calibration = '/calibration';
  static const String game = '/game';
  static const String result = '/result';
  static const String settings = '/settings';
}

class PhonePongApp extends StatefulWidget {
  const PhonePongApp({super.key});

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
          title: 'PhonePong',
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
        case Routes.scan:
          return SpatialScanScreen(a11y: _a11y);
        case Routes.calibration:
          final args = settings.arguments as ScannedAreaModel?;
          return CalibrationScreen(a11y: _a11y, playArea: args);
        case Routes.game:
          return GameScreen(a11y: _a11y);
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
