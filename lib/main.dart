import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SnakeGameApp());
}

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Snake 3D Neon Ultimate',
      theme: AppTheme.dark,
      home: const MainMenuScreen(),
    );
  }
}
