import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/level_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const SudokuAdventureApp());
}

class SudokuAdventureApp extends StatelessWidget {
  const SudokuAdventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku Adventure',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = const SplashScreen();
            break;
          case '/home':
            page = const HomeScreen();
            break;
          case '/levels':
            page = const LevelSelectScreen();
            break;
          case '/game':
            final level = settings.arguments as int?;
            page = GameScreen(level: level);
            break;
          default:
            page = const SplashScreen();
        }
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            final scale = Tween<double>(begin: 0.96, end: 1.0).animate(fade);
            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
      },
    );
  }
}
