import 'package:flutter/material.dart';

import '../models/direction.dart';
import '../models/game_enums.dart';
import '../services/game_storage_service.dart';
import '../widgets/game_board_3d.dart';
import '../widgets/ui_kit.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int coins = 0;
  String equippedSkin = 'classic';
  List<String> unlockedSkins = ['classic'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    int c = await GameStorageService.getCoins();
    String eq = await GameStorageService.getEquippedSkin();
    List<String> un = await GameStorageService.getUnlockedSkins();
    if (!mounted) return;
    setState(() {
      coins = c;
      equippedSkin = eq;
      unlockedSkins = un;
    });
  }

  Future<void> _buyOrEquip(SnakeSkinInfo skin) async {
    if (unlockedSkins.contains(skin.id)) {
      await GameStorageService.setEquippedSkin(skin.id);
      if (!mounted) return;
      setState(() {
        equippedSkin = skin.id;
      });
    } else {
      if (coins >= skin.price) {
        await GameStorageService.deductCoins(skin.price);
        await GameStorageService.unlockSkin(skin.id);
        await GameStorageService.setEquippedSkin(skin.id);
        await _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tabriklaymiz! '${skin.name}' terisi sotib olindi!"),
            backgroundColor: const Color(0xFF0B3D2C),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tangalar yetarli emas!"),
            backgroundColor: Color(0xFF3D1116),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: NeonBackground(
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
                        child: NeonTitle('ILON DO\'KONI', fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatPill(
                      icon: Icons.monetization_on,
                      label: "$coins",
                      color: const Color(0xFFFFC857),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SectionLabel('3D terilar'),
                    SectionLabel('5 teri'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                  itemCount: GameSkins.availableSkins.length,
                  itemBuilder: (context, index) {
                    final skin = GameSkins.availableSkins[index];
                    final isUnlocked = unlockedSkins.contains(skin.id);
                    final isEquipped = equippedSkin == skin.id;
                    final accent = skin.colors.first;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassPanel(
                        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                        radius: 20,
                        blur: 8,
                        borderColor: accent.withValues(alpha: isEquipped ? 0.95 : 0.30),
                        glowColor: isEquipped ? accent : null,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 78,
                              height: 62,
                              child: _SkinPreview(colors: skin.colors),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      skin.name,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      isEquipped
                                          ? "Kiyilgan"
                                          : (isUnlocked
                                                ? "Sotib olingan"
                                                : "Narxi: ${skin.price} tanga"),
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: isEquipped ? accent : Colors.white60,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: NeonButton(
                                label: isEquipped
                                    ? "KIYILGAN"
                                    : (isUnlocked ? "KIYISH" : "SOTIB OLISH"),
                                fontSize: 11,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                colors: isEquipped
                                    ? [accent, accent]
                                    : (isUnlocked
                                          ? [
                                              const Color(0xFF35C4FF),
                                              const Color(0xFF6FE3FF),
                                            ]
                                          : [
                                              const Color(0xFFFFC857),
                                              const Color(0xFFFFE59B),
                                            ]),
                                onPressed: () => _buyOrEquip(skin),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Do'kon kartochkasidagi kichik 3D ilon namunasi.
class _SkinPreview extends StatelessWidget {
  final List<Color> colors;

  const _SkinPreview({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SnakeScene3D(
      rowCount: 4,
      colCount: 9,
      snake: const [17, 16, 15, 14, 13, 22, 23],
      food: 4,
      bonusFood: -1,
      direction: Direction.right,
      pulseValue: 0.25,
      timeValue: 12,
      skinColors: colors,
      radius: 12,
    );
  }
}
