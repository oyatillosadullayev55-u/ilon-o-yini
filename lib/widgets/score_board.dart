import 'package:flutter/material.dart';
import '../models/direction.dart';

class ScoreBoard extends StatelessWidget {
  final int score;
  final int highScore;
  final int level;
  final GameMode gameMode;
  final ValueChanged<GameMode> onModeChanged;

  const ScoreBoard({
    super.key,
    required this.score,
    required this.highScore,
    required this.level,
    required this.gameMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF161B22), Color(0xFF0D1117)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.greenAccent.withValues(alpha: 0.5),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'OCHKO',
                  '$score',
                  Colors.greenAccent,
                  Icons.sports_esports,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  'DARAJA',
                  '$level',
                  Colors.amberAccent,
                  Icons.bolt,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  'REKORD',
                  '$highScore',
                  Colors.cyanAccent,
                  Icons.emoji_events,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeButton('Klassik', GameMode.classic),
              const SizedBox(width: 8),
              _buildModeButton('Cheksiz', GameMode.endless),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton(String label, GameMode mode) {
    final isSelected = gameMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.greenAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.white24);
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 200),
          key: ValueKey(value),
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.6), blurRadius: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
