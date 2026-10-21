import 'package:flutter/material.dart';
import '../services/game_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    bool s = await GameStorageService.isSoundEnabled();
    bool v = await GameStorageService.isVibrationEnabled();
    if (mounted) {
      setState(() {
        soundEnabled = s;
        vibrationEnabled = v;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text("SOZLAMALAR", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.amberAccent),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Ovoz effektlari", style: TextStyle(color: Colors.white, fontSize: 16)),
            subtitle: const Text("Yemak yeganda va tugmalarda ovoz", style: TextStyle(color: Colors.white54, fontSize: 12)),
            activeThumbColor: Colors.amberAccent,
            value: soundEnabled,
            onChanged: (val) async {
              await GameStorageService.setSoundEnabled(val);
              setState(() => soundEnabled = val);
            },
          ),
          const Divider(color: Colors.white10),
          SwitchListTile(
            title: const Text("Vibratsiya (Haptic)", style: TextStyle(color: Colors.white, fontSize: 16)),
            subtitle: const Text("O'yin davomida tebranish", style: TextStyle(color: Colors.white54, fontSize: 12)),
            activeThumbColor: Colors.amberAccent,
            value: vibrationEnabled,
            onChanged: (val) async {
              await GameStorageService.setVibrationEnabled(val);
              setState(() => vibrationEnabled = val);
            },
          ),
        ],
      ),
    );
  }
}
