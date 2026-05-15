enum BallState { far, near, ready, hit, smash, missed }

enum GameStatus { ready, playing, hit, smash, missed, gameOver }

enum BallLane { left, right, center }

class GameResult {
  const GameResult({
    required this.score,
    required this.hits,
    required this.smashes,
    required this.longestRally,
    required this.durationSeconds,
    required this.accuracy,
    required this.peakBallSpeed,
  });

  final int score;
  final int hits;
  final int smashes;
  final int longestRally;
  final int durationSeconds;
  final double accuracy;
  final double peakBallSpeed;

  factory GameResult.empty() {
    return const GameResult(
      score: 0,
      hits: 0,
      smashes: 0,
      longestRally: 0,
      durationSeconds: 0,
      accuracy: 0,
      peakBallSpeed: 1,
    );
  }
}
