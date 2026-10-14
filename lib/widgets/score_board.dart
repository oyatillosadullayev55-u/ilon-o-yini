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
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 1,
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('OCHKO', '$score', Colors.greenAccent),
              _buildDivider(),
              _buildStatItem('DARAJA', '$level', Colors.amberAccent),
              _buildDivider(),
              _buildStatItem('REKORD', '$highScore', Colors.cyanAccent),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeChip('Klassik', GameMode.classic),
            const SizedBox(width: 12),
            _buildModeChip('Cheksiz', GameMode.endless),
          ],
        ),
      ],
    );
  }

  Widget _buildModeChip(String label, GameMode mode) {
    final isSelected = gameMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.greenAccent,
      backgroundColor: const Color(0xFF161B22),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white60,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (_) => onModeChanged(mode),
    );
  }

  Widget _buildDivider() {
    return Container(height: 25, width: 1, color: Colors.white24);
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: color.withOpacity(0.5), blurRadius: 8),
            ],
          ),
        ),
      ],
    );
  }
}