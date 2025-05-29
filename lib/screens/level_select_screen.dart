import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Set<int> completedLevels = {};
  int nextLevel = 1;
  bool _showTiles = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => _showTiles = true);
    });
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList('completedLevels') ?? [];
    setState(() {
      completedLevels = completed.map(int.parse).toSet();
      nextLevel = 1;
      for (int i = 1; i <= 100; i++) {
        if (!completedLevels.contains(i)) {
          nextLevel = i;
          break;
        }
      }
    });
  }

  void _onLevelTap(int level) {
    Navigator.pushNamed(
      context,
      '/game',
      arguments: level,
    ).then((_) => _loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/bg_home.jpg', fit: BoxFit.cover),
          ),
          // Overlay for readability
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
          // Main content
          Column(
            children: [
              const SizedBox(height: 48),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Select Level',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: 100,
                    itemBuilder: (context, idx) {
                      int level = idx + 1;
                      bool completed = completedLevels.contains(level);
                      bool unlocked = level == nextLevel || completed;
                      return AnimatedOpacity(
                        opacity: _showTiles ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        child: AnimatedSlide(
                          offset: _showTiles
                              ? Offset.zero
                              : const Offset(0, 0.2),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          child: GestureDetector(
                            onTap: unlocked ? () => _onLevelTap(level) : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color: completed
                                    ? Colors.greenAccent.withOpacity(0.85)
                                    : unlocked
                                    ? Colors.deepPurpleAccent.withOpacity(0.85)
                                    : Colors.grey[400]!.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: completed
                                      ? Colors.green
                                      : unlocked
                                      ? Colors.deepPurpleAccent
                                      : Colors.grey,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: completed
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 32,
                                      )
                                    : Text(
                                        '$level',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: unlocked
                                              ? Colors.white
                                              : Colors.grey[700],
                                          shadows: [
                                            Shadow(
                                              color: Colors.black38,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
