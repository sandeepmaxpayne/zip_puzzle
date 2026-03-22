import 'dart:convert';

enum ClassicDifficulty { easy, medium, hard }

extension ClassicDifficultyCopy on ClassicDifficulty {
  String get key => name;

  String get label => switch (this) {
    ClassicDifficulty.easy => 'Easy',
    ClassicDifficulty.medium => 'Medium',
    ClassicDifficulty.hard => 'Hard',
  };

  String get flavor => switch (this) {
    ClassicDifficulty.easy => 'More guides, calmer route',
    ClassicDifficulty.medium => 'Balanced anchors and speed',
    ClassicDifficulty.hard => 'Sparse anchors, focused finish',
  };
}

class DayProgress {
  DayProgress({
    Map<String, int>? bestSeconds,
    Map<String, bool>? completions,
  })  : bestSeconds = bestSeconds ?? <String, int>{},
        completions = completions ?? <String, bool>{};

  final Map<String, int> bestSeconds;
  final Map<String, bool> completions;

  bool get completedAny => completions.values.any((value) => value);

  bool isCompleted(ClassicDifficulty difficulty) {
    return completions[difficulty.key] ?? false;
  }

  void markCompleted(ClassicDifficulty difficulty, int seconds) {
    completions[difficulty.key] = true;
    final previousBest = bestSeconds[difficulty.key];
    if (previousBest == null || seconds < previousBest) {
      bestSeconds[difficulty.key] = seconds;
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bestSeconds': bestSeconds,
        'completions': completions,
      };

  factory DayProgress.fromJson(Map<String, dynamic> json) {
    return DayProgress(
      bestSeconds: (json['bestSeconds'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value as int)),
      completions: (json['completions'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value as bool)),
    );
  }
}

class AppProgress {
  AppProgress({
    required this.totalClaims,
    required this.currentStreak,
    required this.lastClaimDateIso,
    required this.totalScore,
    required this.streakFreezeCredits,
    required this.advanceUnlockDays,
    required this.processedPurchaseTokens,
    required this.yearlyProgress,
    this.userId,
  });

  factory AppProgress.initial() {
    return AppProgress(
      totalClaims: 0,
      currentStreak: 0,
      lastClaimDateIso: null,
      totalScore: 0,
      streakFreezeCredits: 0,
      advanceUnlockDays: 0,
      processedPurchaseTokens: <String>{},
      yearlyProgress: <int, Map<int, DayProgress>>{},
    );
  }

  String? userId;
  int totalClaims;
  int currentStreak;
  String? lastClaimDateIso;
  int totalScore;
  int streakFreezeCredits;
  int advanceUnlockDays;
  final Set<String> processedPurchaseTokens;
  final Map<int, Map<int, DayProgress>> yearlyProgress;

  static int totalDaysForYear(int year) {
    final isLeap =
        DateTime(year, 12, 31).difference(DateTime(year, 1, 1)).inDays == 365;
    return isLeap ? 366 : 365;
  }

  DateTime? get lastClaimDate =>
      lastClaimDateIso == null ? null : DateTime.tryParse(lastClaimDateIso!);

  int get nextClaimDayIndex => totalClaims + 1;

  bool canClaimToday(DateTime now) {
    final claimDate = lastClaimDate;
    if (claimDate == null) {
      return true;
    }
    return _dateOnly(claimDate) != _dateOnly(now);
  }

  DayProgress dayProgressFor(int year, int day) {
    final yearMap = yearlyProgress.putIfAbsent(year, () => <int, DayProgress>{});
    return yearMap.putIfAbsent(day, DayProgress.new);
  }

  bool isDayCompletedAny(int year, int day) {
    return yearlyProgress[year]?[day]?.completedAny ?? false;
  }

  bool isDayCompleted(int year, int day, ClassicDifficulty difficulty) {
    return yearlyProgress[year]?[day]?.isCompleted(difficulty) ?? false;
  }

  bool isDayUnlocked({
    required int year,
    required int day,
    required int totalDays,
  }) {
    if (day < 1 || day > totalDays) {
      return false;
    }
    if (day == 1) {
      return true;
    }
    if (isDayCompletedAny(year, day)) {
      return true;
    }
    final purchasedUnlockGate = day <= totalClaims + advanceUnlockDays + 1;
    if (purchasedUnlockGate) {
      return true;
    }
    final previousComplete = isDayCompletedAny(year, day - 1);
    final streakGate = totalClaims >= day - 1;
    return previousComplete && streakGate;
  }

  void claimToday(DateTime now) {
    if (!canClaimToday(now)) {
      return;
    }
    final normalizedNow = _dateOnly(now);
    final previous = lastClaimDate == null ? null : _dateOnly(lastClaimDate!);
    if (previous != null && normalizedNow.difference(previous).inDays == 1) {
      currentStreak += 1;
    } else if (previous != null &&
        normalizedNow.difference(previous).inDays > 1 &&
        streakFreezeCredits > 0) {
      streakFreezeCredits -= 1;
      currentStreak += 1;
    } else {
      currentStreak = 1;
    }
    totalClaims += 1;
    lastClaimDateIso = normalizedNow.toIso8601String();
  }

  void markDayCompleted({
    required int year,
    required int day,
    required ClassicDifficulty difficulty,
    required int seconds,
  }) {
    dayProgressFor(year, day).markCompleted(difficulty, seconds);
  }

  void awardPoints(int points) {
    totalScore += points;
  }

  void grantAdvanceUnlockDays(int days) {
    advanceUnlockDays += days;
  }

  void grantStreakFreezeCredits(int credits) {
    streakFreezeCredits += credits;
  }

  bool hasProcessedPurchaseToken(String token) {
    return token.isNotEmpty && processedPurchaseTokens.contains(token);
  }

  void rememberPurchaseToken(String token) {
    if (token.isNotEmpty) {
      processedPurchaseTokens.add(token);
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'totalClaims': totalClaims,
        'currentStreak': currentStreak,
        'lastClaimDateIso': lastClaimDateIso,
        'totalScore': totalScore,
        'streakFreezeCredits': streakFreezeCredits,
        'advanceUnlockDays': advanceUnlockDays,
        'processedPurchaseTokens': processedPurchaseTokens.toList(),
        'yearlyProgress': yearlyProgress.map(
          (year, days) => MapEntry(
            year.toString(),
            days.map(
              (day, progress) => MapEntry(day.toString(), progress.toJson()),
            ),
          ),
        ),
      };

  String toStorageString() => jsonEncode(toJson());

  factory AppProgress.fromStorageString(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    return AppProgress.fromJson(decoded);
  }

  factory AppProgress.fromJson(Map<String, dynamic> json) {
    final progressJson =
        json['yearlyProgress'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return AppProgress(
      userId: json['userId'] as String?,
      totalClaims: json['totalClaims'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      lastClaimDateIso: json['lastClaimDateIso'] as String?,
      totalScore: json['totalScore'] as int? ?? 0,
      streakFreezeCredits: json['streakFreezeCredits'] as int? ?? 0,
      advanceUnlockDays: json['advanceUnlockDays'] as int? ?? 0,
      processedPurchaseTokens:
          (json['processedPurchaseTokens'] as List<dynamic>? ?? <dynamic>[])
              .map((token) => token as String)
              .toSet(),
      yearlyProgress: progressJson.map(
        (year, days) => MapEntry(
          int.parse(year),
          (days as Map<String, dynamic>).map(
            (day, progress) => MapEntry(
              int.parse(day),
              DayProgress.fromJson(progress as Map<String, dynamic>),
            ),
          ),
        ),
      ),
    );
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
