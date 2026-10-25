import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake/services/game_storage_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('tanga qo\'shiladi va yetarlicha bo\'lganda ayriladi', () async {
    await GameStorageService.addCoins(60);
    expect(await GameStorageService.getCoins(), 60);

    // Narxi 100 bo'lgan narsani sotib olishga urinish tangani kamaytirmaydi.
    await GameStorageService.deductCoins(100);
    expect(await GameStorageService.getCoins(), 60);

    await GameStorageService.deductCoins(50);
    expect(await GameStorageService.getCoins(), 10);
  });

  test('XP darajani ko\'taradi va qoldiq saqlanadi', () async {
    await GameStorageService.addXp(140);
    expect(await GameStorageService.getLevel(), 2);
    expect(await GameStorageService.getXp(), 40);
  });

  test('terilar bir marta qulflanadi va kiyiladi', () async {
    expect(await GameStorageService.getUnlockedSkins(), ['classic']);
    await GameStorageService.unlockSkin('fire');
    await GameStorageService.unlockSkin('fire');
    expect(await GameStorageService.getUnlockedSkins(), ['classic', 'fire']);

    await GameStorageService.setEquippedSkin('fire');
    expect(await GameStorageService.getEquippedSkin(), 'fire');
  });

  test('rekord faqat yangi natija katta bo\'lganda yoziladi', () async {
    expect(await GameStorageService.setHighScore('classic', 40), isTrue);
    expect(await GameStorageService.setHighScore('classic', 30), isFalse);
    expect(await GameStorageService.getHighScore('classic'), 40);
  });

  test('statistika eng uzun ilonni saqlaydi', () async {
    await GameStorageService.updateStats(foodDelta: 5, snakeLength: 9);
    await GameStorageService.updateStats(foodDelta: 2, snakeLength: 4);
    final stats = await GameStorageService.getStats();
    expect(stats['totalGames'], 2);
    expect(stats['totalFood'], 7);
    expect(stats['longestSnake'], 9);
  });
}
