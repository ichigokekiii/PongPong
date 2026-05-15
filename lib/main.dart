import 'package:flutter/material.dart';
import 'package:pongpong/features/scan/scan_screen.dart';

void main() {
  runApp(const PongPongApp());
}

class PongPongApp extends StatelessWidget {
  const PongPongApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF0C7C59);

    return MaterialApp(
      title: 'PongPong',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F1),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.home,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.home:
            return MaterialPageRoute<void>(
              builder: (_) => const HomeScreen(),
              settings: settings,
            );
          case AppRoutes.safety:
            return MaterialPageRoute<void>(
              builder: (_) => const SafetyScreen(),
              settings: settings,
            );
          case AppRoutes.scan:
            return MaterialPageRoute<void>(
              builder: (context) => ScanScreen(
                onScanComplete: (scannedArea) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.calibration,
                    arguments: PlayArea(
                      widthMeters: scannedArea.widthMeters,
                      lengthMeters: scannedArea.lengthMeters,
                    ),
                  );
                },
              ),
              settings: settings,
            );
          case AppRoutes.calibration:
            return MaterialPageRoute<void>(
              builder: (_) =>
                  CalibrationScreen(playArea: settings.arguments as PlayArea?),
              settings: settings,
            );
          case AppRoutes.game:
            return MaterialPageRoute<void>(
              builder: (_) =>
                  GameScreen(setup: settings.arguments as GameSetup?),
              settings: settings,
            );
          case AppRoutes.results:
            return MaterialPageRoute<void>(
              builder: (_) =>
                  ResultsScreen(result: settings.arguments as GameResult?),
              settings: settings,
            );
          default:
            return MaterialPageRoute<void>(
              builder: (_) => const HomeScreen(),
              settings: settings,
            );
        }
      },
    );
  }
}

abstract final class AppRoutes {
  static const home = '/';
  static const safety = '/safety';
  static const scan = '/scan';
  static const calibration = '/calibration';
  static const game = '/game';
  static const results = '/results';
}

enum Handedness { left, right }

enum BallState { far, near, ready, hit, smash, missed }

class PlayArea {
  const PlayArea({required this.widthMeters, required this.lengthMeters});

  final double widthMeters;
  final double lengthMeters;
}

class CalibrationProfile {
  const CalibrationProfile({
    required this.handedness,
    required this.normalSwingThreshold,
    required this.smashThreshold,
  });

  final Handedness handedness;
  final double normalSwingThreshold;
  final double smashThreshold;
}

class GameSetup {
  const GameSetup({required this.playArea, required this.calibration});

  final PlayArea playArea;
  final CalibrationProfile calibration;
}

class GameResult {
  const GameResult({
    required this.score,
    required this.hits,
    required this.smashes,
    required this.longestRally,
    required this.accuracy,
  });

