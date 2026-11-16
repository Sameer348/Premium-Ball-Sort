/// Result record for one day's challenge.
class DailyChallengeRecord {
  const DailyChallengeRecord({required this.dateKey, this.completed = false, this.bestScore = 0, this.bestMoves = 0, this.attempts = 0});

  /// yyyymmdd.
  final int dateKey;
  final bool completed;
  final int bestScore;
  final int bestMoves;
  final int attempts;

  DailyChallengeRecord copyWith({bool? completed, int? bestScore, int? bestMoves, int? attempts}) => DailyChallengeRecord(
        dateKey: dateKey,
        completed: completed ?? this.completed,
        bestScore: bestScore ?? this.bestScore,
        bestMoves: bestMoves ?? this.bestMoves,
        attempts: attempts ?? this.attempts,
      );

  Map<String, Object?> toJson() => {'d': dateKey, 'c': completed, 's': bestScore, 'm': bestMoves, 'a': attempts};

  factory DailyChallengeRecord.fromJson(Map<String, Object?> j) => DailyChallengeRecord(
        dateKey: j['d'] as int,
        completed: j['c'] as bool? ?? false,
        bestScore: j['s'] as int? ?? 0,
        bestMoves: j['m'] as int? ?? 0,
        attempts: j['a'] as int? ?? 0,
      );
}

int dateKeyOf(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

DateTime dateOfKey(int k) => DateTime(k ~/ 10000, k ~/ 100 % 100, k % 100);
