import 'dart:math';
// Sudoku puzzle data and mapping logic

class SudokuPuzzle {
  final List<List<int?>> puzzle;
  final List<List<int>> solution;
  SudokuPuzzle(this.puzzle, this.solution);
}

// --- Easy 6x6 Puzzles (at least 5 unique) ---
final List<SudokuPuzzle> easy6x6Puzzles = [
  SudokuPuzzle(
    [
      [null, 2, null, 4, null, 6],
      [4, null, 6, null, 2, null],
      [null, 6, null, 2, null, 4],
      [2, null, 4, null, 6, null],
      [null, 4, null, 6, null, 2],
      [6, null, 2, null, 4, null],
    ],
    [
      [1, 2, 3, 4, 5, 6],
      [4, 5, 6, 1, 2, 3],
      [5, 6, 1, 2, 3, 4],
      [2, 3, 4, 5, 6, 1],
      [3, 4, 5, 6, 1, 2],
      [6, 1, 2, 3, 4, 5],
    ],
  ),
  SudokuPuzzle(
    [
      [1, null, null, 4, null, 6],
      [null, 5, 6, null, 2, null],
      [null, 6, 1, null, null, 4],
      [2, null, 4, 5, null, null],
      [null, 4, null, 6, 1, null],
      [6, null, 2, null, 4, 5],
    ],
    [
      [1, 2, 3, 4, 5, 6],
      [4, 5, 6, 1, 2, 3],
      [5, 6, 1, 2, 3, 4],
      [2, 3, 4, 5, 6, 1],
      [3, 4, 5, 6, 1, 2],
      [6, 1, 2, 3, 4, 5],
    ],
  ),
  SudokuPuzzle(
    [
      [null, null, 3, null, 5, 6],
      [4, 5, null, 1, null, null],
      [5, null, 1, null, 3, 4],
      [null, 3, 4, 5, null, 1],
      [3, 4, null, 6, 1, null],
      [6, 1, 2, null, 4, null],
    ],
    [
      [1, 2, 3, 4, 5, 6],
      [4, 5, 6, 1, 2, 3],
      [5, 6, 1, 2, 3, 4],
      [2, 3, 4, 5, 6, 1],
      [3, 4, 5, 6, 1, 2],
      [6, 1, 2, 3, 4, 5],
    ],
  ),
  SudokuPuzzle(
    [
      [1, 2, null, 4, null, null],
      [null, null, 6, 1, 2, 3],
      [5, 6, 1, null, 3, null],
      [2, 3, 4, 5, null, 1],
      [null, 4, 5, 6, 1, 2],
      [6, null, 2, 3, 4, 5],
    ],
    [
      [1, 2, 3, 4, 5, 6],
      [4, 5, 6, 1, 2, 3],
      [5, 6, 1, 2, 3, 4],
      [2, 3, 4, 5, 6, 1],
      [3, 4, 5, 6, 1, 2],
      [6, 1, 2, 3, 4, 5],
    ],
  ),
  SudokuPuzzle(
    [
      [null, 2, 3, null, 5, null],
      [4, null, 6, 1, null, 3],
      [5, 6, null, 2, 3, null],
      [2, 3, 4, null, 6, 1],
      [3, null, 5, 6, 1, 2],
      [6, 1, null, 3, 4, 5],
    ],
    [
      [1, 2, 3, 4, 5, 6],
      [4, 5, 6, 1, 2, 3],
      [5, 6, 1, 2, 3, 4],
      [2, 3, 4, 5, 6, 1],
      [3, 4, 5, 6, 1, 2],
      [6, 1, 2, 3, 4, 5],
    ],
  ),
];

