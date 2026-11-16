/// Tunable economy. Keep generosity high — the game should never feel
/// pay-to-progress.
class Economy {
  Economy._();

  static const int hintPrice = 60;
  static const int undoPrice = 20;
  static const int extraTubePrice = 120;
  static const int shufflePrice = 90;

  /// Undos per level that never touch the inventory.
  static const int freeUndosPerLevel = 3;
  static const int maxExtraTubesPerLevel = 2;

  static const int dailyChallengeCoins = 120;
  static const double perfectModeMultiplier = 2;
  static const double timeAttackMultiplier = 1.5;
}