  final int score;
  final int hits;
  final int smashes;
  final int longestRally;
  final double accuracy;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'PongPong MVP',
      subtitle: 'Phone-as-paddle table tennis for quick hackathon iteration.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HighlightPanel(
            title: 'Core flow',
            body:
                'Scan a play area, calibrate a swing, then follow screen, sound, and haptic cues to rally an invisible ball.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.safety),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Game'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showHowToPlay(context),
            icon: const Icon(Icons.sports_tennis_rounded),
            label: const Text('How To Play'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.calibration),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Calibration'),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return const Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How it works',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text('1. Scan a clear space around you.'),
              SizedBox(height: 8),
              Text('2. Hold your phone like a paddle.'),
              SizedBox(height: 8),
              Text('3. Watch the screen color and edge cues.'),
              SizedBox(height: 8),
              Text('4. Swing when the center indicator turns green.'),
            ],
          ),
        );
      },
    );
  }
}

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Safety Check',
      subtitle: 'Make space before swinging the phone.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HighlightPanel(
            title: 'Before you play',
            body:
                'Clear the area around you. Avoid people, pets, glass, and fragile objects. Hold the phone firmly with a wrist-safe grip.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.scan),
            child: const Text('I Have Space'),
          ),
        ],
      ),
    );
  }
}

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key, this.playArea});

  final PlayArea? playArea;

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  Handedness _handedness = Handedness.right;
  double _normalThreshold = 0.8;
  double _smashThreshold = 1.6;

  @override
  Widget build(BuildContext context) {
    final playArea =
        widget.playArea ?? const PlayArea(widthMeters: 2.5, lengthMeters: 3.0);

    return AppShell(
      title: 'Calibration',
      subtitle: 'Save a quick swing profile for early testing.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HighlightPanel(
            title: 'Detected play area',
            body:
                '${playArea.widthMeters.toStringAsFixed(1)} m wide by ${playArea.lengthMeters.toStringAsFixed(1)} m long.',
          ),
          const SizedBox(height: 24),
          SegmentedButton<Handedness>(
            segments: const [
              ButtonSegment<Handedness>(
                value: Handedness.left,
                label: Text('Left-handed'),
                icon: Icon(Icons.pan_tool_alt_rounded),
              ),
              ButtonSegment<Handedness>(
                value: Handedness.right,
                label: Text('Right-handed'),
                icon: Icon(Icons.sports_handball_rounded),
              ),
            ],
            selected: <Handedness>{_handedness},
            onSelectionChanged: (selection) {
              setState(() => _handedness = selection.first);
            },
          ),
          const SizedBox(height: 16),
          MetricCard(
            label: 'Normal swing threshold',
            value: _normalThreshold.toStringAsFixed(2),
            child: Slider(
              value: _normalThreshold,
              min: 0.5,
              max: 1.4,
              divisions: 18,
              onChanged: (value) {
                setState(() {
                  _normalThreshold = value;
                  if (_smashThreshold <= _normalThreshold) {
                    _smashThreshold = _normalThreshold + 0.1;
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          MetricCard(
            label: 'Smash threshold',
            value: _smashThreshold.toStringAsFixed(2),
            child: Slider(
              value: _smashThreshold,
              min: (_normalThreshold + 0.1).clamp(0.6, 2.4),
              max: 2.5,
              divisions: 20,
              onChanged: (value) => setState(() => _smashThreshold = value),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.game,
                arguments: GameSetup(
                  playArea: playArea,
                  calibration: CalibrationProfile(
                    handedness: _handedness,
                    normalSwingThreshold: _normalThreshold,
                    smashThreshold: _smashThreshold,
                  ),
                ),
              );
            },
            child: const Text('Save Calibration'),
          ),
        ],
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.setup});

  final GameSetup? setup;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  BallState _ballState = BallState.far;
  int _score = 0;
  int _rally = 0;
  int _hits = 0;
  int _smashes = 0;
  int _attempts = 0;
  int _longestRally = 0;

  @override
  Widget build(BuildContext context) {
    final setup =
        widget.setup ??
        GameSetup(
          playArea: const PlayArea(widthMeters: 2.5, lengthMeters: 3.0),
          calibration: const CalibrationProfile(
            handedness: Handedness.right,
            normalSwingThreshold: 0.8,
            smashThreshold: 1.6,
          ),
        );
    final indicator = _indicatorFor(_ballState);

    return Scaffold(
      backgroundColor: indicator.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Game'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  StatChip(label: 'Score', value: '$_score'),
                  StatChip(label: 'Rally', value: '$_rally'),
                  StatChip(label: 'Smashes', value: '$_smashes'),
                  StatChip(
                    label: 'Accuracy',
                    value: '${_accuracy.toStringAsFixed(0)}%',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              IndicatorPanel(indicator: indicator),
              const SizedBox(height: 24),
              HighlightPanel(
                title: 'Current setup',
                body:
                    '${setup.playArea.widthMeters.toStringAsFixed(1)} m x ${setup.playArea.lengthMeters.toStringAsFixed(1)} m, ${setup.calibration.handedness.name}-handed, normal ${setup.calibration.normalSwingThreshold.toStringAsFixed(2)}, smash ${setup.calibration.smashThreshold.toStringAsFixed(2)}.',
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _advanceBall,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Advance Ball'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _registerHit,
                    icon: const Icon(Icons.sports_tennis_rounded),
                    label: const Text('Hit'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _registerSmash,
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text('Smash'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _registerMiss,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Miss'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resetSession,
                child: const Text('Reset Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get _accuracy => _attempts == 0 ? 0 : (_hits / _attempts) * 100;

  void _advanceBall() {
    setState(() {
      switch (_ballState) {
        case BallState.far:
        case BallState.hit:
        case BallState.smash:
          _ballState = BallState.near;
        case BallState.near:
          _ballState = BallState.ready;
        case BallState.ready:
        case BallState.missed:
          _ballState = BallState.far;
      }
    });
  }

  void _registerHit() {
    if (_ballState != BallState.ready) {
      return;
    }

    setState(() {
      _attempts++;
      _hits++;
      _score += 1;
      _rally++;
      _longestRally = _rally > _longestRally ? _rally : _longestRally;
      _ballState = BallState.hit;
    });
  }

  void _registerSmash() {
    if (_ballState != BallState.ready) {
      return;
    }

    setState(() {
      _attempts++;
      _hits++;
      _smashes++;
      _score += 3;
      _rally++;
      _longestRally = _rally > _longestRally ? _rally : _longestRally;
      _ballState = BallState.smash;
    });
  }

  void _registerMiss() {
    setState(() {
      _attempts++;
      _ballState = BallState.missed;
    });

    Navigator.pushNamed(
      context,
      AppRoutes.results,
      arguments: GameResult(
        score: _score,
        hits: _hits,
        smashes: _smashes,
        longestRally: _longestRally,
        accuracy: _accuracy,
      ),
    );
  }

  void _resetSession() {
    setState(() {
      _ballState = BallState.far;
      _score = 0;
      _rally = 0;
      _hits = 0;
      _smashes = 0;
      _attempts = 0;
      _longestRally = 0;
    });
  }
}

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, this.result});

  final GameResult? result;

  @override
  Widget build(BuildContext context) {
    final result =
        this.result ??
        const GameResult(
          score: 0,
          hits: 0,
          smashes: 0,
          longestRally: 0,
          accuracy: 0,
        );

    return AppShell(
      title: 'Results',
      subtitle: 'A clean summary for quick iteration after each rally.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StatChip(label: 'Final Score', value: '${result.score}'),
              StatChip(label: 'Hits', value: '${result.hits}'),
              StatChip(label: 'Smashes', value: '${result.smashes}'),
              StatChip(
                label: 'Accuracy',
                value: '${result.accuracy.toStringAsFixed(0)}%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          HighlightPanel(
            title: 'Longest rally',
            body: '${result.longestRally} successful returns in a row.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            ),
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class HighlightPanel extends StatelessWidget {
  const HighlightPanel({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.child,
  });

  final String label;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(value),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class BallIndicator {
  const BallIndicator({
    required this.label,
    required this.edgeCue,
    required this.guidance,
    required this.background,
  });

  final String label;
  final String edgeCue;
  final String guidance;
  final Color background;
}

class IndicatorPanel extends StatelessWidget {
  const IndicatorPanel({super.key, required this.indicator});

  final BallIndicator indicator;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            indicator.label,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(indicator.edgeCue),
          const SizedBox(height: 16),
          Text(
            indicator.guidance,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

BallIndicator _indicatorFor(BallState state) {
  switch (state) {
    case BallState.far:
      return const BallIndicator(
        label: 'Far / Red',
        edgeCue: 'Top edge blinking. Ball is still far away.',
        guidance: 'Prepare and wait.',
        background: Color(0xFFF6D4D2),
      );
    case BallState.near:
      return const BallIndicator(
        label: 'Near / Yellow',
        edgeCue: 'Left or right edge blinking. Ball is approaching.',
        guidance: 'Get ready to swing.',
        background: Color(0xFFF6E8AE),
      );
    case BallState.ready:
      return const BallIndicator(
        label: 'Ready / Green',
        edgeCue: 'Center pulse. Ball is in the hit zone.',
        guidance: 'Swing now.',
        background: Color(0xFFD6EFC7),
      );
    case BallState.hit:
      return const BallIndicator(
        label: 'Clean Hit',
        edgeCue: 'Return cue is active. Rally continues.',
        guidance: 'Advance the ball to the next return.',
        background: Color(0xFFD8F4E5),
      );
    case BallState.smash:
      return const BallIndicator(
        label: 'Smash',
        edgeCue: 'Very fast blink. Next return should feel faster.',
        guidance: 'Prepare for a faster ball.',
        background: Color(0xFFFFD39A),
      );
    case BallState.missed:
      return const BallIndicator(
        label: 'Missed',
        edgeCue: 'Cue dropped. Rally over.',
        guidance: 'Review the result and restart.',
        background: Color(0xFFE6E7EB),
      );
  }
}
