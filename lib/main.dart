import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const SnakeGameApp());
}

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Snake Neon Ultimate',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080C10),
      ),
      home: const GameScreen(),
    );
  }
}