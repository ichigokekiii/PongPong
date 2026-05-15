import 'package:flutter/material.dart';

import '../features/calibration/calibration_screen.dart';
import '../features/calibration/swing_profile_model.dart';
import '../features/game/game_models.dart';
import '../features/game/game_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/safety_screen.dart';
import '../features/results/result_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/scan/scanned_area_model.dart';

class AppRoutes {
  static const home = '/';
  static const safety = '/safety';
  static const scan = '/scan';
  static const calibration = '/calibration';
  static const game = '/game';
  static const results = '/results';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case safety:
        return MaterialPageRoute<void>(
          builder: (_) => const SafetyScreen(),
          settings: settings,
        );
      case scan:
        return MaterialPageRoute<void>(
          builder: (_) => const ScanScreen(),
          settings: settings,
        );
      case calibration:
        final playArea = settings.arguments is ScannedArea
            ? settings.arguments! as ScannedArea
            : ScannedArea.demo();
        return MaterialPageRoute<void>(
          builder: (_) => CalibrationScreen(playArea: playArea),
          settings: settings,
        );
      case game:
        final args = settings.arguments is GameScreenArgs
            ? settings.arguments! as GameScreenArgs
            : GameScreenArgs(
                playArea: ScannedArea.demo(),
                swingProfile: SwingProfile.demo(),
              );
        return MaterialPageRoute<void>(
          builder: (_) => GameScreen(args: args),
          settings: settings,
        );
      case results:
        final args = settings.arguments is ResultScreenArgs
            ? settings.arguments! as ResultScreenArgs
            : ResultScreenArgs(
                result: GameResult.empty(),
                playArea: ScannedArea.demo(),
                swingProfile: SwingProfile.demo(),
              );
        return MaterialPageRoute<void>(
          builder: (_) => ResultScreen(args: args),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const _MissingRouteScreen(),
          settings: settings,
        );
    }
  }
}

class _MissingRouteScreen extends StatelessWidget {
  const _MissingRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Unknown route',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