// --- Medium 9x9 Puzzles (at least 5 unique) ---
final List<SudokuPuzzle> medium9x9Puzzles = [
  SudokuPuzzle(
    [
      [5, 3, null, null, 7, null, null, null, null],
      [6, null, null, 1, 9, 5, null, null, null],
      [null, 9, 8, null, null, null, null, 6, null],
      [8, null, null, null, 6, null, null, null, 3],
      [4, null, null, 8, null, 3, null, null, 1],
      [7, null, null, null, 2, null, null, null, 6],
      [null, 6, null, null, null, null, 2, 8, null],
      [null, null, null, 4, 1, 9, null, null, 5],
      [null, null, null, null, 8, null, null, 7, 9],
    ],
    [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ],
  ),
  SudokuPuzzle(
    [
      [null, null, null, 2, 6, null, 7, null, 1],
      [6, 8, null, null, 7, null, null, 9, null],
      [1, 9, null, null, null, 4, 5, null, null],
      [8, 2, null, 1, null, null, null, 4, null],
      [null, null, 4, 6, null, 2, 9, null, null],
      [null, 5, null, null, null, 3, null, 2, 8],
      [null, null, 9, 3, null, null, null, 7, 4],
      [null, 4, null, null, 5, null, null, 3, 6],
      [7, null, 3, null, 1, 8, null, null, null],
    ],
    [
      [4, 3, 5, 2, 6, 9, 7, 8, 1],
      [6, 8, 2, 5, 7, 1, 4, 9, 3],
      [1, 9, 7, 8, 3, 4, 5, 6, 2],
      [8, 2, 6, 1, 9, 5, 3, 4, 7],
      [3, 7, 4, 6, 8, 2, 9, 1, 5],
      [9, 5, 1, 7, 4, 3, 6, 2, 8],
      [5, 1, 9, 3, 2, 6, 8, 7, 4],
      [2, 4, 8, 9, 5, 7, 1, 3, 6],
      [7, 6, 3, 4, 1, 8, 2, 5, 9],
    ],
  ),
  SudokuPuzzle(
    [
      [2, null, null, 6, null, 8, null, null, 5],
      [null, 8, null, null, 7, null, null, 9, null],
      [6, null, 1, null, 9, 5, null, null, null],
      [null, 7, null, null, 6, null, null, null, 3],
      [4, null, null, 8, null, 3, null, null, 1],
      [7, null, null, null, 2, null, null, null, 6],
      [null, 6, null, null, null, null, 2, 8, null],
      [null, null, null, 4, 1, 9, null, null, 5],
      [null, null, null, null, 8, null, null, 7, 9],
    ],
    [
      [2, 7, 9, 6, 3, 8, 1, 4, 5],
      [5, 8, 3, 2, 7, 1, 6, 9, 4],
      [6, 4, 1, 5, 9, 5, 3, 2, 7],
      [8, 7, 5, 9, 6, 2, 4, 1, 3],
      [4, 2, 6, 8, 5, 3, 7, 5, 1],
      [7, 1, 8, 3, 2, 4, 5, 6, 9],
      [9, 6, 4, 7, 1, 5, 2, 8, 3],
      [3, 5, 2, 4, 1, 9, 8, 7, 6],
      [1, 9, 7, 5, 8, 6, 9, 3, 2],
    ],
  ),
  // ...add more unique puzzles for medium and hard...
];

// --- Hard 9x9 Puzzles (at least 5 unique) ---
final List<SudokuPuzzle> hard9x9Puzzles = [
  SudokuPuzzle(
    [
      [null, null, null, 2, 6, null, 7, null, 1],
      [6, 8, null, null, 7, null, null, 9, null],
      [1, 9, null, null, null, 4, 5, null, null],
      [8, 2, null, 1, null, null, null, 4, null],
      [null, null, 4, 6, null, 2, 9, null, null],
      [null, 5, null, null, null, 3, null, 2, 8],
      [null, null, 9, 3, null, null, null, 7, 4],
      [null, 4, null, null, 5, null, null, 3, 6],
      [7, null, 3, null, 1, 8, null, null, null],
    ],
    [
      [4, 3, 5, 2, 6, 9, 7, 8, 1],
      [6, 8, 2, 5, 7, 1, 4, 9, 3],
      [1, 9, 7, 8, 3, 4, 5, 6, 2],
      [8, 2, 6, 1, 9, 5, 3, 4, 7],
      [3, 7, 4, 6, 8, 2, 9, 1, 5],
      [9, 5, 1, 7, 4, 3, 6, 2, 8],
      [5, 1, 9, 3, 2, 6, 8, 7, 4],
      [2, 4, 8, 9, 5, 7, 1, 3, 6],
      [7, 6, 3, 4, 1, 8, 2, 5, 9],
    ],
  ),
  // ...add more unique hard puzzles here...
];

// --- Level Mapping Logic ---

class LevelSession {
  final List<int> easyOrder;
  final List<int> mediumOrder;
  final List<int> hardOrder;
  LevelSession({
    required this.easyOrder,
    required this.mediumOrder,
    required this.hardOrder,
  });
}

LevelSession generateLevelSession(Random rng) {
  List<int> easyOrder = List.generate(easy6x6Puzzles.length, (i) => i)
    ..shuffle(rng);
  List<int> mediumOrder = List.generate(medium9x9Puzzles.length, (i) => i)
    ..shuffle(rng);
  List<int> hardOrder = List.generate(hard9x9Puzzles.length, (i) => i)
    ..shuffle(rng);
  return LevelSession(
    easyOrder: easyOrder,
    mediumOrder: mediumOrder,
    hardOrder: hardOrder,
  );
}

SudokuPuzzle getPuzzleForLevel(LevelSession session, int level) {
  if (level >= 1 && level <= 20) {
    int idx = session.easyOrder[(level - 1) % easy6x6Puzzles.length];
    return easy6x6Puzzles[idx];
  } else if (level >= 21 && level <= 50) {
    int idx = session.mediumOrder[(level - 21) % medium9x9Puzzles.length];
    return medium9x9Puzzles[idx];
  } else if (level >= 51 && level <= 100) {
    int idx = session.hardOrder[(level - 51) % hard9x9Puzzles.length];
    return hard9x9Puzzles[idx];
  }
  throw Exception('Invalid level');
}
