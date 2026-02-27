import '../../config/rank_config.dart';
import '../../utils/formatters.dart';

/// Result of rank progress for a given revenue.
class RankResult {
  const RankResult({
    required this.rank,
    required this.nextRank,
    required this.current,
    required this.nextThreshold,
    required this.progress0to1,
    required this.progressPercent,
    required this.remainingToNext,
  });

  /// Current rank (e.g. 'B').
  final String rank;

  /// Next rank in ladder; same as [rank] when at top (SSS).
  final String nextRank;

  /// Current rank's threshold (revenue floor for this rank).
  final double current;

  /// Next rank's threshold; same as [current] when at top.
  final double nextThreshold;

  /// Progress toward next rank in [0, 1].
  final double progress0to1;

  /// Progress as integer 0–100.
  final int progressPercent;

  /// Revenue still needed to reach next rank; 0 when at top.
  final double remainingToNext;

  /// Formatting-friendly: current threshold as currency string.
  String get currentFormatted => formatCurrency(current);

  /// Formatting-friendly: next threshold as currency string.
  String get nextThresholdFormatted => formatCurrency(nextThreshold);

  /// Formatting-friendly: remaining to next rank as currency string.
  String get remainingFormatted => formatCurrency(remainingToNext);

  @override
  String toString() =>
      'RankResult($rank → $nextRank, $progressPercent%, remaining: $remainingFormatted)';
}

/// Computes hunter rank and progress from monthly revenue.
class RankEngine {
  RankEngine._();

  static const _ladder = RankConfig.rankLadder;

  /// Returns the rank label for [revenue] (highest rank whose threshold <= revenue).
  static String getRankForRevenue(double revenue) {
    if (revenue.isNaN || revenue.isNegative) return _ladder.first.$1;
    String out = _ladder.first.$1;
    for (final e in _ladder) {
      if (revenue >= e.$2) out = e.$1;
    }
    return out;
  }

  /// Full progress toward next rank. At top rank (SSS), [nextRank] == [rank], [progress0to1] == 1, [remainingToNext] == 0.
  static RankResult getRankProgress(double revenue) {
    if (revenue.isNaN || revenue < 0) {
      return _progressAt(0, 0);
    }
    final rev = revenue.toDouble();

    int currentIndex = 0;
    for (int i = 0; i < _ladder.length; i++) {
      if (rev >= _ladder[i].$2) currentIndex = i;
    }

    final currentThreshold = _ladder[currentIndex].$2.toDouble();
    final isTopRank = currentIndex == _ladder.length - 1;
    final nextIndex = isTopRank ? currentIndex : currentIndex + 1;
    final nextThreshold = _ladder[nextIndex].$2.toDouble();

    final rank = _ladder[currentIndex].$1;
    final nextRank = _ladder[nextIndex].$1;

    double progress0to1;
    double remainingToNext;
    if (isTopRank || nextThreshold == currentThreshold) {
      progress0to1 = 1.0;
      remainingToNext = 0.0;
    } else {
      progress0to1 =
          ((rev - currentThreshold) / (nextThreshold - currentThreshold))
              .clamp(0.0, 1.0);
      remainingToNext = (nextThreshold - rev).clamp(0.0, double.infinity);
    }
    final progressPercent = (progress0to1 * 100).round().clamp(0, 100);

    return RankResult(
      rank: rank,
      nextRank: nextRank,
      current: currentThreshold,
      nextThreshold: nextThreshold,
      progress0to1: progress0to1,
      progressPercent: progressPercent,
      remainingToNext: remainingToNext,
    );
  }

  static RankResult _progressAt(int currentIndex, double revenue) {
    final t = _ladder[currentIndex].$2.toDouble();
    return RankResult(
      rank: _ladder[currentIndex].$1,
      nextRank: currentIndex + 1 < _ladder.length
          ? _ladder[currentIndex + 1].$1
          : _ladder[currentIndex].$1,
      current: t,
      nextThreshold: currentIndex + 1 < _ladder.length
          ? _ladder[currentIndex + 1].$2.toDouble()
          : t,
      progress0to1: currentIndex + 1 >= _ladder.length ? 1.0 : 0.0,
      progressPercent: currentIndex + 1 >= _ladder.length ? 100 : 0,
      remainingToNext: currentIndex + 1 < _ladder.length
          ? (_ladder[currentIndex + 1].$2 - revenue).clamp(0.0, double.infinity)
          : 0.0,
    );
  }

  /// Sanity checks (run in debug). No test package.
  static void _runSanityChecks() {
    assert(getRankForRevenue(-1) == 'F');
    assert(getRankForRevenue(0) == 'F');
    assert(getRankForRevenue(2999) == 'F');
    assert(getRankForRevenue(3000) == 'E');
    assert(getRankForRevenue(6999) == 'E');
    assert(getRankForRevenue(7000) == 'D');
    assert(getRankForRevenue(14999) == 'D');
    assert(getRankForRevenue(29999) == 'C');
    assert(getRankForRevenue(30000) == 'B');
    assert(getRankForRevenue(49999) == 'B');
    assert(getRankForRevenue(50000) == 'A');
    assert(getRankForRevenue(99999) == 'A');
    assert(getRankForRevenue(100000) == 'S');
    assert(getRankForRevenue(249999) == 'S');
    assert(getRankForRevenue(250000) == 'SS');
    assert(getRankForRevenue(999999) == 'SS');
    assert(getRankForRevenue(1000000) == 'SSS');
    assert(getRankForRevenue(2000000) == 'SSS');

    final r0 = getRankProgress(0);
    assert(r0.rank == 'F' && r0.nextRank == 'E');
    assert(r0.current == 0 && r0.nextThreshold == 3000);
    assert(r0.progress0to1 == 0 && r0.progressPercent == 0);
    assert(r0.remainingToNext == 3000);

    final rMid = getRankProgress(15000);
    assert(rMid.rank == 'C' && rMid.nextRank == 'B');
    assert(rMid.current == 15000 && rMid.nextThreshold == 30000);
    assert((rMid.progress0to1 - 0.0).abs() < 0.001 && rMid.progressPercent == 0);

    final rB = getRankProgress(30000);
    assert(rB.rank == 'B' && rB.nextRank == 'A');
    assert(rB.current == 30000 && rB.nextThreshold == 50000);
    assert(rB.progress0to1 == 0 && rB.progressPercent == 0);
    assert(rB.remainingToNext == 20000);

    final rHalf = getRankProgress(40000); // B -> A: 30k to 50k
    assert(rHalf.rank == 'B' && rHalf.nextRank == 'A');
    assert((rHalf.progress0to1 - 0.5).abs() < 0.01);
    assert(rHalf.progressPercent == 50);
    assert((rHalf.remainingToNext - 10000).abs() < 0.01);

    final rSss = getRankProgress(1000000);
    assert(rSss.rank == 'SSS' && rSss.nextRank == 'SSS');
    assert(rSss.progress0to1 == 1 && rSss.progressPercent == 100);
    assert(rSss.remainingToNext == 0);
  }

  /// Call from main() in debug to run sanity checks. No-op in release.
  static void runSanityChecksInDebug() {
    assert(() {
      _runSanityChecks();
      return true;
    }());
  }
}
