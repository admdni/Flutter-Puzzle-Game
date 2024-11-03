import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

import 'homegame.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SudokuPuzzle extends StatefulWidget {
  const SudokuPuzzle({Key? key}) : super(key: key);

  @override
  State<SudokuPuzzle> createState() => _SudokuPuzzleState();
}

class _SudokuPuzzleState extends State<SudokuPuzzle>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late List<List<int>> _board;
  late List<List<int>> _solution;
  late List<List<bool>> _isFixed;
  late List<List<Set<int>>> _notes;
  int _selectedRow = -1;
  int _selectedCol = -1;
  bool _isNoteModeActive = false;
  int _mistakes = 0;
  int _hintsRemaining = 3;
  Timer? _timer;
  int _seconds = 0;
  String _difficulty = 'Medium';
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    _initializeGame();
    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialDialog();
    });
  }

  void _initializeGame() {
    _solution = _generateSolvedSudoku();
    _board = List.generate(9, (i) => List.generate(9, (j) => _solution[i][j]));
    _removeNumbers();
    _isFixed = List.generate(
      9,
      (i) => List.generate(9, (j) => _board[i][j] != 0),
    );
    _notes = List.generate(
      9,
      (i) => List.generate(9, (j) => <int>{}),
    );
    _mistakes = 0;
    _hintsRemaining = 3;
    _seconds = 0;
    _isCompleted = false;
  }

  List<List<int>> _generateSolvedSudoku() {
    // Bu örnek için basit bir çözülmüş Sudoku board'u döndürüyoruz
    // Gerçek uygulamada backtracking algoritması ile rastgele board üretilmeli
    return [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9]
    ];
  }

  void _removeNumbers() {
    final random = math.Random();
    int numbersToRemove;

    switch (_difficulty) {
      case 'Easy':
        numbersToRemove = 40;
        break;
      case 'Medium':
        numbersToRemove = 50;
        break;
      case 'Hard':
        numbersToRemove = 60;
        break;
      default:
        numbersToRemove = 50;
    }

    while (numbersToRemove > 0) {
      int row = random.nextInt(9);
      int col = random.nextInt(9);
      if (_board[row][col] != 0) {
        _board[row][col] = 0;
        numbersToRemove--;
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isCompleted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _handleNumberInput(int number) {
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_isFixed[_selectedRow][_selectedCol]) return;

    setState(() {
      if (_isNoteModeActive) {
        if (_notes[_selectedRow][_selectedCol].contains(number)) {
          _notes[_selectedRow][_selectedCol].remove(number);
        } else {
          _notes[_selectedRow][_selectedCol].add(number);
        }
      } else {
        _notes[_selectedRow][_selectedCol].clear();
        if (_board[_selectedRow][_selectedCol] == number) {
          _board[_selectedRow][_selectedCol] = 0;
        } else {
          _board[_selectedRow][_selectedCol] = number;
          if (_solution[_selectedRow][_selectedCol] != number) {
            _mistakes++;
            if (_mistakes >= 3) {
              _showGameOverDialog();
            }
          }
          _checkCompletion();
        }
      }
    });
  }

  void _useHint() {
    if (_hintsRemaining <= 0 || _selectedRow == -1 || _selectedCol == -1)
      return;
    if (_isFixed[_selectedRow][_selectedCol]) return;

    setState(() {
      _board[_selectedRow][_selectedCol] =
          _solution[_selectedRow][_selectedCol];
      _isFixed[_selectedRow][_selectedCol] = true;
      _hintsRemaining--;
      _checkCompletion();
    });
  }

  void _checkCompletion() {
    bool isComplete = true;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_board[i][j] != _solution[i][j]) {
          isComplete = false;
          break;
        }
      }
    }
    if (isComplete) {
      _isCompleted = true;
      _timer?.cancel();
      _showWinDialog();
    }
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'How to Play Sudoku',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTutorialStep(
              '1',
              'Fill each row, column, and 3x3 box with numbers 1-9',
              Icons.grid_on,
            ),
            const SizedBox(height: 16),
            _buildTutorialStep(
              '2',
              'Use notes mode to write possible numbers',
              Icons.edit_note,
            ),
            const SizedBox(height: 16),
            _buildTutorialStep(
              '3',
              'Use hints wisely - you only have three!',
              Icons.lightbulb_outline,
            ),
            const SizedBox(height: 16),
            _buildTutorialStep(
              '4',
              'Avoid mistakes - three strikes and you\'re out!',
              Icons.warning_amber,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep(String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '😔 Game Over',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'You made 3 mistakes!\nTime played: ${_formatTime(_seconds)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _initializeGame();
                _startTimer();
              });
            },
            child: const Text(
              'Try Again',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateScore() {
    // Örnek skor hesaplama:
    // Temel puan: 10000
    // Her hata için -1000 puan
    // Her saniye için -5 puan
    int baseScore = 10000;
    int mistakePenalty = _mistakes * 1000;
    int timePenalty = _seconds * 5;

    return baseScore - mistakePenalty - timePenalty;
  }

// Skoru gönderme metodu ekleyin
  Future<void> _submitScore(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      if (username != null) {
        final response = await http.post(
          Uri.parse('https://appledeveloper.com.tr/tablo/app2.php'),
          body: json.encode({
            'action': 'add_score',
            'username': username,
            'game_type': 'sudoku',
            'score': score,
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          print('Score submitted successfully');
        }
      }
    } catch (e) {
      print('Error submitting score: $e');
    }
  }

  void _showWinDialog() {
    int score = _calculateScore();

    // Skoru gönder
    _submitScore(score);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '🎉 Puzzle Complete!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Mistakes: $_mistakes\nTime: ${_formatTime(_seconds)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _initializeGame();
                _startTimer();
              });
            },
            child: const Text(
              'Next Puzzle',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _bgController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Şeffaf renk.
        elevation: 0, // Gölgeyi kaldırır.
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Colors.white), // Geri dönme ikonu.
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      BrainTeasersHome()), // GoldenAceHome sayfasına git
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Background
          Image.asset(
            'assets/bg.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          // Animated overlay
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.3),
                      Colors.purple.withOpacity(0.3),
                      Colors.indigo.withOpacity(0.3),
                    ],
                    transform:
                        GradientRotation(_bgController.value * 2 * math.pi),
                  ),
                ),
              );
            },
          ),
          // Game content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeader(),
                        _buildSudokuGrid(),
                        _buildNumberPad(),
                        _buildControls(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _difficulty,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mistakes: $_mistakes/3',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatTime(_seconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSudokuGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(8),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            ),
            itemCount: 81,
            itemBuilder: (context, index) {
              final row = index ~/ 9;
              final col = index % 9;
              return _buildCell(row, col);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final isSelected = row == _selectedRow && col == _selectedCol;
    final isFixed = _isFixed[row][col];
    final value = _board[row][col];
    final notes = _notes[row][col];
    final isRelated = _selectedRow != -1 &&
        _selectedCol != -1 &&
        (row == _selectedRow ||
            col == _selectedCol ||
            (row ~/ 3 == _selectedRow ~/ 3 && col ~/ 3 == _selectedCol ~/ 3));

    final borderTop = row % 3 == 0 ? 2.0 : 0.5;
    final borderBottom = row % 3 == 2 ? 2.0 : 0.5;
    final borderLeft = col % 3 == 0 ? 2.0 : 0.5;
    final borderRight = col % 3 == 2 ? 2.0 : 0.5;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRow = row;
          _selectedCol = col;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withOpacity(0.3)
              : isRelated
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.white.withOpacity(0.1),
          border: Border(
            top: BorderSide(
                color: Colors.white.withOpacity(0.3), width: borderTop),
            bottom: BorderSide(
                color: Colors.white.withOpacity(0.3), width: borderBottom),
            left: BorderSide(
                color: Colors.white.withOpacity(0.3), width: borderLeft),
            right: BorderSide(
                color: Colors.white.withOpacity(0.3), width: borderRight),
          ),
        ),
        child: value != 0
            ? Center(
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    color: isFixed ? Colors.white : Colors.blue.shade200,
                    fontSize: 24,
                    fontWeight: isFixed ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              )
            : notes.isEmpty
                ? null
                : GridView.count(
                    crossAxisCount: 3,
                    padding: const EdgeInsets.all(2),
                    children: List.generate(9, (index) {
                      final number = index + 1;
                      return Center(
                        child: notes.contains(number)
                            ? Text(
                                number.toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              )
                            : null,
                      );
                    }),
                  ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return _buildNumberButton(index + 1);
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return _buildNumberButton(index + 6);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    return Material(
      color: Colors.black26,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _handleNumberInput(number),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          child: Text(
            number.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildControlButton(
              Icons.edit_note,
              'Notes',
              _isNoteModeActive ? Colors.blue : Colors.black26,
              () {
                setState(() {
                  _isNoteModeActive = !_isNoteModeActive;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildControlButton(
              Icons.lightbulb_outline,
              'Hint',
              Colors.black26,
              _useHint,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildControlButton(
              Icons.refresh,
              'Reset',
              Colors.black26,
              () {
                setState(() {
                  _initializeGame();
                  _startTimer();
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildControlButton(
              Icons.home,
              'Exit',
              Colors.black26,
              () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
