import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shufflepuzzle_game/homegame.dart';

class MathSlotGame extends StatefulWidget {
  const MathSlotGame({Key? key}) : super(key: key);

  @override
  State<MathSlotGame> createState() => _MathSlotGameState();
}

class _MathSlotGameState extends State<MathSlotGame>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _spinController;
  late final AnimationController _bounceController;
  late final AnimationController _shakeController;

  final List<String> _symbols = ['🎲', '🎮', '🎯', '⭐️', '🌟', '💫'];
  List<int> _currentSymbols = [0, 0, 0];
  bool _isSpinning = false;
  int _score = 0;
  int _streak = 0;
  int _level = 1;
  bool _showMathProblem = false;
  String _mathProblem = '';
  int _correctAnswer = 0;
  List<int> _answerOptions = [];
  int? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
  Timer? _spinTimer;

  Map<int, Map<String, dynamic>> _levelSettings = {
    1: {
      'maxNumber': 10,
      'operations': ['+'],
      'symbols': 3,
      'pointsToNext': 3,
      'questionTime': 20,
    },
    2: {
      'maxNumber': 20,
      'operations': ['+', '-'],
      'symbols': 4,
      'pointsToNext': 5,
      'questionTime': 15,
    },
    3: {
      'maxNumber': 50,
      'operations': ['+', '-', '×'],
      'symbols': 5,
      'pointsToNext': 8,
      'questionTime': 12,
    },
    4: {
      'maxNumber': 100,
      'operations': ['+', '-', '×', '÷'],
      'symbols': 6,
      'pointsToNext': 10,
      'questionTime': 10,
    },
    5: {
      'maxNumber': 100,
      'operations': ['+', '-', '×', '÷', '^'],
      'symbols': 6,
      'pointsToNext': 15,
      'questionTime': 8,
    }
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _generateRandomSymbols();
  }

  void _initializeControllers() {
    _bgController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _spinController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _generateRandomSymbols() {
    final random = math.Random();
    final settings = _levelSettings[_level];
    final symbolCount = settings?['symbols'] ?? 3;

    for (int i = 0; i < _currentSymbols.length; i++) {
      _currentSymbols[i] = random.nextInt(symbolCount);
    }
  }

  void _spin() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _showResult = false;
      _selectedAnswer = null;
    });

    _spinController.reset();
    _spinController.forward();

    int spinCount = 0;
    _spinTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _generateRandomSymbols();
      });

      spinCount++;
      if (spinCount >= 20) {
        timer.cancel();
        _checkWinAndShowMath();
      }
    });
  }

  void _checkWinAndShowMath() {
    bool hasMatch = _currentSymbols[0] == _currentSymbols[1] ||
        _currentSymbols[1] == _currentSymbols[2] ||
        _currentSymbols[0] == _currentSymbols[2];

    if (hasMatch) {
      _generateMathProblem();
      setState(() {
        _showMathProblem = true;
        _isSpinning = false;
      });
    } else {
      setState(() {
        _isSpinning = false;
      });
    }
  }

  void _generateAnswerOptions() {
    final random = math.Random();
    _answerOptions = [_correctAnswer];

    while (_answerOptions.length < 4) {
      // Minimum offset değeri belirleme
      int minOffset = 1;
      // Maximum offset değeri belirleme
      int maxOffset = math.max(_correctAnswer ~/ 2, 5);

      // Offset hesaplama
      int offset = random.nextInt(maxOffset) + minOffset;

      // Yanlış cevap oluşturma
      int wrongAnswer;
      if (random.nextBool()) {
        wrongAnswer = _correctAnswer + offset;
      } else {
        wrongAnswer = _correctAnswer - offset;
        // Negatif sayıları önleme
        if (wrongAnswer < 0) {
          wrongAnswer = _correctAnswer + offset;
        }
      }

      // Eğer cevap daha önce eklenmemişse listeye ekle
      if (!_answerOptions.contains(wrongAnswer)) {
        _answerOptions.add(wrongAnswer);
      }
    }

    // Cevapları karıştır
    _answerOptions.shuffle();
  }

  void _generateMathProblem() {
    final random = math.Random();
    final settings = _levelSettings[_level] ?? _levelSettings[1];
    final operations = settings?['operations'] as List<String>;
    final maxNumber = settings?['maxNumber'] as int;
    final operation = operations[random.nextInt(operations.length)];

    int num1 = random.nextInt(maxNumber) + 1;
    int num2 = random.nextInt(maxNumber) + 1;

    // Sayıları düzenleme
    if (operation == '-' || operation == '÷') {
      // Çıkarma ve bölme için ilk sayının daha büyük olmasını sağla
      if (num1 < num2) {
        int temp = num1;
        num1 = num2;
        num2 = temp;
      }
    }

    // Bölme işlemi için tam bölünebilir sayılar üret
    if (operation == '÷') {
      num1 = (num1 * num2).clamp(1, maxNumber);
    }

    switch (operation) {
      case '+':
        _correctAnswer = num1 + num2;
        _mathProblem = '$num1 + $num2 = ?';
        break;
      case '-':
        _correctAnswer = num1 - num2;
        _mathProblem = '$num1 - $num2 = ?';
        break;
      case '×':
        while (num1 * num2 > maxNumber) {
          num1 = random.nextInt(maxNumber ~/ 2) + 1;
          num2 = random.nextInt(maxNumber ~/ 2) + 1;
        }
        _correctAnswer = num1 * num2;
        _mathProblem = '$num1 × $num2 = ?';
        break;
      case '÷':
        _correctAnswer = num1 ~/ num2;
        _mathProblem = '$num1 ÷ $num2 = ?';
        break;
      case '^':
        num2 = random.nextInt(2) + 2; // 2 veya 3 üssü
        while (math.pow(num1, num2) > maxNumber) {
          num1 = random.nextInt(maxNumber ~/ 4) + 1;
        }
        _correctAnswer = math.pow(num1, num2).toInt();
        _mathProblem = '$num1^$num2 = ?';
        break;
    }

    _generateAnswerOptions();
  }

  void _checkAnswer(int answer) {
    if (_selectedAnswer != null) return;

    setState(() {
      _selectedAnswer = answer;
      _showResult = true;
      _isCorrect = answer == _correctAnswer;

      if (_isCorrect) {
        _score++;
        _streak++;
        _checkLevelProgress();
      } else {
        _streak = 0;
      }
    });

    if (_isCorrect) {
      _showSuccessDialog();
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showMathProblem = false;
            _showResult = false;
            _selectedAnswer = null;
          });
        }
      });
    }
  }

  void _checkLevelProgress() {
    final settings = _levelSettings[_level];
    final pointsNeeded = settings?['pointsToNext'] ?? 5;

    if (_score >= pointsNeeded && _level < 5) {
      _showLevelUpDialog();
    }
  }

  // Skor hesaplama metodu
  int _calculateScore() {
    // Seviye bazlı bonus
    int levelBonus = _level * 1000;
    // Streak bonus
    int streakBonus = _streak * 100;
    // Temel puan
    int baseScore = _score * 500;

    return baseScore + levelBonus + streakBonus;
  }

