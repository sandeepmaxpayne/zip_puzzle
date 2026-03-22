import 'app_progress.dart';

class ClassicLeaderboardEntry {
  const ClassicLeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.score,
    required this.elapsedSeconds,
    required this.hintsUsed,
    required this.undoCount,
    required this.difficulty,
    required this.updatedAtIso,
  });

  final String userId;
  final String displayName;
  final int score;
  final int elapsedSeconds;
  final int hintsUsed;
  final int undoCount;
  final ClassicDifficulty difficulty;
  final String updatedAtIso;

  factory ClassicLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return ClassicLeaderboardEntry(
      userId: json['userId'] as String? ?? 'guest',
      displayName: json['displayName'] as String? ?? 'Guest',
      score: json['score'] as int? ?? 0,
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      undoCount: json['undoCount'] as int? ?? 0,
      difficulty: ClassicDifficulty.values.byName(
        json['difficulty'] as String? ?? ClassicDifficulty.easy.name,
      ),
      updatedAtIso: json['updatedAtIso'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'displayName': displayName,
        'score': score,
        'elapsedSeconds': elapsedSeconds,
        'hintsUsed': hintsUsed,
        'undoCount': undoCount,
        'difficulty': difficulty.name,
        'updatedAtIso': updatedAtIso,
      };
}
