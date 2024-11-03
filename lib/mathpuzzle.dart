import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

import 'package:shufflepuzzle_game/homegame.dart';

class MathPuzzle extends StatefulWidget {
  const MathPuzzle({Key? key}) : super(key: key);

  @override
  State<MathPuzzle> createState() => _MathPuzzleState();
}

class _MathPuzzleState extends State<MathPuzzle> with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _cardController;
  late List<NumberCard> _cards;
  late int _targetNumber;
  String _currentExpression = '';
  int _currentResult = 0;
  int _moves = 0;
  int _currentLevel = 1;
  int _score = 0;
  Timer? _timer;
  int _seconds = 0;
  int _hintsRemaining = 3;
  int _powerups = 3;
  int _combo = 0;
  bool _isCompleted = false;
  List<String> _history = [];
  List<Achievement> _achievements = [];
  String _difficulty = 'Normal';

  final List<String> _operators = ['+', '-', '×', '÷'];
  String? _selectedOperator;
  NumberCard? _selectedCard;

  // Animation controllers
  late final AnimationController _shakeController;
  late final AnimationController _pulseController;
  late final Animation<Offset> _shakeAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeGame();
    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialDialog();
    });
  }

  void _initializeControllers() {
    _bgController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _shakeAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.1, 0),
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeGame() {
    int cardCount = math.min(6 + (_currentLevel ~/ 2), 8);
    _cards = _generateCards(cardCount);
    _targetNumber = _generateTarget();
    _currentExpression = '';
    _currentResult = 0;
    _moves = 0;
    _combo = 0;
    _selectedOperator = null;
    _selectedCard = null;
    _history.clear();
    _isCompleted = false;
    _seconds = 0;
  }

  List<NumberCard> _generateCards(int count) {
    final random = math.Random();
    final maxNumber = _calculateMaxNumber();
    List<NumberCard> cards = [];

    for (int i = 0; i < count; i++) {
      int value = random.nextInt(maxNumber) + 1;
      cards.add(NumberCard(
        value: value,
        type: _determineCardType(value),
      ));
    }

    return cards;
  }

  int _calculateMaxNumber() {
    if (_currentLevel <= 3) return 10;
    if (_currentLevel <= 5) return 20;
    if (_currentLevel <= 8) return 50;
    return 99;
  }

  CardType _determineCardType(int value) {
    if (_isPrime(value)) return CardType.prime;
    if (_isSquare(value)) return CardType.square;
    return CardType.normal;
  }

  bool _isPrime(int n) {
    if (n <= 1) return false;
    for (int i = 2; i <= n ~/ 2; i++) {
      if (n % i == 0) return false;
    }
    return true;
  }

  bool _isSquare(int n) {
    int root = math.sqrt(n).toInt();
    return root * root == n;
  }

  int _generateTarget() {
    final random = math.Random();
    if (_currentLevel <= 3) return random.nextInt(30) + 10;
    if (_currentLevel <= 5) return random.nextInt(50) + 20;
    if (_currentLevel <= 8) return random.nextInt(100) + 30;
    return random.nextInt(200) + 50;
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

  void _handleCardTap(NumberCard card) {
    if (card.isUsed || _isCompleted) return;

    setState(() {
      if (_selectedCard == null) {
        _selectedCard = card;
        _currentExpression = card.value.toString();
      } else if (_selectedOperator != null) {
        final result = _calculateResult(_selectedCard!.value, card.value);
        if (result != null) {
          _processValidMove(result, card);
        } else {
          _handleInvalidMove();
        }
      }
    });
  }

  int? _calculateResult(int num1, int num2) {
    switch (_selectedOperator) {
      case '+':
        return num1 + num2;
      case '-':
        return num1 - num2;
      case '×':
        return num1 * num2;
      case '÷':
        if (num2 == 0 || num1 % num2 != 0) return null;
        return num1 ~/ num2;
      default:
        return null;
    }
  }

  void _processValidMove(int result, NumberCard card) {
    _moves++;
    _selectedCard!.isUsed = true;
    card.isUsed = true;

    if (_isGoodMove(result)) {
      _combo++;
      _score += _combo * 10;
    } else {
      _combo = 0;
    }

    _cards.add(NumberCard(
      value: result,
      type: _determineCardType(result),
    ));

    _history
        .add('$_currentExpression $_selectedOperator ${card.value} = $result');
    _currentExpression = result.toString();
    _currentResult = result;

    if (_currentResult == _targetNumber) {
      _handleSuccess();
    }

    _selectedCard = null;
    _selectedOperator = null;
  }

  bool _isGoodMove(int result) {
    return result == _targetNumber || _isPrime(result) || _isSquare(result);
  }

  void _handleInvalidMove() {
    _shakeController.forward().then((_) => _shakeController.reverse());
    _combo = 0;
    _score = math.max(0, _score - 5);
  }

  void _handleSuccess() {
    _isCompleted = true;
    _timer?.cancel();

    int timeBonus = math.max(0, (300 - _seconds) * 2);
    int moveBonus = math.max(0, (20 - _moves) * 10);
    _score += timeBonus + moveBonus;

    _showWinDialog();
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
          'How to Play',
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
              'Select numbers and use operators to reach the target',
              Icons.calculate,
            ),
            const SizedBox(height: 16),
            _buildTutorialStep(
              '2',
              'Prime and square numbers give bonus points',
              Icons.star,
            ),
            const SizedBox(height: 16),
            _buildTutorialStep(
              '3',
              'Complete levels to unlock new challenges',
              Icons.trending_up,
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

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '🎉 Level Complete!',
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
              'Score: $_score\nMoves: $_moves\nTime: ${_formatTime(_seconds)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentLevel++;
                _initializeGame();
                _startTimer();
              });
            },
            child: const Text(
              'Next Level',
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
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
            child: Column(
              children: [
                _buildHeader(),
                _buildTargetArea(),
                const Spacer(),
                _buildGameBoard(),
                _buildOperators(),
                _buildControls(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level $_currentLevel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Score: $_score',
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

  Widget _buildTargetArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text(
                'TARGET',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Text(
                _targetNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            width: 2,
            height: 50,
            color: Colors.white24,
          ),
          Column(
            children: [
              const Text(
                'CURRENT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Text(
                _currentExpression,
                style: TextStyle(
                  color: _currentResult == _targetNumber
                      ? Colors.greenAccent
                      : Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: _cards.map((card) {
          return _buildCard(card);
        }).toList(),
      ),
    );
  }

  Widget _buildCard(NumberCard card) {
    final isSelected = card == _selectedCard;

    return GestureDetector(
      onTap: () => _handleCardTap(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 70,
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getCardColors(card, isSelected),
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            card.value.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              decoration: card.isUsed ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getCardColors(NumberCard card, bool isSelected) {
    if (card.isUsed) {
      return [
        Colors.grey.withOpacity(0.3),
        Colors.grey.withOpacity(0.3),
      ];
    }

    if (isSelected) {
      return [
        Colors.blue.shade400,
        Colors.blue.shade700,
      ];
    }

    switch (card.type) {
      case CardType.prime:
        return [
          Colors.red.shade400,
          Colors.red.shade700,
        ];
      case CardType.square:
        return [
          Colors.purple.shade400,
          Colors.purple.shade700,
        ];
      default:
        return [
          Colors.blue.withOpacity(0.7),
          Colors.purple.withOpacity(0.7),
        ];
    }
  }

  Widget _buildOperators() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _operators.map((operator) {
          return _buildOperatorButton(operator);
        }).toList(),
      ),
    );
  }

  Widget _buildOperatorButton(String operator) {
    final isSelected = operator == _selectedOperator;

    return GestureDetector(
      onTap: () {
        if (_selectedCard != null) {
          setState(() {
            _selectedOperator = operator;
          });
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.black26,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            operator,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            Icons.refresh,
            'Reset',
            () {
              setState(() {
                _initializeGame();
                _startTimer();
              });
            },
          ),
          _buildControlButton(
            Icons.lightbulb_outline,
            'Hint ($_hintsRemaining)',
            _hintsRemaining > 0 ? _useHint : null,
          ),
          _buildControlButton(
            Icons.undo,
            'Undo',
            _history.isNotEmpty ? _undoMove : null,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback? onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: MaterialButton(
          onPressed: onTap,
          color: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
    );
  }

  void _useHint() {
    if (_hintsRemaining <= 0) return;
    setState(() {
      _hintsRemaining--;
      // Hint implementation would go here
    });
  }

  void _undoMove() {
    if (_history.isEmpty) return;
    setState(() {
      _history.removeLast();
      _initializeGame(); // This is a simple implementation
    });
  }
}

enum CardType { normal, prime, square }

class NumberCard {
  final int value;
  final CardType type;
  bool isUsed;

  NumberCard({
    required this.value,
    this.type = CardType.normal,
    this.isUsed = false,
  });
}

class Achievement {
  final String title;
  final String description;
  final IconData icon;

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
  });
}