// Skor gönderme metodu
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
            'game_type': 'spin',
            'score': score,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      print('Error submitting score: $e');
    }
  }

  void _showSuccessDialog() {
    int finalScore = _calculateScore();

    // Skoru gönder
    _submitScore(finalScore);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '🎉 Congratulations!',
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
            Text(
              'Correct Answer!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            if (_streak > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Streak: $_streak',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showMathProblem = false;
                _showResult = false;
                _selectedAnswer = null;
              });
            },
            child: const Text(
              'Spin Again',
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

  void _showLevelUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '🌟 Level Up!',
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
            Text(
              'Advancing to Level ${_level + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'New challenges await!',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _level++;
                _score = 0;
              });
            },
            child: const Text(
              'Continue',
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

  @override
  void dispose() {
    _bgController.dispose();
    _spinController.dispose();
    _bounceController.dispose();
    _shakeController.dispose();
    _spinTimer?.cancel();
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
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                _buildSlotMachine(),
                if (_showMathProblem) _buildMathProblem(),
                const Spacer(),
                _buildSpinButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final settings = _levelSettings[_level];
    final pointsNeeded = settings?['pointsToNext'] ?? 5;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $_level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_streak > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Streak: $_streak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _score / pointsNeeded,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor()),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Score: $_score / $pointsNeeded',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotMachine() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white24,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < _currentSymbols.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            _buildSlotReel(i),
          ],
        ],
      ),
    );
  }

  Widget _buildSlotReel(int index) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white24,
          width: 2,
        ),
      ),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: _isSpinning ? 48 : 40,
          ),
          child: Text(_symbols[_currentSymbols[index]]),
        ),
      ),
    );
  }

  Widget _buildMathProblem() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            _mathProblem,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _answerOptions.map((answer) {
              bool isSelected = _selectedAnswer == answer;
              bool showResult = _showResult && isSelected;
              Color buttonColor = showResult
                  ? (answer == _correctAnswer ? Colors.green : Colors.red)
                  : Colors.blue;

              return ElevatedButton(
                onPressed: _showResult ? null : () => _checkAnswer(answer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  answer.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinButton() {
    return GestureDetector(
      onTap: _isSpinning || _showMathProblem ? null : _spin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _isSpinning || _showMathProblem
                  ? Colors.grey.shade400
                  : Colors.blue.shade400,
              _isSpinning || _showMathProblem
                  ? Colors.grey.shade600
                  : Colors.purple.shade400,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5),
              blurRadius: _isSpinning ? 20 : 10,
              spreadRadius: _isSpinning ? 2 : 1,
            ),
          ],
        ),
        child: Center(
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 300),
            turns: _spinController.value,
            child: Icon(
              Icons.refresh,
              color: Colors.white,
              size: _isSpinning ? 48 : 40,
            ),
          ),
        ),
      ),
    );
  }

  Color _getLevelColor() {
    switch (_level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/bg.jpg'), context);
  }
}
