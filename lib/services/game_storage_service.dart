import 'package:shared_preferences/shared_preferences.dart';

class GameStorageService {
  static const String _keyCoins = 'game_coins';
  static const String _keyXp = 'game_xp';
  static const String _keyLevel = 'game_level';
  static const String _keyEquippedSkin = 'equipped_skin';
  static const String _keyUnlockedSkins = 'unlocked_skins';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  
  // Stats
  static const String _keyTotalGames = 'stat_total_games';
  static const String _keyTotalFood = 'stat_total_food';
  static const String _keyLongestSnake = 'stat_longest_snake';

  // High Scores per mode
  static String _getHighScoreKey(String modeName) => 'high_score_$modeName';

  static Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  static Future<int> getCoins() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyCoins) ?? 0;
  }

  static Future<void> addCoins(int amount) async {
    final prefs = await _prefs;
    int current = prefs.getInt(_keyCoins) ?? 0;
    await prefs.setInt(_keyCoins, current + amount);
  }

  static Future<void> deductCoins(int amount) async {
    final prefs = await _prefs;
    int current = prefs.getInt(_keyCoins) ?? 0;
    if (current >= amount) {
      await prefs.setInt(_keyCoins, current - amount);
    }
  }

  static Future<int> getXp() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyXp) ?? 0;
  }

  static Future<void> addXp(int amount) async {
    final prefs = await _prefs;
    int currentXp = prefs.getInt(_keyXp) ?? 0;
    int currentLevel = prefs.getInt(_keyLevel) ?? 1;
    
    currentXp += amount;
    int requiredXp = currentLevel * 100;
    if (currentXp >= requiredXp) {
      currentXp -= requiredXp;
      currentLevel++;
      await prefs.setInt(_keyLevel, currentLevel);
    }
    await prefs.setInt(_keyXp, currentXp);
  }

  static Future<int> getLevel() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyLevel) ?? 1;
  }

  static Future<String> getEquippedSkin() async {
    final prefs = await _prefs;
    return prefs.getString(_keyEquippedSkin) ?? 'classic';
  }

  static Future<void> setEquippedSkin(String skinId) async {
    final prefs = await _prefs;
    await prefs.setString(_keyEquippedSkin, skinId);
  }

  static Future<List<String>> getUnlockedSkins() async {
    final prefs = await _prefs;
    return prefs.getStringList(_keyUnlockedSkins) ?? ['classic'];
  }

  static Future<void> unlockSkin(String skinId) async {
    final prefs = await _prefs;
    List<String> unlocked = prefs.getStringList(_keyUnlockedSkins) ?? ['classic'];
    if (!unlocked.contains(skinId)) {
      unlocked.add(skinId);
      await prefs.setStringList(_keyUnlockedSkins, unlocked);
    }
  }

  static Future<int> getHighScore(String modeName) async {
    final prefs = await _prefs;
    return prefs.getInt(_getHighScoreKey(modeName)) ?? 0;
  }

  static Future<bool> setHighScore(String modeName, int score) async {
    final prefs = await _prefs;
    int current = prefs.getInt(_getHighScoreKey(modeName)) ?? 0;
    if (score > current) {
      await prefs.setInt(_getHighScoreKey(modeName), score);
      return true; // new high score
    }
    return false;
  }

  static Future<bool> isSoundEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keySoundEnabled) ?? true;
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keySoundEnabled, enabled);
  }

  static Future<bool> isVibrationEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyVibrationEnabled) ?? true;
  }

  static Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyVibrationEnabled, enabled);
  }

  // Statistics getters & updaters
  static Future<Map<String, int>> getStats() async {
    final prefs = await _prefs;
    return {
      'totalGames': prefs.getInt(_keyTotalGames) ?? 0,
      'totalFood': prefs.getInt(_keyTotalFood) ?? 0,
      'longestSnake': prefs.getInt(_keyLongestSnake) ?? 3,
    };
  }

  static Future<void> updateStats({int foodDelta = 0, int snakeLength = 3}) async {
    final prefs = await _prefs;
    int games = (prefs.getInt(_keyTotalGames) ?? 0) + 1;
    int food = (prefs.getInt(_keyTotalFood) ?? 0) + foodDelta;
    int longest = prefs.getInt(_keyLongestSnake) ?? 3;
    if (snakeLength > longest) longest = snakeLength;

    await prefs.setInt(_keyTotalGames, games);
    await prefs.setInt(_keyTotalFood, food);
    await prefs.setInt(_keyLongestSnake, longest);
  }
}
