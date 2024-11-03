import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'homegame.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? username;
  bool isLoading = true;
  Map<String, List<ScoreData>> leaderboards = {
    'sudoku': [],
    'math_blast': [],
    'math': [],
    'spin': [],
  };

  static const String apiUrl = 'https://appledeveloper.com.tr/tablo/app2.php';
  static const String usernameKey = 'username';

  final List<Map<String, dynamic>> gameTypes = [
    {
      'name': 'Sudoku',
      'icon': Icons.grid_4x4,
      'color': Color(0xFFE74C3C),
      'gradient': [Color(0xFFE74C3C), Color(0xFFC0392B)],
    },
    {
      'name': 'Math Blast',
      'icon': Icons.architecture,
      'color': Color(0xFF3498DB),
      'gradient': [Color(0xFF3498DB), Color(0xFF2980B9)],
    },
    {
      'name': 'Math',
      'icon': Icons.calculate,
      'color': Color(0xFF2ECC71),
      'gradient': [Color(0xFF2ECC71), Color(0xFF27AE60)],
    },
    {
      'name': 'Spin',
      'icon': Icons.cyclone,
      'color': Color(0xFF9B59B6),
      'gradient': [Color(0xFF9B59B6), Color(0xFF8E44AD)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeUser();

    // Add listener for tab changes
    _tabController.addListener(() {
      setState(() {}); // Refresh UI when tab changes
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString(usernameKey);

    if (username == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUsernameDialog();
      });
    } else {
      _loadLeaderboards();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentGameType = gameTypes[_tabController.index];

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
          // Background Image - Keeping the existing background
          Image.asset(
            'assets/bg.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  currentGameType['gradient'][0].withOpacity(0.8),
                  currentGameType['gradient'][1].withOpacity(0.9),
                ],
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(currentGameType),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: leaderboards.entries.map((entry) {
                      return _buildLeaderboardContent(entry.value);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> gameType) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadLeaderboards,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (username != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    username!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.2),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
        tabs: gameTypes.map((game) {
          return Tab(
            icon: Icon(game['icon'] as IconData),
            text: game['name'] as String,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeaderboardContent(List<ScoreData> scores) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (scores.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(24),
      itemCount: scores.length,
      itemBuilder: (context, index) {
        return _buildScoreCard(scores[index], index);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Loading scores...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Colors.white70,
          ),
          SizedBox(height: 16),
          Text(
            'No scores yet\nBe the first to set a record!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(ScoreData score, int index) {
    final isCurrentUser = score.username == username;
    final isTopThree = index < 3;
    final positionColor = _getPositionColor(index);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isCurrentUser
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            isCurrentUser
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isTopThree
                ? positionColor.withOpacity(0.2)
                : Colors.transparent,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildPosition(index),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        score.username,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTopThree ? 18 : 16,
                          fontWeight: isCurrentUser || isTopThree
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDate(score.createdAt),
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildScore(score.score, index),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosition(int index) {
    final color = _getPositionColor(index);
    final isTopThree = index < 3;

    if (isTopThree) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.emoji_events,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildScore(int score, int index) {
    final color = _getPositionColor(index);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        score.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: index < 3 ? 20 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPositionColor(int index) {
    switch (index) {
      case 0:
        return Color(0xFFFFD700); // Gold
      case 1:
        return Color(0xFFC0C0C0); // Silver
      case 2:
        return Color(0xFFCD7F32); // Bronze
      default:
        return Colors.white.withOpacity(0.5);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Just now';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _loadLeaderboards() async {
    setState(() => isLoading = true);

    try {
      for (String gameType in leaderboards.keys) {
        final response = await http.post(
          Uri.parse(apiUrl),
          body: json.encode({
            'action': 'get_leaderboard',
            'game_type': gameType,
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['leaderboard'] != null) {
            setState(() {
              leaderboards[gameType] = (data['leaderboard'] as List)
                  .map((item) => ScoreData.fromJson(item))
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to load leaderboards');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showUsernameDialog() async {
    final TextEditingController controller = TextEditingController();
    bool isSubmitting = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade900.withOpacity(0.95),
                  Colors.purple.shade800.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 40,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    'Create your username to join the leaderboard',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Username TextField
                  TextField(
                    controller: controller,
                    enabled: !isSubmitting,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter username',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.person, color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    maxLength: 20,
                    textCapitalization: TextCapitalization.none,
                    onSubmitted: (_) =>
                        _submitUsername(controller, setState, isSubmitting),
                  ),
                  const SizedBox(height: 24),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () => _submitUsername(
                              controller, setState, isSubmitting),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.purple.shade900,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: isSubmitting
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.purple.shade900,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
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

  Future<void> _submitUsername(
    TextEditingController controller,
    StateSetter setState,
    bool isSubmitting,
  ) async {
    final username = controller.text.trim();
    if (username.isEmpty) return;

    setState(() => isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(usernameKey, username);

      this.setState(() {
        this.username = username;
      });

      Navigator.pop(context);
      _loadLeaderboards();
    } catch (e) {
      setState(() => isSubmitting = false);
      _showErrorDialog('Failed to save username');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.shade900.withOpacity(0.95),
                Colors.red.shade800.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.red.shade900,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScoreData {
  final String username;
  final int score;
  final DateTime createdAt;

  const ScoreData({
    required this.username,
    required this.score,
    required this.createdAt,
  });

  factory ScoreData.fromJson(Map<String, dynamic> json) {
    return ScoreData(
      username: json['username'] as String,
      score: int.parse(json['score'].toString()),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'score': score,
        'created_at': createdAt.toIso8601String(),
      };
}
