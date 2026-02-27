/// Rank configuration for Hunter Rank Finance System.
/// Ordered ladder: rank name → minimum monthly revenue threshold.
class RankConfig {
  RankConfig._();

  static const int defaultMonthlyTarget = 30000;

  /// Ordered (rank name, min revenue) from lowest to highest.
  static const List<(String name, int threshold)> rankLadder = [
    ('F', 0),
    ('E', 3000),
    ('D', 7000),
    ('C', 15000),
    ('B', 30000),
    ('A', 50000),
    ('S', 100000),
    ('SS', 250000),
    ('SSS', 1000000),
  ];

  /// All rank names in order (F → SSS).
  static List<String> get rankNames =>
      rankLadder.map((e) => e.$1).toList();

  /// Threshold for a rank by index. [0] = F, [1] = E, ...
  static int thresholdAt(int index) => rankLadder[index].$2;
}
