enum RewardKind { coins, hint, undo, extraTube, skin, premium }

class DailyReward {
  const DailyReward(this.day, this.kind, this.amount, this.label);
  final int day;
  final RewardKind kind;
  final int amount;
  final String label;

  /// 7-day cycle. Day 5 grants a ball skin, day 7 a premium bundle.
  static const cycle = <DailyReward>[
    DailyReward(1, RewardKind.coins, 50, '50 Coins'),
    DailyReward(2, RewardKind.coins, 80, '80 Coins'),
    DailyReward(3, RewardKind.hint, 2, '2 Hints'),
    DailyReward(4, RewardKind.undo, 5, '5 Undos'),
    DailyReward(5, RewardKind.skin, 1, 'Pearl Skin'),
    DailyReward(6, RewardKind.coins, 150, '150 Coins'),
    DailyReward(7, RewardKind.premium, 300, 'Premium Bundle'),
  ];

  /// Skin unlocked on day 5.
  static const skinRewardId = 'ball_pearl';
}
