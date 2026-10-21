import 'package:flutter/material.dart';

import '../services/game_storage_service.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF080C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text(
          "STATISTIKA VA REKORDLAR",
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Umumiy ko'rsatkichlar",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatCard(
                "O'yinlar",
                "${stats['totalGames']}",
                Icons.sports_esports,
                Colors.greenAccent,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                "Yeb qo'yilgan",
                "${stats['totalFood']}",
                Icons.restaurant,
                Colors.amberAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                "Eng uzun ilon",
                "${stats['longestSnake']}",
                Icons.straighten,
                Colors.cyanAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Rejimlar bo'yicha rekordlar",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildModeRecord("Klassik rejim", classicHigh, Colors.greenAccent),
          _buildModeRecord("Cheksiz rejim", endlessHigh, Colors.cyanAccent),
          _buildModeRecord("Time Attack", timeAttackHigh, Colors.amberAccent),
          _buildModeRecord(
            "Survival (Omon qolish)",
            survivalHigh,
            Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeRecord(String title, int score, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "$score",
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
