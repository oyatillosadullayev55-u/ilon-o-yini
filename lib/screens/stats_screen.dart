import 'package:flutter/material.dart';

import '../services/game_storage_service.dart';
import '../widgets/ui_kit.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, int> stats = {'totalGames': 0, 'totalFood': 0, 'longestSnake': 3};
  int classicHigh = 0;
  int endlessHigh = 0;
  int timeAttackHigh = 0;
  int survivalHigh = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await GameStorageService.getStats();
    final cHigh = await GameStorageService.getHighScore('classic');
    final eHigh = await GameStorageService.getHighScore('endless');
    final tHigh = await GameStorageService.getHighScore('timeAttack');
    final sHigh = await GameStorageService.getHighScore('survival');

    if (!mounted) return;
    setState(() {
      stats = s;
      classicHigh = cHigh;
      endlessHigh = eHigh;
      timeAttackHigh = tHigh;
      survivalHigh = sHigh;
    });
  }

  @override
  Widget build(BuildContext context) {
    final best = [classicHigh, endlessHigh, timeAttackHigh, survivalHigh]
        .reduce((a, b) => a > b ? a : b);
    final records = <(String, int, Color)>[
      ('Klassik rejim', classicHigh, const Color(0xFF00E5A0)),
      ('Cheksiz rejim', endlessHigh, const Color(0xFF35C4FF)),
      ('Time Attack', timeAttackHigh, const Color(0xFFFFC857)),
      ('Survival (Omon qolish)', survivalHigh, const Color(0xFFFF5364)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: NeonBackground(
          accent: const Color(0xFF35C4FF),
          intensity: 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 14, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: NeonTitle('STATISTIKA', fontSize: 22),
                      ),
                    ),
                    StatPill(
                      icon: Icons.emoji_events_rounded,
                      label: "Rekord $best",
                      color: const Color(0xFFFFC857),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  children: [
                    const SectionLabel("Umumiy statistika"),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatCard(
                          label: "O'yinlar",
                          value: stats['totalGames'] ?? 0,
                          icon: Icons.sports_esports_rounded,
                          color: const Color(0xFF00E5A0),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Yeb qo\'yilgan',
                          value: stats['totalFood'] ?? 0,
                          icon: Icons.restaurant_rounded,
                          color: const Color(0xFFFFC857),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Eng uzun',
                          value: stats['longestSnake'] ?? 3,
                          icon: Icons.straighten_rounded,
                          color: const Color(0xFF35C4FF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel('Rejim rekordlari'),
                    const SizedBox(height: 10),
                    for (final (title, score, color) in records)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecordRow(
                          title: title,
                          score: score,
                          color: color,
                          fraction: best == 0 ? 0.0 : score / best,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        radius: 18,
        blur: 8,
        borderColor: color.withValues(alpha: 0.34),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) => Text(
                animated.round().toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final String title;
  final int score;
  final Color color;
  final double fraction;

  const _RecordRow({
    required this.title,
    required this.score,
    required this.color,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      radius: 18,
      blur: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "$score",
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: fraction.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
