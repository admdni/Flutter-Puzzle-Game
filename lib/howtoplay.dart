import 'package:flutter/material.dart';
import 'dart:math' as math;

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({Key? key}) : super(key: key);

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  final List<GameTutorial> tutorials = [
    GameTutorial(
      title: 'Classic Sudoku Mode',
      description: 'Master the classic number puzzle',
      icon: Icons.dashboard_customize,
      color: const Color(0xFF2C3E50),
      steps: [
        TutorialStep(
          title: 'Basic Rules',
          description: 'Fill each row, column, and 3x3 box with numbers 1-9.',
          icon: Icons.grid_on,
          details: [
            'Each number can only appear once in each row',
            'Each number can only appear once in each column',
            'Each number can only appear once in each 3x3 box',
            'Use logic to determine the correct placement',
          ],
        ),
        TutorialStep(
          title: 'Using Notes',
          description: 'Write down possible numbers for each cell.',
          icon: Icons.edit_note,
          details: [
            'Tap the notes button to enter note mode',
            'Write small numbers as possibilities',
            'Use notes to track candidates',
            'Eliminate numbers as you solve',
          ],
        ),
        TutorialStep(
          title: 'Advanced Techniques',
          description: 'Learn advanced strategies for difficult puzzles.',
          icon: Icons.psychology,
          details: [
            'Look for single candidates',
            'Use cross-hatching technique',
            'Find hidden pairs and triplets',
            'Practice scanning techniques',
          ],
        ),
      ],
    ),
    GameTutorial(
      title: 'Math Blast',
      description: 'Fast-paced math challenge',
      icon: Icons.calculate,
      color: const Color(0xFF2980B9),
      steps: [
        TutorialStep(
          title: 'Quick Math',
          description: 'Solve math problems against the clock.',
          icon: Icons.speed,
          details: [
            'Solve basic math operations quickly',
            'Choose from four possible answers',
            'Build combos for bonus points',
            'Race against the timer',
          ],
        ),
        TutorialStep(
          title: 'Power-Ups',
          description: 'Use special powers to help you.',
          icon: Icons.flash_on,
          details: [
            'Time Boost: Add 5 seconds',
            '50/50: Remove two wrong answers',
            'Skip: Change current question',
            'Use powers strategically',
          ],
        ),
        TutorialStep(
          title: 'Progression',
          description: 'Level up and face harder challenges.',
          icon: Icons.trending_up,
          details: [
            'Start with simple addition/subtraction',
            'Unlock multiplication and division',
            'Face larger numbers at higher levels',
            'Maintain combos for high scores',
          ],
        ),
      ],
    ),
    GameTutorial(
      title: 'Math Slot',
      description: 'Spin and solve math puzzles',
      icon: Icons.casino,
      color: const Color.fromARGB(255, 22, 69, 200),
      steps: [
        TutorialStep(
          title: 'Slot Mechanics',
          description: 'Learn how the slot machine works.',
          icon: Icons.casino,
          details: [
            'Spin to match symbols',
            'Get math problems on matches',
            'Solve problems for points',
            'Build winning streaks',
          ],
        ),
        TutorialStep(
          title: 'Math Challenges',
          description: 'Solve various math problems.',
          icon: Icons.school,
          details: [
            'Quick mental math',
            'Progressive difficulty',
            'Multiple choice answers',
            'Time-based bonuses',
          ],
        ),
        TutorialStep(
          title: 'Progression',
          description: 'Advance through the game.',
          icon: Icons.trending_up,
          details: [
            'Level up system',
            'Unlock new operations',
            'Earn achievements',
            'Complete daily challenges',
          ],
        ),
      ],
    ),
    GameTutorial(
      title: 'Math Challange',
      description: 'Select numbers and use operators to reach the target',
      icon: Icons.casino,
      color: const Color(0xFF16A085),
      steps: [
        TutorialStep(
          title: 'Prime',
          description: 'Prime and square numbers give bonus points.',
          icon: Icons.casino,
          details: [
            'Complete levels to unlock new challenges',
            'Get math problems on matches',
            'Solve problems for points',
            'Build winning streaks',
          ],
        ),
        TutorialStep(
          title: 'Math Challenges',
          description: 'Solve various math problems.',
          icon: Icons.school,
          details: [
            'Quick mental math',
            'Progressive difficulty',
            'Multiple choice answers',
            'Time-based bonuses',
          ],
        ),
        TutorialStep(
          title: 'Progression',
          description: 'Advance through the game.',
          icon: Icons.trending_up,
          details: [
            'Level up system',
            'Unlock new operations',
            'Earn achievements',
            'Complete daily challenges',
          ],
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Image.asset(
            'assets/bg.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          // Animated gradient overlay
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
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildTutorialList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'How to Play',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: tutorials.length,
      itemBuilder: (context, index) {
        final tutorial = tutorials[index];
        return _buildTutorialCard(tutorial);
      },
    );
  }

  Widget _buildTutorialCard(GameTutorial tutorial) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: tutorial.color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(tutorial.icon, color: Colors.white, size: 24),
          ),
          title: Text(
            tutorial.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            tutorial.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tutorial.steps
                    .map((step) => _buildTutorialStep(step))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialStep(TutorialStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(step.icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...step.details.map((detail) => _buildDetailItem(detail)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_right,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              detail,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameTutorial {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<TutorialStep> steps;

  GameTutorial({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.steps,
  });
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final List<String> details;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.details,
  });
}
