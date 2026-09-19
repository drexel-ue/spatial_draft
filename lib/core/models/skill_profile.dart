import 'dart:math' as math;

class AngleSectorStats {
  final int sectorIndex; // 0 to 15 (each sector is 22.5 degrees)
  final double centerAngleDegrees;
  int sampleCount;
  double totalAccuracy;
  double totalJitter;

  AngleSectorStats({
    required this.sectorIndex,
  })  : centerAngleDegrees = sectorIndex * 22.5,
        sampleCount = 0,
        totalAccuracy = 0.0,
        totalJitter = 0.0;

  double get averageAccuracy => sampleCount > 0 ? totalAccuracy / sampleCount : 0.75;
  double get averageJitter => sampleCount > 0 ? totalJitter / sampleCount : 0.20;

  void addSample({required double accuracy, required double jitter}) {
    sampleCount++;
    totalAccuracy += accuracy;
    totalJitter += jitter;
  }
}

class SkillProfile {
  // 16 radial angle sectors (0 to 360 degrees)
  final List<AngleSectorStats> angleSectors;

  // Running cumulative metrics
  int totalStrokesCompleted;
  int totalDrillsCompleted;

  double overallAccuracy;
  double overallVelocityConsistency;
  double averageJitter;

  double ellipseAccuracy;
  double isometricAccuracy;
  double formGestureAccuracy;

  SkillProfile({
    List<AngleSectorStats>? angleSectors,
    this.totalStrokesCompleted = 0,
    this.totalDrillsCompleted = 0,
    this.overallAccuracy = 0.80,
    this.overallVelocityConsistency = 0.82,
    this.averageJitter = 0.15,
    this.ellipseAccuracy = 0.75,
    this.isometricAccuracy = 0.78,
    this.formGestureAccuracy = 0.76,
  }) : angleSectors = angleSectors ??
            List.generate(16, (i) => AngleSectorStats(sectorIndex: i));

  /// Find the angle sector with the lowest performance or fewest samples
  double getAdaptiveTargetAngle() {
    // Sort sectors by accuracy weighted by confidence
    AngleSectorStats? weakest;
    double lowestScore = 999.0;

    for (final sector in angleSectors) {
      // Prioritize sectors with low sample count or low accuracy
      final explorationBonus = sector.sampleCount == 0 ? -0.2 : 0.0;
      final score = sector.averageAccuracy + explorationBonus;
      if (score < lowestScore) {
        lowestScore = score;
        weakest = sector;
      }
    }

    // Add slight jitter (+/- 8 degrees) around the center of the sector for natural variety
    final random = math.Random();
    final center = weakest?.centerAngleDegrees ?? 45.0;
    final jitterOffset = (random.nextDouble() - 0.5) * 16.0;
    return (center + jitterOffset) % 360.0;
  }

  void recordGhostingAnalysis({
    required double angleRadians,
    required double accuracy,
    required double jitter,
    required double velocityConsistency,
  }) {
    totalStrokesCompleted++;
    totalDrillsCompleted++;

    // Normalize angle to 0..2*pi
    var normAngle = angleRadians % (2 * math.pi);
    if (normAngle < 0) normAngle += 2 * math.pi;

    final degrees = normAngle * (180.0 / math.pi);
    final sectorIdx = ((degrees / 22.5).round()) % 16;
    angleSectors[sectorIdx].addSample(accuracy: accuracy, jitter: jitter);

    // Exponential moving average for overall metrics
    const alpha = 0.2;
    overallAccuracy = (1 - alpha) * overallAccuracy + alpha * accuracy;
    overallVelocityConsistency = (1 - alpha) * overallVelocityConsistency + alpha * velocityConsistency;
    averageJitter = (1 - alpha) * averageJitter + alpha * jitter;
  }

  void recordEllipseAnalysis({
    required double accuracy,
    required double minorAxisErrorDeg,
    required double eccentricity,
  }) {
    totalDrillsCompleted++;
    const alpha = 0.25;
    ellipseAccuracy = (1 - alpha) * ellipseAccuracy + alpha * accuracy;
  }

  void recordIsometricAnalysis({
    required double accuracy,
    required double lineWeightFidelity,
  }) {
    totalDrillsCompleted++;
    const alpha = 0.25;
    final combined = (accuracy * 0.7) + (lineWeightFidelity * 0.3);
    isometricAccuracy = (1 - alpha) * isometricAccuracy + alpha * combined;
  }

  void recordFormAnalysis({
    required double accuracy,
  }) {
    totalDrillsCompleted++;
    const alpha = 0.25;
    formGestureAccuracy = (1 - alpha) * formGestureAccuracy + alpha * accuracy;
  }
}
