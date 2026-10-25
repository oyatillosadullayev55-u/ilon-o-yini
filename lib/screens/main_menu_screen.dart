import 'dart:math';
import 'package:flutter/material.dart';
import '../models/animation_models.dart';
import '../models/direction.dart';
import '../services/game_storage_service.dart';
import '../widgets/game_board_3d.dart';
import '../widgets/ui_kit.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'stats_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  GameMode selectedMode = GameMode.classic;
  int coins = 0;
  int level = 1;

  static const List<(GameMode, String, Color)> _modes = [
    (GameMode.classic, 'Klassik', Color(0xFF00E5A0)),
    (GameMode.endless, 'Cheksiz', Color(0xFF35C4FF)),
    (GameMode.timeAttack, 'Time Attack', Color(0xFFFFC857)),
    (GameMode.obstacle, 'Obstacle', Color(0xFFFF5364)),
    (GameMode.survival, 'Survival', Color(0xFFB57BFF)),
  ];

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

  Future<void> _open(Widget page) async {
    await Navigator.push(context, FadeScaleRoute(child: page));
    _loadUserProgress();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _modes.firstWhere((m) => m.$1 == selectedMode).$3;
    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: NeonBackground(
          accent: accent,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatPill(icon: Icons.monetization_on, label: "$coins", color: Color(0xFFFFC857)),
                    StatPill(icon: Icons.bolt, label: "Daraja $level", color: accent),
                  ],
                ),
                const SizedBox(height: 14),
                const _FloatingTitle(),
                const SizedBox(height: 6),
                const Center(child: SectionLabel('Neon 3D Arcade')),
                const SizedBox(height: 16),
                GlassPanel(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  borderColor: accent.withValues(alpha: 0.34),
                  glowColor: accent,
                  blur: 6,
                  child: Column(
                    children: [
                      SizedBox(height: 168, child: const _DemoScene()),
                      const SizedBox(height: 8),
                      const SectionLabel('Jonli 3D demo'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionLabel("Rejimni tanlang"),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (mode, label, color) in _modes)
                      _ModeChip(
                        label: label,
                        color: color,
                        selected: selectedMode == mode,
                        onTap: () => setState(() => selectedMode = mode),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: NeonButton(
                    label: 'B O S H L A S H',
                    icon: Icons.play_arrow_rounded,
                    fontSize: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 16),
                    colors: [accent, Color.lerp(accent, Colors.white, 0.28)!],
                    onPressed: () => _open(GameScreen(initialMode: selectedMode)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GlassButton(
                      label: "Do'kon",
                      icon: Icons.storefront_rounded,
                      color: const Color(0xFFFFC857),
                      onPressed: () => _open(const ShopScreen()),
                    ),
                    const SizedBox(width: 8),
                    GlassButton(
                      label: 'Statistika',
                      icon: Icons.insights_rounded,
                      color: const Color(0xFF35C4FF),
                      onPressed: () => _open(const StatsScreen()),
                    ),
                    const SizedBox(width: 8),
                    GlassButton(
                      label: 'Sozlama',
                      icon: Icons.settings_rounded,
                      color: const Color(0xFFB57BFF),
                      onPressed: () => _open(const SettingsScreen()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sarlavha — sekin suzib yuruvchi neon matn.
class _FloatingTitle extends StatefulWidget {
  const _FloatingTitle();

  @override
  State<_FloatingTitle> createState() => _FloatingTitleState();
}

class _FloatingTitleState extends State<_FloatingTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, sin(_t.value * 2 * pi) * 3.5),
        child: child,
      ),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: NeonTitle('SNAKE 3D', fontSize: 40),
      ),
    );
  }
}

/// Rejim tugmasi (glass chip).
class _ModeChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.62)])
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: selected ? 1 : 0.32), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: selected ? 0.40 : 0.0),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

/// Bosh menyudagi jonli ilon aylanasi — haqiqiy 3D renderer orqali.
class _DemoScene extends StatefulWidget {
  const _DemoScene();

  @override
  State<_DemoScene> createState() => _DemoSceneState();
}

class _DemoSceneState extends State<_DemoScene> with SingleTickerProviderStateMixin {
  static const int rows = 8;
  static const int cols = 12;
  static const int body = 7;

  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  late final List<int> _route = _buildRoute();

  List<int> _buildRoute() {
    final cells = <int>[];
    for (int c = 1; c <= cols - 2; c++) {
      cells.add(1 * cols + c);
    }
    for (int r = 2; r <= rows - 2; r++) {
      cells.add(r * cols + (cols - 2));
    }
    for (int c = cols - 3; c >= 1; c--) {
      cells.add((rows - 2) * cols + c);
    }
    for (int r = rows - 3; r >= 2; r--) {
      cells.add(r * cols + 1);
    }
    return cells;
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final loop = _route.length;
        final travel = _t.value * loop * 1.4;
        final head = (travel.truncate() % loop + loop) % loop;
        final frac = travel - travel.truncate();
        final snake = [for (int i = 0; i < body; i++) _route[(head - i + loop * 4) % loop]];
        return SnakeScene3D(
          rowCount: rows,
          colCount: cols,
          snake: snake,
          food: _route[(head + 5) % loop],
          bonusFood: -1,
          direction: Direction.right,
          pulseValue: _t.value,
          timeValue: _t.value * 24,
          interpolation: frac,
          prevLength: body,
          floatingScores: [
            FloatingScore(
              text: '+10',
              position: const Offset(6.5, 2.5),
              color: const Color(0xFF00E5A0),
              opacity: 0.55,
            ),
          ],
          particles: [
            Particle(
              position: const Offset(9.5, 4.5),
              velocity: const Offset(0.01, 0.0),
              color: const Color(0xFF35C4FF),
              size: 0.14,
              opacity: 0.6,
            ),
          ],
          skinColors: const [Color(0xFF00E5A0), Color(0xFF35C4FF)],
          wraps: true,
          radius: 16,
        );
      },
    );
  }
}
