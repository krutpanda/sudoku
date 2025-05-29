import 'package:flutter/material.dart';
import '../components/banner_ad_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              const SizedBox(height: 60),
              Text(
                'Sudoku Adventure',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Center(child: _AnimatedHomeButton()),
              const Spacer(),
              const BannerAdWidget(),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedHomeButton extends StatefulWidget {
  @override
  State<_AnimatedHomeButton> createState() => _AnimatedHomeButtonState();
}

class _AnimatedHomeButtonState extends State<_AnimatedHomeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    Future.delayed(const Duration(milliseconds: 200), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 22),
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            elevation: 8,
            shadowColor: Colors.deepPurpleAccent.withOpacity(0.4),
          ),
          onPressed: () => Navigator.pushNamed(context, '/levels'),
          child: const Text('Play Levels'),
        ),
      ),
    );
  }
}
