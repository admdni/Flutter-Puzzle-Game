import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shufflepuzzle_game/classic.dart';
import 'package:shufflepuzzle_game/howtoplay.dart';
import 'package:shufflepuzzle_game/mathpuzzle.dart';
import 'package:shufflepuzzle_game/mathslot.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:io' show exit;

import 'leaderboard.dart';
import 'speedrun.dart';

class BrainTeasersHome extends StatefulWidget {
  const BrainTeasersHome({Key? key}) : super(key: key);

  @override
  State<BrainTeasersHome> createState() => _BrainTeasersHomeState();
}

class _BrainTeasersHomeState extends State<BrainTeasersHome>
    with SingleTickerProviderStateMixin {
  final InAppReview _inAppReview = InAppReview.instance;
  late AnimationController _pulseController;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed && _isAnimating) {
        _pulseController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleAnimation() {
    setState(() {
      _isAnimating = !_isAnimating;
      if (_isAnimating) {
        _pulseController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/bg.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          SafeArea(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Brain Teaser Combo',
                                  style: TextStyle(
                                    fontSize: 29,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Touch center button to start',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.help_outline),
                                color: Colors.white,
                                iconSize: 28,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const HowToPlayScreen(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                _buildGameMenu(),
                const Spacer(),
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameMenu() {
    return Center(
      child: SizedBox(
        width: 360,
        height: 360,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Math Icon Button
            GestureDetector(
              onTap: _toggleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.functions,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            // Game Buttons
            ..._buildGameButtons(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGameButtons() {
    final buttons = [
      _GameButtonData(
        angle: -math.pi / 2,
        color: const Color(0xFFE74C3C),
        icon: Icons.grid_4x4,
        title: 'Classic\nSudoku',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SudokuPuzzle()),
        ),
      ),
      _GameButtonData(
        angle: 0,
        color: const Color(0xFF3498DB),
        icon: Icons.architecture,
        title: 'Math\nBlast',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MathBlast()),
        ),
      ),
      _GameButtonData(
        angle: math.pi / 2,
        color: const Color(0xFF2ECC71),
        icon: Icons.calculate,
        title: 'Math\nChallenge',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MathPuzzle()),
        ),
      ),
      _GameButtonData(
        angle: math.pi,
        color: const Color(0xFF9B59B6),
        icon: Icons.cyclone,
        title: 'Math\nSpin',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MathSlotGame()),
        ),
      ),
    ];

    return buttons.map((data) {
      final x = math.cos(data.angle) * 130;
      final y = math.sin(data.angle) * 130;

      return Positioned(
        left: 180 + x - 50,
        top: 180 + y - 50,
        child: GestureDetector(
          onTap: data.onTap,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white30,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.color.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  data.icon,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 4),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBottomButton(
            'Exit',
            Icons.exit_to_app,
            () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.9),
                title: const Text('Exit Game?'),
                content: const Text('Are you sure you want to exit?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => exit(0),
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomButton(
            'Privacy',
            Icons.shield_outlined,
            () async {
              const url =
                  'https://www.freeprivacypolicy.com/live/d85ab14d-0a6a-4f73-8ace-b85b392025e7';
              if (await canLaunch(url)) {
                await launch(url);
              }
            },
          ),
          _buildBottomButton(
            'LeaderBoard',
            Icons.leaderboard,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaderboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(String label, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameButtonData {
  final double angle;
  final Color color;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _GameButtonData({
    required this.angle,
    required this.color,
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
