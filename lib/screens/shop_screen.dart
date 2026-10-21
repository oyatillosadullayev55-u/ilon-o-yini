import 'package:flutter/material.dart';

import '../models/game_enums.dart';
import '../services/game_storage_service.dart';

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
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Tangalar yetarli emas!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        titleSpacing: 0,
        centerTitle: false,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: const Text(
            "ILON DO'KONI (SHOP)",
            maxLines: 1,
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.greenAccent),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.amberAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$coins",
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: GameSkins.availableSkins.length,
        itemBuilder: (context, index) {
          final skin = GameSkins.availableSkins[index];
          final isUnlocked = unlockedSkins.contains(skin.id);
          final isEquipped = equippedSkin == skin.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEquipped ? Colors.greenAccent : Colors.white24,
                width: isEquipped ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: skin.colors),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              skin.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEquipped
                                  ? "Kiyilgan"
                                  : (isUnlocked
                                        ? "Sotib olingan"
                                        : "Narxi: ${skin.price} tanga"),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isEquipped
                                    ? Colors.greenAccent
                                    : Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEquipped
                        ? Colors.greenAccent
                        : (isUnlocked ? Colors.cyanAccent : Colors.amberAccent),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _buyOrEquip(skin),
                  child: Text(
                    isEquipped
                        ? "KIYILGAN"
                        : (isUnlocked ? "KIYISH" : "SOTIB OLISH"),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
