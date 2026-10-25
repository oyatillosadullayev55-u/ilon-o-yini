import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/game_storage_service.dart';
import '../widgets/ui_kit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  int level = 1;
  int xp = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    bool s = await GameStorageService.isSoundEnabled();
    bool v = await GameStorageService.isVibrationEnabled();
    int l = await GameStorageService.getLevel();
    int x = await GameStorageService.getXp();
    if (!mounted) return;
    setState(() {
      soundEnabled = s;
      vibrationEnabled = v;
      level = l;
      xp = x;
    });
  }

  @override
  Widget build(BuildContext context) {
    final requiredXp = level * 100;
    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: NeonBackground(
          accent: const Color(0xFFB57BFF),
          accent2: const Color(0xFF35C4FF),
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
                        child: NeonTitle(
                          'SOZLAMALAR',
                          fontSize: 22,
                          colors: [Color(0xFFB57BFF), Color(0xFF35C4FF)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  children: [
                    GlassPanel(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                      radius: 20,
                      blur: 8,
                      borderColor: const Color(0xFFB57BFF).withValues(alpha: 0.32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.rocket_launch_rounded,
                                  color: Color(0xFFB57BFF), size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: SectionLabel("Daraja va tajriba"),
                              ),
                              Text(
                                "$xp / $requiredXp XP",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Daraja $level',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0.0,
                                end: (xp / requiredXp).clamp(0.0, 1.0),
                              ),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) => LinearProgressIndicator(
                                value: v,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.07),
                                valueColor: const AlwaysStoppedAnimation(Color(0xFFB57BFF)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SectionLabel('Ovoz va tebranish'),
                    const SizedBox(height: 10),
                    _SettingRow(
                      icon: Icons.volume_up_rounded,
                      color: const Color(0xFF00E5A0),
                      title: 'Ovoz effektlari',
                      subtitle: 'Yemak yeganda va tugmalarda ovoz',
                      value: soundEnabled,
                      onChanged: (val) async {
                        await GameStorageService.setSoundEnabled(val);
                        if (mounted) setState(() => soundEnabled = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    _SettingRow(
                      icon: Icons.vibration_rounded,
                      color: const Color(0xFF35C4FF),
                      title: 'Vibratsiya (Haptic)',
                      subtitle: "O'yin davomida tebranish",
                      value: vibrationEnabled,
                      onChanged: (val) async {
                        await GameStorageService.setVibrationEnabled(val);
                        if (mounted) setState(() => vibrationEnabled = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const SectionLabel("Boshqaruv"),
                    const SizedBox(height: 10),
                    GlassPanel(
                      padding: const EdgeInsets.all(14),
                      radius: 20,
                      blur: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _HintRow(Icons.wb_sunny_rounded, 'W A S D yoki strelkalar — yo\'nalish'),
                          _HintRow(Icons.touch_app_rounded, 'Barmoq bilan sudrab boshqarish'),
                          _HintRow(Icons.pause_rounded, 'P — pauza, Space — boshlash'),
                        ],
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

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;

  const _SettingRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      radius: 20,
      blur: 8,
      borderColor: color.withValues(alpha: value ? 0.6 : 0.22),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HintRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
