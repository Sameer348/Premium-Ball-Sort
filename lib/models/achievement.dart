/// Which counter an achievement tracks.
enum AchievementMetric { levelsCompleted, perfectLevels, noUndoLevels, fastLevels, dailyStreak, tubesCompleted, threeStarLevels, dailyCompleted }

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.goal,
    required this.reward,
  });

  final String id;
  final String title;
  final String description;
  final AchievementMetric metric;
  final int goal;
  final int reward;

  static const all = <Achievement>[
    Achievement(id: 'first_sort', title: 'First Sort', description: 'Complete your first level', metric: AchievementMetric.levelsCompleted, goal: 1, reward: 50),
    Achievement(id: 'levels_10', title: 'Getting Into It', description: 'Complete 10 levels', metric: AchievementMetric.levelsCompleted, goal: 10, reward: 100),
    Achievement(id: 'levels_50', title: 'Sorting Habit', description: 'Complete 50 levels', metric: AchievementMetric.levelsCompleted, goal: 50, reward: 250),
    Achievement(id: 'levels_100', title: 'Centurion', description: 'Complete 100 levels', metric: AchievementMetric.levelsCompleted, goal: 100, reward: 500),
    Achievement(id: 'levels_500', title: 'Sphere Sage', description: 'Complete 500 levels', metric: AchievementMetric.levelsCompleted, goal: 500, reward: 1500),
    Achievement(id: 'levels_1000', title: 'Legend of Order', description: 'Complete 1000 levels', metric: AchievementMetric.levelsCompleted, goal: 1000, reward: 4000),
    Achievement(id: 'perfect_sorter', title: 'Perfect Sorter', description: 'Finish 10 levels at or under target moves', metric: AchievementMetric.perfectLevels, goal: 10, reward: 300),
    Achievement(id: 'no_undo', title: 'No Looking Back', description: 'Finish 25 levels without undo', metric: AchievementMetric.noUndoLevels, goal: 25, reward: 300),
    Achievement(id: 'speed_sorter', title: 'Speed Sorter', description: 'Finish 10 levels in under 60 seconds', metric: AchievementMetric.fastLevels, goal: 10, reward: 300),
    Achievement(id: 'daily_streak', title: 'Daily Ritual', description: 'Reach a 7-day daily streak', metric: AchievementMetric.dailyStreak, goal: 7, reward: 400),
    Achievement(id: 'color_master', title: 'Color Master', description: 'Complete 500 tubes', metric: AchievementMetric.tubesCompleted, goal: 500, reward: 500),
    Achievement(id: 'puzzle_master', title: 'Puzzle Master', description: 'Earn 3 stars on 100 levels', metric: AchievementMetric.threeStarLevels, goal: 100, reward: 1000),
  ];
}
