import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

/// Yuqoridagi ball paneli va rejim tanlagichi.
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

  static const List<(GameMode, String, Color)> _modes = [
    (GameMode.classic, 'Klassik', AppTheme.primary),
    (GameMode.endless, 'Cheksiz', AppTheme.secondary),
    (GameMode.timeAttack, 'Time Attack', AppTheme.gold),
    (GameMode.obstacle, 'Obstacle', Color(0xFFFF5364)),
    (GameMode.survival, 'Survival', Color(0xFFC86BFF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: GlassPanel(
            radius: 20,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            borderColor: AppTheme.primary.withValues(alpha: 0.28),
            child: Row(
              children: [
                Expanded(child: _stat('OCHKO', '$score', AppTheme.primary, Icons.sports_esports)),
                _divider(),
                Expanded(child: _stat('DARAJA', '$level', AppTheme.gold, Icons.bolt)),
                _divider(),
                Expanded(child: _stat('REKORD', '$highScore', AppTheme.secondary, Icons.emoji_events)),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final (mode, label, color) in _modes) ...[
                _modeChip(mode, label, color),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _modeChip(GameMode mode, String label, Color color) {
    final selected = gameMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.55)])
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: selected ? color : Colors.white.withValues(alpha: 0.10)),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14, spreadRadius: 1)]
              : const [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white60,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(height: 28, width: 1, color: Colors.white.withValues(alpha: 0.12));

  Widget _stat(String label, String value, Color color, IconData icon) {
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
        const SizedBox(height: 3),
        TweenAnimationBuilder<double>(
          key: ValueKey(value),
          tween: Tween(begin: 0.72, end: 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: color.withValues(alpha: 0.55), blurRadius: 12)],
            ),
          ),
        ),
      ],
    );
  }
}
