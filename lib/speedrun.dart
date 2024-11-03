import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MathQuestion {
  final String question;
  final int correctAnswer;
  final List<int> options;
  bool isAnswered;
  bool isCorrect;

  MathQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
    this.isAnswered = false,
    this.isCorrect = false,
  });
}

class MathBlast extends StatefulWidget {
  const MathBlast({Key? key}) : super(key: key);

  @override
  State<MathBlast> createState() => _MathBlastState();
}

class _MathBlastState extends State<MathBlast> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late Timer _gameTimer;
  late MathQuestion currentQuestion;

  int score = 0;
  int level = 1;
  int combo = 0;
  double timeLeft = 30.0;
  bool isGameOver = false;
  String? username;

  bool hasTimeBoost = true;
  bool hasSkip = true;
  bool has5050 = true;

  int correctAnswers = 0;
  int totalQuestions = 0;

  static const String apiUrl = 'https://appledeveloper.com.tr/tablo/app2.php';

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _initializeUser();
    generateQuestion();
    startTimer();
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username');
  }

  void generateQuestion() {
    int num1, num2, answer;
    String operator;
    List<int> options = [];

    // Seviyeye göre zorluk ayarla
    if (level <= 3) {
      // Toplama ve çıkarma, küçük sayılar
      num1 = math.Random().nextInt(10) + 1;
      num2 = math.Random().nextInt(10) + 1;
      operator = math.Random().nextBool() ? '+' : '-';

      if (operator == '+') {
        answer = num1 + num2;
      } else {
        // Negatif sonuç olmamasını sağla
        if (num1 < num2) {
          int temp = num1;
          num1 = num2;
          num2 = temp;
        }
        answer = num1 - num2;
      }
    } else if (level <= 6) {
      // Çarpma ve kolay bölme ekle
      int operation = math.Random().nextInt(3);
      switch (operation) {
        case 0: // Toplama
          num1 = math.Random().nextInt(20) + 1;
          num2 = math.Random().nextInt(20) + 1;
          operator = '+';
          answer = num1 + num2;
          break;
        case 1: // Çıkarma
          num1 = math.Random().nextInt(30) + 20;
          num2 = math.Random().nextInt(20) + 1;
          operator = '-';
          answer = num1 - num2;
          break;
        case 2: // Çarpma
          num1 = math.Random().nextInt(10) + 1;
          num2 = math.Random().nextInt(5) + 1;
          operator = '×';
          answer = num1 * num2;
          break;
        default:
          num1 = num2 = 0;
          operator = '+';
          answer = 0;
      }
    } else {
      // Tüm operatörler, daha büyük sayılar
      int operation = math.Random().nextInt(4);
      switch (operation) {
        case 0: // Toplama
          num1 = math.Random().nextInt(50) + 1;
          num2 = math.Random().nextInt(50) + 1;
          operator = '+';
          answer = num1 + num2;
          break;
        case 1: // Çıkarma
          num1 = math.Random().nextInt(100) + 1;
          num2 = math.Random().nextInt(50) + 1;
          operator = '-';
          answer = num1 - num2;
          break;
        case 2: // Çarpma
          num1 = math.Random().nextInt(12) + 1;
          num2 = math.Random().nextInt(8) + 1;
          operator = '×';
          answer = num1 * num2;
          break;
        case 3: // Bölme
          // Tam bölünebilir sayılar üret
          num2 = math.Random().nextInt(10) + 1;
          answer = math.Random().nextInt(10) + 1;
          num1 = num2 * answer;
          operator = '÷';
          break;
        default:
          num1 = num2 = 0;
          operator = '+';
          answer = 0;
      }
    }

    // Yanlış cevap seçenekleri üret
    options.add(answer); // Doğru cevap
    while (options.length < 4) {
      int wrong;
      if (level <= 3) {
        wrong = answer + (math.Random().nextInt(5) - 2);
      } else if (level <= 6) {
        wrong = answer + (math.Random().nextInt(11) - 5);
      } else {
        wrong = answer + (math.Random().nextInt(21) - 10);
      }

      if (wrong != answer && wrong >= 0 && !options.contains(wrong)) {
        options.add(wrong);
      }
    }

    // Seçenekleri karıştır
    options.shuffle();

    currentQuestion = MathQuestion(
      question: '$num1 $operator $num2 = ?',
      correctAnswer: answer,
      options: options,
    );
  }

  void checkAnswer(int answer) {
    if (currentQuestion.isAnswered) return;

    setState(() {
      currentQuestion.isAnswered = true;
      currentQuestion.isCorrect = answer == currentQuestion.correctAnswer;
      totalQuestions++;

      if (currentQuestion.isCorrect) {
        correctAnswers++;
        combo++;

        // Combo bonus
        int points = 10;
        if (combo >= 3) points = 20;
        if (combo >= 5) points = 30;
        if (combo >= 10) points = 50;

        score += points;

        // Seviye atla
        if (correctAnswers % 5 == 0) {
          level++;
          timeLeft = math.min(30.0, timeLeft + 5); // Bonus süre
        }
      } else {
        combo = 0;
      }

      // Kısa bir gecikme ile yeni soru
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !isGameOver) {
          generateQuestion();
        }
      });
    });
  }

  void startTimer() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        timeLeft -= 0.1;
        if (timeLeft <= 0) {
          gameOver();
        }
      });
    });
  }

  void gameOver() {
    _gameTimer.cancel();
    isGameOver = true;
    _saveScore();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Game Over!',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $score\nLevel: $level\nCorrect: $correctAnswers/$totalQuestions',
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
            child: const Text(
              'Play Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveScore() async {
    if (username == null) return;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: json.encode({
          'action': 'add_score',
          'username': username,
          'game_type': 'math_blast',
          'score': score.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        print('Error saving score: ${response.body}');
      }
    } catch (e) {
      print('Error saving score: $e');
    }
  }

  void resetGame() {
    setState(() {
      score = 0;
      level = 1;
      combo = 0;
      timeLeft = 30.0;
      isGameOver = false;
      correctAnswers = 0;
      totalQuestions = 0;
      hasTimeBoost = true;
      hasSkip = true;
      has5050 = true;
      generateQuestion();
      startTimer();
    });
  }

  void use5050() {
    if (!has5050 || currentQuestion.isAnswered) return;

    setState(() {
      has5050 = false;

      // İki yanlış cevabı kaldır
      List<int> wrongAnswers = [];
      for (int option in currentQuestion.options) {
        if (option != currentQuestion.correctAnswer) {
          wrongAnswers.add(option);
        }
      }

      wrongAnswers.shuffle();
      for (int i = 0; i < 2; i++) {
        int index = currentQuestion.options.indexOf(wrongAnswers[i]);
        currentQuestion.options[index] = -1; // Gizlenmş seçenek
      }
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _gameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Image.asset(
            'assets/bg.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
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
                    ],
                    transform:
                        GradientRotation(_bgController.value * 2 * math.pi),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                _buildQuestion(),
                const Spacer(),
                _buildAnswerOptions(),
                _buildPowerups(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Level $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (combo >= 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'COMBO x$combo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                'Score: $score',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  timeLeft <= 5 ? Colors.red.withOpacity(0.8) : Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  color: timeLeft <= 5 ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  timeLeft.toStringAsFixed(1),
                  style: TextStyle(
                    color: timeLeft <= 5 ? Colors.white : Colors.white70,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            currentQuestion.isAnswered
                ? (currentQuestion.isCorrect ? 'Correct!' : 'Wrong!')
                : 'Solve It!',
            style: TextStyle(
              color: currentQuestion.isAnswered
                  ? (currentQuestion.isCorrect ? Colors.green : Colors.red)
                  : Colors.white70,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            currentQuestion.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              _buildAnswerButton(currentQuestion.options[0], 0),
              const SizedBox(width: 12),
              _buildAnswerButton(currentQuestion.options[1], 1),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAnswerButton(currentQuestion.options[2], 2),
              const SizedBox(width: 12),
              _buildAnswerButton(currentQuestion.options[3], 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(int answer, int index) {
    bool isCorrect = answer == currentQuestion.correctAnswer;
    bool showResult = currentQuestion.isAnswered;
    bool isHidden = answer == -1; // 50/50 powerup ile gizlenmiş

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!currentQuestion.isAnswered && !isHidden) {
            checkAnswer(answer);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                if (isHidden)
                  Colors.grey.shade800
                else if (showResult && isCorrect)
                  Colors.green.shade700
                else if (showResult && !isCorrect)
                  Colors.red.shade700
                else
                  Colors.purple.shade700,
                if (isHidden)
                  Colors.grey.shade900
                else if (showResult && isCorrect)
                  Colors.green.shade900
                else if (showResult && !isCorrect)
                  Colors.red.shade900
                else
                  Colors.purple.shade900,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (showResult && isCorrect)
                    ? Colors.green.withOpacity(0.5)
                    : Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              isHidden ? '?' : answer.toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(isHidden ? 0.5 : 1.0),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPowerups() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPowerupButton(
            'Time +5',
            Icons.timer,
            hasTimeBoost,
            () {
              if (hasTimeBoost) {
                setState(() {
                  hasTimeBoost = false;
                  timeLeft = math.min(30.0, timeLeft + 5);
                });
              }
            },
          ),
          _buildPowerupButton(
            'Skip',
            Icons.skip_next,
            hasSkip,
            () {
              if (hasSkip) {
                setState(() {
                  hasSkip = false;
                  generateQuestion();
                });
              }
            },
          ),
          _buildPowerupButton(
            '50/50',
            Icons.remove_circle_outline,
            has5050,
            () {
              if (has5050) {
                use5050();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPowerupButton(
    String label,
    IconData icon,
    bool isAvailable,
    VoidCallback onTap,
  ) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isAvailable ? onTap : null,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
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
