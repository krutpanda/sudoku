import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/puzzles_fixed.dart';
import 'package:lottie/lottie.dart';
import '../components/banner_ad_widget.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class GameScreen extends StatefulWidget {
  final int? level;
  const GameScreen({super.key, this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late List<List<int?>> puzzle;
  late List<List<int?>> solution;
  late List<List<bool>> fixed;
  int? selectedRow;
  int? selectedCol;
  int? selectedNumber;
  int mistakes = 0;
  int maxMistakes = 3;
  int seconds = 0;
  Timer? timer;
  List<List<List<int?>>> history = [];
  bool gameOver = false;
  bool gameWon = false;
  bool mistakeFlash = false;
  AnimationController? _flashController;
  DateTime? _lastSolveAll;
  DateTime? _lastSolveStepHour;
  int _solveStepCount = 0;
  bool _solveAllAvailable = true;
  bool _solveStepAvailable = true;
  Set<String> warningCells = {};
  Duration? _solveStepRemaining;
  Duration? _solveAllRemaining;
  Timer? _cooldownTimer;
  LevelSession? session;
  int? level;
  SudokuPuzzle? currentPuzzle;
  DateTime? lastAIHintTime;
  Timer? aiHintCooldownTimer;
  Duration aiHintCooldown = Duration.zero;
  bool showConfetti = false;
  int score = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Duration _soundDuration = const Duration(milliseconds: 300);
  AnimationController? _shakeController;
  Animation<double>? _shakeAnimation;
  bool _showContent = false;
  int _lastScore = 0;
  int _lastSeconds = 0;
  late AnimationController _scorePopController;
  late AnimationController _timerPopController;
  late Animation<double> _scorePopAnim;
  late Animation<double> _timerPopAnim;

  @override
  void initState() {
    super.initState();
    level = widget.level;
    _loadSessionAndPuzzle();
    _loadLimits();
    _generatePuzzle();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!gameOver && !gameWon) {
        setState(() {
          seconds++;
        });
      }
    });
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flashController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          mistakeFlash = false;
        });
        _flashController!.reset();
      }
    });
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 16,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController!);
    _scorePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 1.0,
      upperBound: 1.2,
    );
    _scorePopAnim = _scorePopController.drive(
      Tween<double>(begin: 1.0, end: 1.2),
    );
    _timerPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 1.0,
      upperBound: 1.2,
    );
    _timerPopAnim = _timerPopController.drive(
      Tween<double>(begin: 1.0, end: 1.2),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => _showContent = true);
    });
    _startCooldownTimer();
    _updateAIHintCooldown();
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _updateCooldowns();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCooldowns();
    });
  }

  void _updateCooldowns() {
    final now = DateTime.now();
    // Solve Step
    if (!_solveStepAvailable && _lastSolveStepHour != null) {
      final nextHour = DateTime(
        _lastSolveStepHour!.year,
        _lastSolveStepHour!.month,
        _lastSolveStepHour!.day,
        _lastSolveStepHour!.hour + 1,
      );
      final remaining = nextHour.difference(now);
      setState(() {
        _solveStepRemaining = remaining > Duration.zero ? remaining : null;
      });
    } else {
      setState(() {
        _solveStepRemaining = null;
      });
    }
    // Solve All
    if (!_solveAllAvailable && _lastSolveAll != null) {
      final tomorrow = DateTime(
        _lastSolveAll!.year,
        _lastSolveAll!.month,
        _lastSolveAll!.day + 1,
      );
      final remaining = tomorrow.difference(now);
      setState(() {
        _solveAllRemaining = remaining > Duration.zero ? remaining : null;
      });
    } else {
      setState(() {
        _solveAllRemaining = null;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _flashController?.dispose();
    _cooldownTimer?.cancel();
    aiHintCooldownTimer?.cancel();
    _audioPlayer.dispose();
    _shakeController?.dispose();
    _scorePopController.dispose();
    _timerPopController.dispose();
    super.dispose();
  }

  Future<void> _loadLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSolveAllStr = prefs.getString('lastSolveAll');
    final lastSolveStepHourStr = prefs.getString('lastSolveStepHour');
    final solveStepCount = prefs.getInt('solveStepCount') ?? 0;
    final now = DateTime.now();
    if (lastSolveAllStr != null) {
      _lastSolveAll = DateTime.tryParse(lastSolveAllStr);
      if (_lastSolveAll != null &&
          _lastSolveAll!.day == now.day &&
          _lastSolveAll!.month == now.month &&
          _lastSolveAll!.year == now.year) {
        _solveAllAvailable = false;
      } else {
        _solveAllAvailable = true;
      }
    } else {
      _solveAllAvailable = true;
    }
    if (lastSolveStepHourStr != null) {
      _lastSolveStepHour = DateTime.tryParse(lastSolveStepHourStr);
      if (_lastSolveStepHour != null &&
          _lastSolveStepHour!.year == now.year &&
          _lastSolveStepHour!.month == now.month &&
          _lastSolveStepHour!.day == now.day &&
          _lastSolveStepHour!.hour == now.hour) {
        _solveStepCount = solveStepCount;
        _solveStepAvailable = _solveStepCount < 3;
      } else {
        _solveStepCount = 0;
        _solveStepAvailable = true;
      }
    } else {
      _solveStepCount = 0;
      _solveStepAvailable = true;
    }
    setState(() {});
  }

  Future<void> _updateSolveAllUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('lastSolveAll', now.toIso8601String());
    setState(() {
      _lastSolveAll = now;
      _solveAllAvailable = false;
    });
  }

  Future<void> _updateSolveStepUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    if (_lastSolveStepHour != null &&
        _lastSolveStepHour!.year == now.year &&
        _lastSolveStepHour!.month == now.month &&
        _lastSolveStepHour!.day == now.day &&
        _lastSolveStepHour!.hour == now.hour) {
      _solveStepCount++;
    } else {
      _solveStepCount = 1;
      _lastSolveStepHour = now;
    }
    await prefs.setString(
      'lastSolveStepHour',
      _lastSolveStepHour!.toIso8601String(),
    );
    await prefs.setInt('solveStepCount', _solveStepCount);
    setState(() {
      _solveStepAvailable = _solveStepCount < 3;
    });
  }

  Future<void> _loadSessionAndPuzzle() async {
    final prefs = await SharedPreferences.getInstance();
    // Load or create session mapping
    String? sessionSeed = prefs.getString('levelSessionSeed');
    if (sessionSeed == null) {
      sessionSeed = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('levelSessionSeed', sessionSeed);
    }
    final rng = Random(int.parse(sessionSeed));
    session = generateLevelSession(rng);
    // Load puzzle for this level
    if (level != null) {
      currentPuzzle = getPuzzleForLevel(session!, level!);
      puzzle = currentPuzzle!.puzzle
          .map((row) => List<int?>.from(row))
          .toList();
      solution = currentPuzzle!.solution
          .map((row) => List<int?>.from(row))
          .toList();
      fixed = List.generate(
        puzzle.length,
        (i) => List.generate(puzzle[i].length, (j) => puzzle[i][j] != null),
      );
    }
    // Load AI hint cooldown
    String aiHintKey = 'aiHintTime_${level ?? 0}';
    String? lastHintStr = prefs.getString(aiHintKey);
    if (lastHintStr != null) {
      lastAIHintTime = DateTime.tryParse(lastHintStr);
    }
    _updateAIHintCooldown();
    setState(() {});
  }

  void _updateAIHintCooldown() {
    aiHintCooldownTimer?.cancel();
    if (lastAIHintTime != null) {
      final now = DateTime.now();
      final nextAvailable = lastAIHintTime!.add(const Duration(minutes: 10));
      final remaining = nextAvailable.difference(now);
      if (remaining > Duration.zero) {
        aiHintCooldown = remaining;
        aiHintCooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            final now = DateTime.now();
            final nextAvailable = lastAIHintTime!.add(
              const Duration(minutes: 10),
            );
            aiHintCooldown = nextAvailable.difference(now);
            if (aiHintCooldown <= Duration.zero) {
              aiHintCooldownTimer?.cancel();
              aiHintCooldown = Duration.zero;
            }
          });
        });
      } else {
        aiHintCooldown = Duration.zero;
      }
    } else {
      aiHintCooldown = Duration.zero;
    }
  }

  void _generatePuzzle() {
    if (currentPuzzle != null) {
      puzzle = currentPuzzle!.puzzle
          .map((row) => List<int?>.from(row))
          .toList();
      solution = currentPuzzle!.solution
          .map((row) => List<int?>.from(row))
          .toList();
      fixed = List.generate(
        puzzle.length,
        (i) => List.generate(puzzle[i].length, (j) => puzzle[i][j] != null),
      );
    } else {
      // Default to 6x6 puzzle if no level is selected
      puzzle = [
        [null, 2, null, 4, null, 6],
        [4, null, 6, null, 2, null],
        [null, 6, null, 2, null, 4],
        [2, null, 4, null, 6, null],
        [null, 4, null, 6, null, 2],
        [6, null, 2, null, 4, null],
      ];
      solution = [
        [1, 2, 3, 4, 5, 6],
        [4, 5, 6, 1, 2, 3],
        [5, 6, 1, 2, 3, 4],
        [2, 3, 4, 5, 6, 1],
        [3, 4, 5, 6, 1, 2],
        [6, 1, 2, 3, 4, 5],
      ];
      fixed = List.generate(
        6,
        (i) => List.generate(6, (j) => puzzle[i][j] != null),
      );
    }
    history.clear();
    selectedRow = null;
    selectedCol = null;
    selectedNumber = null;
    mistakes = 0;
    seconds = 0;
    gameOver = false;
    gameWon = false;
    mistakeFlash = false;
  }

  void _selectCell(int row, int col) {
    if (gameOver || gameWon) return;
    if (selectedNumber == null) return;
    if (fixed[row][col] || puzzle[row][col] != null) return;
    setState(() {
      history.add(_copyGrid(puzzle));
      puzzle[row][col] = selectedNumber;
      // If incorrect, show warning for 2 seconds
      if (selectedNumber != solution[row][col]) {
        String key = '[$row,$col]';
        warningCells.add(key);
        mistakeFlash = true;
        _flashController?.forward();
        _playSound('assets/sounds/mistake.mp3');
        HapticFeedback.vibrate();
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            warningCells.remove(key);
            mistakeFlash = false;
          });
        });
      } else {
        score += 10;
        _scorePopController.forward(from: 0.0);
        _playSound('assets/sounds/correct.mp3');
        HapticFeedback.selectionClick();
        if (_isComplete()) {
          _onLevelComplete();
        }
      }
      selectedNumber = null;
    });
  }

  void _selectNumber(int num) {
    _playSound('assets/sounds/cell.mp3');
    setState(() {
      selectedNumber = num;
    });
  }

  void _undo() {
    if (gameOver || gameWon) return;
    if (history.isNotEmpty) {
      setState(() {
        puzzle = _copyGrid(history.removeLast());
      });
      _playSound('assets/sounds/cell.mp3');
    }
  }

  void _hint() {
    if (gameOver || gameWon) return;
    if (selectedRow == null || selectedCol == null) return;
    if (fixed[selectedRow!][selectedCol!]) return;
    setState(() {
      history.add(_copyGrid(puzzle));
      puzzle[selectedRow!][selectedCol!] = solution[selectedRow!][selectedCol!];
      if (_isComplete()) {
        _onLevelComplete();
      }
    });
  }

  List<List<int?>> _copyGrid(List<List<int?>> grid) {
    return List.generate(grid.length, (i) => List<int?>.from(grid[i]));
  }

  bool _isComplete() {
    for (var row in puzzle) {
      for (var cell in row) {
        if (cell == null) return false;
      }
    }
    return true;
  }

  Color? _cellColor(int row, int col) {
    String key = '[$row,$col]';
    if (warningCells.contains(key)) {
      return Colors.red[200];
    }
    if (selectedRow == null || selectedCol == null) return null;
    if (row == selectedRow && col == selectedCol) {
      return Colors.blue[100];
    }
    if (row == selectedRow || col == selectedCol) {
      return Colors.blue[50];
    }
    // Box highlight
    final boxSize = puzzle.length == 9 ? 3 : 2;
    int boxRow = selectedRow! ~/ boxSize;
    int boxCol = selectedCol! ~/ boxSize;
    if (row ~/ boxSize == boxRow && col ~/ boxSize == boxCol) {
      return Colors.blue[50];
    }
    return null;
  }

  void _showCooldownDialog(Duration remaining, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            late Timer timer;
            String formatTime(Duration d) {
              String twoDigits(int n) => n.toString().padLeft(2, '0');
              if (d.inHours > 0) {
                return '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}';
              } else {
                return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}';
              }
            }

            Duration timeLeft = remaining;
            timer = Timer.periodic(const Duration(seconds: 1), (_) {
              if (timeLeft.inSeconds <= 1) {
                timer.cancel();
                Navigator.of(context).pop();
              } else {
                setState(() {
                  timeLeft = timeLeft - const Duration(seconds: 1);
                });
              }
            });
            return AlertDialog(
              title: Text(title),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    formatTime(timeLeft),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _solveStep() {
    if (!_solveStepAvailable) {
      if (_solveStepRemaining != null) {
        _showCooldownDialog(_solveStepRemaining!, 'Solve Step available in');
      }
      return;
    }
    _updateSolveStepUsage();
    // Try hidden singles in rows, columns, and blocks
    for (int num = 1; num <= 9; num++) {
      // Rows
      for (int row = 0; row < 9; row++) {
        List<int> possibleCols = [];
        for (int col = 0; col < 9; col++) {
          if (puzzle[row][col] == null &&
              !fixed[row][col] &&
              _getCandidates(row, col).contains(num)) {
            possibleCols.add(col);
          }
        }
        if (possibleCols.length == 1) {
          setState(() {
            puzzle[row][possibleCols[0]] = num;
          });
          return;
        }
      }
      // Columns
      for (int col = 0; col < 9; col++) {
        List<int> possibleRows = [];
        for (int row = 0; row < 9; row++) {
          if (puzzle[row][col] == null &&
              !fixed[row][col] &&
              _getCandidates(row, col).contains(num)) {
            possibleRows.add(row);
          }
        }
        if (possibleRows.length == 1) {
          setState(() {
            puzzle[possibleRows[0]][col] = num;
          });
          return;
        }
      }
      // Blocks
      for (int boxRow = 0; boxRow < 3; boxRow++) {
        for (int boxCol = 0; boxCol < 3; boxCol++) {
          List<List<int>> possibleCells = [];
          for (int r = boxRow * 3; r < boxRow * 3 + 3; r++) {
            for (int c = boxCol * 3; c < boxCol * 3 + 3; c++) {
              if (puzzle[r][c] == null &&
                  !fixed[r][c] &&
                  _getCandidates(r, c).contains(num)) {
                possibleCells.add([r, c]);
              }
            }
          }
          if (possibleCells.length == 1) {
            setState(() {
              puzzle[possibleCells[0][0]][possibleCells[0][1]] = num;
            });
            return;
          }
        }
      }
    }
    // If no move found
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('No logical move found.')));
  }

  void _solveAll() {
    if (!_solveAllAvailable) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final remaining = tomorrow.difference(now);
      _showCooldownDialog(remaining, 'Solve All available in');
      return;
    }
    _updateSolveAllUsage();
    bool progress = true;
    while (progress && !_isComplete()) {
      progress = _solveStepSilent();
    }
    if (!_isComplete()) {
      _backtrackSolve();
    }
    setState(() {});
  }

  // Like _solveStep, but returns true if a cell was filled, false otherwise, and does not show SnackBar or call setState
  bool _solveStepSilent() {
    for (int num = 1; num <= 9; num++) {
      // Rows
      for (int row = 0; row < 9; row++) {
        List<int> possibleCols = [];
        for (int col = 0; col < 9; col++) {
          if (puzzle[row][col] == null &&
              !fixed[row][col] &&
              _getCandidates(row, col).contains(num)) {
            possibleCols.add(col);
          }
        }
        if (possibleCols.length == 1) {
          puzzle[row][possibleCols[0]] = num;
          return true;
        }
      }
      // Columns
      for (int col = 0; col < 9; col++) {
        List<int> possibleRows = [];
        for (int row = 0; row < 9; row++) {
          if (puzzle[row][col] == null &&
              !fixed[row][col] &&
              _getCandidates(row, col).contains(num)) {
            possibleRows.add(row);
          }
        }
        if (possibleRows.length == 1) {
          puzzle[possibleRows[0]][col] = num;
          return true;
        }
      }
      // Blocks
      for (int boxRow = 0; boxRow < 3; boxRow++) {
        for (int boxCol = 0; boxCol < 3; boxCol++) {
          List<List<int>> possibleCells = [];
          for (int r = boxRow * 3; r < boxRow * 3 + 3; r++) {
            for (int c = boxCol * 3; c < boxCol * 3 + 3; c++) {
              if (puzzle[r][c] == null &&
                  !fixed[r][c] &&
                  _getCandidates(r, c).contains(num)) {
                possibleCells.add([r, c]);
              }
            }
          }
          if (possibleCells.length == 1) {
            puzzle[possibleCells[0][0]][possibleCells[0][1]] = num;
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _backtrackSolve() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (puzzle[row][col] == null && !fixed[row][col]) {
          Set<int> candidates = _getCandidates(row, col);
          for (int num in candidates) {
            puzzle[row][col] = num;
            if (_backtrackSolve()) {
              return true;
            }
            puzzle[row][col] = null;
          }
          return false;
        }
      }
    }
    return true;
  }

  Set<int> _getCandidates(int row, int col) {
    final gridSize = puzzle.length;
    Set<int> candidates = Set.from(List.generate(gridSize, (i) => i + 1));
    // Remove numbers in the same row
    for (int c = 0; c < gridSize; c++) {
      if (puzzle[row][c] != null) {
        candidates.remove(puzzle[row][c]);
      }
    }
    // Remove numbers in the same column
    for (int r = 0; r < gridSize; r++) {
      if (puzzle[r][col] != null) {
        candidates.remove(puzzle[r][col]);
      }
    }
    // Remove numbers in the same box
    final boxSize = gridSize == 9 ? 3 : 2;
    int boxRow = row ~/ boxSize;
    int boxCol = col ~/ boxSize;
    for (int r = boxRow * boxSize; r < (boxRow + 1) * boxSize; r++) {
      for (int c = boxCol * boxSize; c < (boxCol + 1) * boxSize; c++) {
        if (puzzle[r][c] != null) {
          candidates.remove(puzzle[r][c]);
        }
      }
    }
    return candidates;
  }

  void _onNumberDrop(int row, int col, int num) {
    if (gameOver || gameWon) return;
    if (fixed[row][col] || puzzle[row][col] != null) return;
    setState(() {
      history.add(_copyGrid(puzzle));
      puzzle[row][col] = num;
      if (num != solution[row][col]) {
        String key = '[$row,$col]';
        warningCells.add(key);
        mistakeFlash = true;
        _flashController?.forward();
        _playSound('assets/sounds/mistake.mp3');
        HapticFeedback.vibrate();
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            warningCells.remove(key);
            mistakeFlash = false;
          });
        });
      } else {
        _playSound('assets/sounds/correct.mp3');
        HapticFeedback.selectionClick();
        if (_isComplete()) {
          _onLevelComplete();
        }
      }
    });
  }

  // --- AI Hint System ---
  void _aiHint() async {
    print('AI Hint button pressed. Cooldown: ' + aiHintCooldown.toString());
    if (aiHintCooldown > Duration.zero) {
      print('AI Hint is on cooldown.');
      return;
    }
    final hint = getAIHint();
    print('AI Hint result: ' + hint.toString());
    if (hint != null) {
      setState(() {
        selectedRow = hint.row;
        selectedCol = hint.col;
      });
      final prefs = await SharedPreferences.getInstance();
      String aiHintKey = 'aiHintTime_${level ?? 0}';
      lastAIHintTime = DateTime.now();
      await prefs.setString(aiHintKey, lastAIHintTime!.toIso8601String());
      _updateAIHintCooldown();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Smart Hint'),
          content: Text(
            'Place ${hint.number} at row ${hint.row + 1}, col ${hint.col + 1}.'
            '\n\n${hint.explanation}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No advanced hints available. Try another move!'),
        ),
      );
    }
  }

  AIHint? getAIHint() {
    return _findNakedSingle() ??
        _findHiddenSingle() ??
        _findLockedCandidate() ??
        _findNakedPair();
  }

  // --- AI Hint Techniques ---
  AIHint? _findNakedSingle() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (puzzle[row][col] == null && !fixed[row][col]) {
          Set<int> candidates = _getCandidates(row, col);
          if (candidates.length == 1) {
            int num = candidates.first;
            return AIHint(
              row,
              col,
              num,
              'Naked Single: Only $num can go here.',
            );
          }
        }
      }
    }
    return null;
  }

  AIHint? _findHiddenSingle() {
    // Rows
    for (int row = 0; row < 9; row++) {
      for (int num = 1; num <= 9; num++) {
        List<int> possibleCols = [];
        for (int col = 0; col < 9; col++) {
          if (puzzle[row][col] == null &&
              !fixed[row][col] &&
              _getCandidates(row, col).contains(num)) {
            possibleCols.add(col);
          }
        }
        if (possibleCols.length == 1) {
          return AIHint(
            row,
            possibleCols[0],
            num,
            'Hidden Single: Only $num can go in row ${row + 1}.',
          );
        }
      }
    }
    // Columns
    for (int col = 0; col < 9; col++) {
      for (int num = 1; num <= 9; num++) {
        List<int> possibleRows = [];
        for (int row = 0; row < 9; row++) {
          if (puzzle[row][col] == null &&
              !fixed[row][col] &&
              _getCandidates(row, col).contains(num)) {
            possibleRows.add(row);
          }
        }
        if (possibleRows.length == 1) {
          return AIHint(
            possibleRows[0],
            col,
            num,
            'Hidden Single: Only $num can go in column ${col + 1}.',
          );
        }
      }
    }
    // Boxes
    for (int boxRow = 0; boxRow < 3; boxRow++) {
      for (int boxCol = 0; boxCol < 3; boxCol++) {
        for (int num = 1; num <= 9; num++) {
          List<List<int>> possibleCells = [];
          for (int r = boxRow * 3; r < boxRow * 3 + 3; r++) {
            for (int c = boxCol * 3; c < boxCol * 3 + 3; c++) {
              if (puzzle[r][c] == null &&
                  !fixed[r][c] &&
                  _getCandidates(r, c).contains(num)) {
                possibleCells.add([r, c]);
              }
            }
          }
          if (possibleCells.length == 1) {
            return AIHint(
              possibleCells[0][0],
              possibleCells[0][1],
              num,
              'Hidden Single: Only $num can go in this 3x3 box.',
            );
          }
        }
      }
    }
    return null;
  }

  AIHint? _findLockedCandidate() {
    final gridSize = puzzle.length;
    final boxSize = gridSize == 9 ? 3 : 2;
    for (int boxRow = 0; boxRow < gridSize ~/ boxSize; boxRow++) {
      for (int boxCol = 0; boxCol < gridSize ~/ boxSize; boxCol++) {
        for (int num = 1; num <= gridSize; num++) {
          List<List<int>> cells = [];
          for (int r = boxRow * boxSize; r < boxRow * boxSize + boxSize; r++) {
            for (
              int c = boxCol * boxSize;
              c < boxCol * boxSize + boxSize;
              c++
            ) {
              if (puzzle[r][c] == null &&
                  !fixed[r][c] &&
                  _getCandidates(r, c).contains(num)) {
                cells.add([r, c]);
              }
            }
          }
          if (cells.isNotEmpty) {
            bool sameRow = cells.every((cell) => cell[0] == cells[0][0]);
            bool sameCol = cells.every((cell) => cell[1] == cells[0][1]);
            if (sameRow) {
              for (int c = 0; c < gridSize; c++) {
                if (c < boxCol * boxSize || c >= boxCol * boxSize + boxSize) {
                  if (puzzle[cells[0][0]][c] == null &&
                      !fixed[cells[0][0]][c] &&
                      _getCandidates(cells[0][0], c).contains(num)) {
                    return AIHint(
                      cells[0][0],
                      c,
                      num,
                      'Locked Candidate: $num must be in row ${cells[0][0] + 1} of this box, so eliminate from other cells in the row.',
                    );
                  }
                }
              }
            }
            if (sameCol) {
              for (int r = 0; r < gridSize; r++) {
                if (r < boxRow * boxSize || r >= boxRow * boxSize + boxSize) {
                  if (puzzle[r][cells[0][1]] == null &&
                      !fixed[r][cells[0][1]] &&
                      _getCandidates(r, cells[0][1]).contains(num)) {
                    return AIHint(
                      r,
                      cells[0][1],
                      num,
                      'Locked Candidate: $num must be in column ${cells[0][1] + 1} of this box, so eliminate from other cells in the column.',
                    );
                  }
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  AIHint? _findNakedPair() {
    final gridSize = puzzle.length;
    for (int row = 0; row < gridSize; row++) {
      List<int> cells = [];
      List<Set<int>> candidatesList = [];
      for (int col = 0; col < gridSize; col++) {
        if (puzzle[row][col] == null && !fixed[row][col]) {
          Set<int> candidates = _getCandidates(row, col);
          if (candidates.length == 2) {
            cells.add(col);
            candidatesList.add(candidates);
          }
        }
      }
      for (int i = 0; i < cells.length; i++) {
        for (int j = i + 1; j < cells.length; j++) {
          if (candidatesList[i].containsAll(candidatesList[j]) &&
              candidatesList[j].containsAll(candidatesList[i])) {
            for (int col = 0; col < gridSize; col++) {
              if (col != cells[i] &&
                  col != cells[j] &&
                  puzzle[row][col] == null &&
                  !fixed[row][col]) {
                Set<int> candidates = _getCandidates(row, col);
                Set<int> pair = candidatesList[i];
                for (int num in pair) {
                  if (candidates.contains(num)) {
                    return AIHint(
                      row,
                      col,
                      num,
                      'Naked Pair: Cells at (${row + 1},${cells[i] + 1}) and (${row + 1},${cells[j] + 1}) form a naked pair, so $num can be eliminated from this cell.',
                    );
                  }
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  void _onLevelComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList('completedLevels') ?? [];
    if (!completed.contains('${level ?? 0}')) {
      completed.add('${level ?? 0}');
      await prefs.setStringList('completedLevels', completed);
    }
    showConfetti = true;
    _playSound('assets/sounds/win.mp3');
    HapticFeedback.heavyImpact();
    setState(() {
      gameWon = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        showConfetti = false;
      });
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Level Complete!'),
          content: const Text('Congratulations! You solved the puzzle.'),
          actions: [
            if ((level ?? 0) < 100)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                    context,
                    '/game',
                    arguments: (level ?? 0) + 1,
                  );
                },
                child: const Text('Next Level'),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/levels');
              },
              child: const Text('Back to Home'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridSize = puzzle.length;
    if (_lastScore != score) {
      _scorePopController.forward(from: 0.0);
      _lastScore = score;
    }
    if (_lastSeconds != seconds) {
      _timerPopController.forward(from: 0.0);
      _lastSeconds = seconds;
    }
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset('assets/bg_home.jpg', fit: BoxFit.cover),
            ),
            // Overlay for readability
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),
            AnimatedBuilder(
              animation: _shakeController!,
              builder: (context, child) {
                return child ?? const SizedBox.shrink();
              },
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.grid_4x4,
                              color: Colors.indigo,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Level ${level ?? 1}',
                              style: TextStyle(
                                color: Colors.indigo[900],
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.timer, color: Colors.indigo, size: 22),
                            const SizedBox(width: 4),
                            ScaleTransition(
                              scale: _timerPopAnim,
                              child: Text(
                                _formatTime(seconds),
                                style: TextStyle(
                                  color: Colors.indigo[900],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.star,
                              color: Colors.amber[700],
                              size: 22,
                            ),
                            const SizedBox(width: 4),
                            ScaleTransition(
                              scale: _scorePopAnim,
                              child: Text(
                                '$score',
                                style: TextStyle(
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Sudoku Grid
                  Expanded(
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _showContent ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                        child: AnimatedSlide(
                          offset: _showContent
                              ? Offset.zero
                              : const Offset(0, 0.1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[850] : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.indigo.withOpacity(0.10),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: _SudokuGrid(
                                puzzle: puzzle,
                                fixed: fixed,
                                selectedRow: selectedRow,
                                selectedCol: selectedCol,
                                cellColor: _cellColor,
                                onNumberDrop: _onNumberDrop,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          icon: Icons.undo,
                          label: 'Undo',
                          onTap: _undo,
                        ),
                        _ActionButton(
                          icon: Icons.psychology,
                          label: aiHintCooldown > Duration.zero
                              ? 'Smart Hint (' + _formatAIHintCooldown() + ')'
                              : 'Smart Hint',
                          onTap: aiHintCooldown > Duration.zero
                              ? () {
                                  _showCooldownDialog(
                                    aiHintCooldown,
                                    'Smart Hint available in',
                                  );
                                }
                              : _aiHint,
                        ),
                        _ActionButton(
                          icon: Icons.auto_fix_high,
                          label:
                              !_solveStepAvailable &&
                                  _solveStepRemaining != null
                              ? 'Solve Step (' +
                                    _formatCooldown(_solveStepRemaining) +
                                    ')'
                              : 'Solve Step',
                          onTap:
                              !_solveStepAvailable &&
                                  _solveStepRemaining != null
                              ? () {
                                  _showCooldownDialog(
                                    _solveStepRemaining!,
                                    'Solve Step available in',
                                  );
                                }
                              : _solveStep,
                        ),
                      ],
                    ),
                  ),
                  // Number Pad
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: AnimatedOpacity(
                      opacity: _showContent ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      child: AnimatedSlide(
                        offset: _showContent
                            ? Offset.zero
                            : const Offset(0, 0.1),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: List.generate(puzzle.length, (i) {
                            final num = i + 1;
                            return AnimatedScale(
                              scale: selectedNumber == num ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Draggable<int>(
                                data: num,
                                feedback: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.indigo[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$num',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$num',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () => _selectNumber(num),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: selectedNumber == num
                                          ? Colors.indigo[100]
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$num',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const BannerAdWidget(),
                ],
              ),
            ),
            // Confetti Animation
            if (showConfetti)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Lottie.asset(
                      'assets/confetti.json',
                      repeat: false,
                      width: 300,
                      height: 300,
                    ),
                  ),
                ),
              ),
            // Game Over Dialog
            if (gameOver)
              _GameDialog(
                title: 'Game Over',
                message: 'You made too many mistakes!',
                onRestart: () {
                  setState(() {
                    _generatePuzzle();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatCooldown(Duration? d) {
    if (d == null) return '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}';
    } else {
      return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}';
    }
  }

  String _formatAIHintCooldown() {
    if (aiHintCooldown <= Duration.zero) return '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final m = twoDigits(aiHintCooldown.inMinutes.remainder(60));
    final s = twoDigits(aiHintCooldown.inSeconds.remainder(60));
    return '$m:$s';
  }

  Future<void> _playSound(String asset) async {
    try {
      print('Attempting to play sound: ' + asset);
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(asset));
    } catch (e) {
      print('Error playing sound: ' + e.toString());
    }
  }
}

class _SudokuGrid extends StatelessWidget {
  final List<List<int?>> puzzle;
  final List<List<bool>> fixed;
  final int? selectedRow;
  final int? selectedCol;
  final Color? Function(int, int) cellColor;
  final void Function(int, int, int) onNumberDrop;
  const _SudokuGrid({
    required this.puzzle,
    required this.fixed,
    required this.selectedRow,
    required this.selectedCol,
    required this.cellColor,
    required this.onNumberDrop,
  });

  @override
  Widget build(BuildContext context) {
    final gridSize = puzzle.length;
    final boxSize = gridSize == 9 ? 3 : 2;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.indigo, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(gridSize, (row) {
          return Expanded(
            child: Row(
              children: List.generate(gridSize, (col) {
                return Expanded(
                  child: DragTarget<int>(
                    builder: (context, candidateData, rejectedData) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.only(
                          left: col % boxSize == 0 ? 2 : 0,
                          top: row % boxSize == 0 ? 2 : 0,
                          right: (col + 1) % boxSize == 0 ? 2 : 0,
                          bottom: (row + 1) % boxSize == 0 ? 2 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: cellColor(row, col),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: puzzle[row][col] != null
                            ? Text(
                                '${puzzle[row][col]}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: fixed[row][col]
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: fixed[row][col]
                                      ? Colors.indigo[900]
                                      : Colors.indigo[400],
                                ),
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                    onWillAcceptWithDetails: (data) {
                      return !fixed[row][col] && puzzle[row][col] == null;
                    },
                    onAcceptWithDetails: (num) {
                      onNumberDrop(row, col, num.data);
                    },
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.indigo),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.indigo,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _GameDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRestart;
  const _GameDialog({
    required this.title,
    required this.message,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(message, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onRestart,
                    child: const Text('Restart'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AIHint {
  final int row;
  final int col;
  final int number;
  final String explanation;
  AIHint(this.row, this.col, this.number, this.explanation);
}
