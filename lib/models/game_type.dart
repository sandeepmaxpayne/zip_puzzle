enum GameType { classic, original }

extension GameTypeCopy on GameType {
  String get title => switch (this) {
    GameType.classic => 'Classic',
    GameType.original => 'Original',
  };

  String get subtitle => switch (this) {
    GameType.classic =>
      'Daily route boards, streak claims, and difficulty-based progression.',
    GameType.original =>
      'Jump straight into the existing freeform puzzle you already built.',
  };
}
