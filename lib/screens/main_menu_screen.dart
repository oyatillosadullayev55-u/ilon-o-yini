import 'package:flutter/material.dart';
import '../models/game_enums.dart';
import '../services/game_storage_service.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  GameMode selectedMode = GameMode.classic;
  int coins = 0;
  int level = 1;

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    int c = await GameStorageService.getCoins();
    int l = await GameStorageService.getLevel();
    if (!mounted) return;
    setState(() {
      coins = c;
      level = l;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C10),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Qisqa ekranlarda Spacerlar manba bo'lmaydi: kontent o'rgatiladi
            final double gap = constraints.maxHeight > 620 ? 28 : 12;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Bar (Coins & Level)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPill(
                          Icons.monetization_on,
                          Colors.amberAccent,
                          "$coins",
                        ),
                        _buildPill(
                          Icons.bolt,
                          Colors.greenAccent,
                          "Daraja $level",
                        ),
                      ],
                    ),
                    SizedBox(height: gap * 2),
                    // Title
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.greenAccent, Colors.cyanAccent],
                        ).createShader(bounds),
                        child: const Text(
                          "SNAKE ULTIMATE",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "PRO ARCADE EDITION",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    SizedBox(height: gap * 2),
                    // Mode Selector
                    const Text(
                      "O'YIN REJIMINI TANLANG",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildModeChip("Klassik", GameMode.classic, Colors.greenAccent),
                        _buildModeChip("Cheksiz", GameMode.endless, Colors.cyanAccent),
                        _buildModeChip("Time Attack", GameMode.timeAttack, Colors.amberAccent),
                        _buildModeChip("Obstacle", GameMode.obstacle, Colors.redAccent),
                        _buildModeChip("Survival", GameMode.survival, Colors.purpleAccent),
                      ],
                    ),
                    SizedBox(height: gap * 2),
                    // Start Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 10,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GameScreen(initialMode: selectedMode),
                          ),
                        );
                        _loadUserProgress();
                      },
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "B O S H L A S H",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Navigation Buttons (Shop, Stats, Settings)
                    Row(
                      children: [
                        _buildNavButton(Icons.store, "Do'kon", () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ShopScreen(),
                            ),
                          );
                          _loadUserProgress();
                        }),
                        const SizedBox(width: 8),
                        _buildNavButton(Icons.bar_chart, "Statistika", () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StatsScreen(),
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                        _buildNavButton(Icons.settings, "Sozlama", () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, GameMode mode, Color color) {
    final isSelected = selectedMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: const Color(0xFF161B22),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => selectedMode = mode),
    );
  }

  Widget _buildNavButton(IconData icon, String label, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF161B22),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.white10),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: Colors.greenAccent),
        label: Text(label, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
