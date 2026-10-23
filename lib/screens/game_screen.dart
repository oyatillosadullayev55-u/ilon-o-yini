import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/direction.dart';
import '../models/animation_models.dart';
import '../models/game_enums.dart';
import '../services/game_storage_service.dart';
import '../widgets/game_board.dart';
import '../widgets/score_board.dart';

class GameScreen extends StatefulWidget {
  final GameMode initialMode;
  const GameScreen({super.key, this.initialMode = GameMode.classic});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int rowCount = 20;
  static const int colCount = 15;

  List<int> snake = [33, 32, 31];
  int food = 100;
  int bonusFood = -1;
  List<int> obstacles = [];
  Direction direction = Direction.right;
  Direction nextDirection = Direction.right;
  Timer? timer;
  Timer? bonusTimer;
  Timer? gameTimer; // For Time Attack countdown

  late GameMode gameMode;
  GameState gameState = GameState.idle;

  int score = 0;
  int highScore = 0;
  int level = 1;
  int speed = 200;
  int eatenFoodCount = 0;
  int timeLeft = 60; // For Time Attack mode

  // Skin colors
  List<Color> skinColors = [Colors.greenAccent, Colors.cyanAccent];

  // Animation controllers & lists
  late AnimationController _pulseController;
  late AnimationController _animationLoopController;
  final List<FloatingScore> floatingScores = [];
  final List<Particle> particles = [];

  bool showLevelUpBanner = false;
  int currentLevelUp = 1;
  double screenShakeOffset = 0.0;

  @override
  void initState() {
    super.initState();
    gameMode = widget.initialMode;
    _loadSkinAndHighScore();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _animationLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _animationLoopController.addListener(_updateAnimations);
  }

  Future<void> _loadSkinAndHighScore() async {
    String skinId = await GameStorageService.getEquippedSkin();
    final skinInfo = GameSkins.availableSkins.firstWhere(
      (s) => s.id == skinId,
      orElse: () => GameSkins.availableSkins.first,
    );
    int hScore = await GameStorageService.getHighScore(gameMode.name);

    if (mounted) {
      setState(() {
        skinColors = skinInfo.colors;
        highScore = hScore;
      });
    }
  }

  void _updateAnimations() {
    if (!mounted) return;
    setState(() {
      for (int i = floatingScores.length - 1; i >= 0; i--) {
        var fs = floatingScores[i];
        fs.yOffset -= 0.055;
        fs.opacity -= 0.035;
        if (fs.opacity <= 0) {
          floatingScores.removeAt(i);
        }
      }

      for (int i = particles.length - 1; i >= 0; i--) {
        var p = particles[i];
        p.position += p.velocity;
        p.opacity -= 0.04;
        p.life -= 0.04;
        p.size *= 0.96;
        if (p.life <= 0 || p.opacity <= 0) {
          particles.removeAt(i);
        }
      }

      if (screenShakeOffset != 0) {
        screenShakeOffset = -screenShakeOffset * 0.7;
        if (screenShakeOffset.abs() < 0.5) screenShakeOffset = 0.0;
      }
    });
  }

  void _spawnParticles(int index, Color color, {int count = 15}) {
    final random = Random();
    final Offset origin = _cellCentreInGridUnits(index);

    for (int i = 0; i < count; i++) {
      double angle = random.nextDouble() * 2 * pi;
      double speedFactor = 0.06 + random.nextDouble() * 0.16;
      particles.add(
        Particle(
          position: origin,
          velocity: Offset(cos(angle) * speedFactor, sin(angle) * speedFactor),
          color: color,
          size: 0.12 + random.nextDouble() * 0.16,
        ),
      );
    }
  }

  void _spawnFloatingScore(int index, String text, Color color) {
    floatingScores.add(
      FloatingScore(
        text: text,
        position: _cellCentreInGridUnits(index),
        color: color,
      ),
    );
  }

  /// Kat indeksini kata birlikdagi markaz koordinatasiga aylantiradi.
  /// (Ekran piksellarini bu yerda bilmaymiz — taxta AspectRatio bilan
  /// masshtablanadi, shuning uchun hisob kata birligida yuritiladi.)
  Offset _cellCentreInGridUnits(int index) =>
      Offset((index % colCount) + 0.5, (index ~/ colCount) + 0.5);

  void startGame() {
    setState(() {
      snake = [33, 32, 31];
      direction = Direction.right;
      nextDirection = Direction.right;
      score = 0;
      level = 1;
      speed = gameMode == GameMode.survival ? 130 : 200;
      eatenFoodCount = 0;
      bonusFood = -1;
      timeLeft = 60;
      floatingScores.clear();
      particles.clear();
      obstacles.clear();
      gameState = GameState.playing;

      if (gameMode == GameMode.obstacle || gameMode == GameMode.survival) {
        _generateObstacles();
      }

      generateNewFood();
    });

    resetTimer();

    if (gameMode == GameMode.timeAttack) {
      gameTimer?.cancel();
      gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (gameState == GameState.playing) {
          setState(() {
            if (timeLeft > 0) {
              timeLeft--;
            } else {
              t.cancel();
              _endGame();
            }
          });
        }
      });
    }
  }

  void _generateObstacles() {
    final random = Random();
    obstacles.clear();
    while (obstacles.length < 5) {
      int obs = random.nextInt(rowCount * colCount);
      if (!snake.contains(obs) && obs != food && !obstacles.contains(obs)) {
        obstacles.add(obs);
      }
    }
  }

  void resetTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: speed), (timer) {
      if (gameState == GameState.playing) {
        updateGame();
      }
    });
  }

  void togglePause() {
    setState(() {
      if (gameState == GameState.playing) {
        gameState = GameState.paused;
      } else if (gameState == GameState.paused) {
        gameState = GameState.playing;
      }
    });
  }

  void generateNewFood() {
    final List<int> free = _freeCells();
    if (free.isEmpty) {
      _endGame(won: true);
      return;
    }
    setState(() {
      food = free[Random().nextInt(free.length)];
    });
  }

  void generateBonusFood() {
    final List<int> free = _freeCells();
    if (free.isEmpty) return;

    setState(() {
      bonusFood = free[Random().nextInt(free.length)];
    });

    bonusTimer?.cancel();
    bonusTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          bonusFood = -1;
        });
      }
    });
  }

  /// Ilon, to'siqlar va mavjud ovqatlar band qilmagan katlar.
  List<int> _freeCells() {
    final Set<int> occupied = {...snake, ...obstacles, food, bonusFood};
    return [
      for (int i = 0; i < rowCount * colCount; i++)
        if (!occupied.contains(i)) i,
    ];
  }

  void updateGame() {
    setState(() {
      direction = nextDirection;
      int nextHead = getNextHeadPosition();

      if (checkCollision(nextHead)) {
        _endGame();
        return;
      }

      snake.insert(0, nextHead);

      if (nextHead == food) {
        score += (gameMode == GameMode.timeAttack ? 20 : 10);
        eatenFoodCount++;

        GameStorageService.addCoins(2);
        GameStorageService.addXp(10);

        bool vib = true;
        GameStorageService.isVibrationEnabled().then((v) => vib = v);
        if (vib) HapticFeedback.lightImpact();

        _spawnParticles(food, skinColors.first, count: 18);
        _spawnFloatingScore(food, gameMode == GameMode.timeAttack ? "+20" : "+10", skinColors.first);

        if (eatenFoodCount % 5 == 0) {
          level++;
          if (speed > 60) speed -= 12;
          resetTimer();
          generateBonusFood();
          _triggerLevelUpBanner(level);
        }

        generateNewFood();
      } else if (nextHead == bonusFood) {
        score += 30;
        GameStorageService.addCoins(5);
        GameStorageService.addXp(25);
        _spawnParticles(bonusFood, Colors.amberAccent, count: 25);
        _spawnFloatingScore(bonusFood, "+30", Colors.amberAccent);
        bonusFood = -1;

        HapticFeedback.mediumImpact();
      } else {
        snake.removeLast();
      }
    });
  }

  Future<void> _endGame({bool won = false}) async {
    timer?.cancel();
    bonusTimer?.cancel();
    gameTimer?.cancel();
    gameState = won ? GameState.won : GameState.gameOver;
    screenShakeOffset = won ? 0.0 : 12.0;

    bool vib = true;
    GameStorageService.isVibrationEnabled().then((v) => vib = v);
    if (vib) HapticFeedback.vibrate();

    bool isNewHigh = await GameStorageService.setHighScore(gameMode.name, score);
    if (isNewHigh) {
      highScore = score;
    }

    await GameStorageService.updateStats(foodDelta: eatenFoodCount, snakeLength: snake.length);

    // Ilon qizarib/e'tibor tortib ulgurishi uchun dialogni biroz kechiktiramiz
    await Future.delayed(const Duration(milliseconds: 450));

    if (mounted) {
      showGameOverDialog(won: won);
    }
  }

  void _triggerLevelUpBanner(int newLevel) {
    setState(() {
      showLevelUpBanner = true;
      currentLevelUp = newLevel;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showLevelUpBanner = false;
        });
      }
    });
  }

  int getNextHeadPosition() {
    int head = snake.first;
    int currentCol = head % colCount;

    if (gameMode == GameMode.endless || gameMode == GameMode.survival) {
      switch (direction) {
        case Direction.up:
          return head - colCount < 0 ? head - colCount + (rowCount * colCount) : head - colCount;
        case Direction.down:
          return (head + colCount) % (rowCount * colCount);
        case Direction.left:
          return currentCol == 0 ? head + colCount - 1 : head - 1;
        case Direction.right:
          return (currentCol + 1) % colCount == 0 ? head - colCount + 1 : head + 1;
      }
    } else {
      switch (direction) {
        case Direction.up:
          return head - colCount;
        case Direction.down:
          return head + colCount;
        case Direction.left:
          return head - 1;
        case Direction.right:
          return head + 1;
      }
    }
  }

  bool checkCollision(int nextHead) {
    if (snake.contains(nextHead)) return true;
    if (obstacles.contains(nextHead)) return true;

    if (gameMode == GameMode.classic || gameMode == GameMode.timeAttack || gameMode == GameMode.obstacle) {
      if (nextHead < 0 || nextHead >= rowCount * colCount) return true;

      int currentHeadCol = snake.first % colCount;
      if (direction == Direction.left && currentHeadCol == 0) return true;
      if (direction == Direction.right && currentHeadCol == colCount - 1) return true;
    }

    return false;
  }

  void changeDirection(Direction newDirection) {
    if (gameState != GameState.playing) return;
    if (newDirection == Direction.up && direction != Direction.down) nextDirection = Direction.up;
    if (newDirection == Direction.down && direction != Direction.up) nextDirection = Direction.down;
    if (newDirection == Direction.left && direction != Direction.right) nextDirection = Direction.left;
    if (newDirection == Direction.right && direction != Direction.left) nextDirection = Direction.right;
  }

  void showGameOverDialog({bool won = false}) {
    final Color accent = won ? Colors.greenAccent : Colors.redAccent;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accent, width: 1.5),
        ),
        title: Text(
          won ? "G'ALABA!" : "O'YIN TUGADI",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (won)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Butun taxtani to'ldirdingiz!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: accent, fontSize: 15),
                  ),
                ),
              Text("To'plangan ochko: $score", style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 8),
              Text("Erishilgan daraja: $level", style: const TextStyle(color: Colors.amberAccent, fontSize: 16)),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Return to main menu
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("BOSH MENYU", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    startGame();
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("QAYTA BOSHLASH", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    bonusTimer?.cancel();
    gameTimer?.cancel();
    _pulseController.dispose();
    _animationLoopController.dispose();
    super.dispose();
  }

  /// Stol (Windows/macOS/web) uchun klaviatura boshqaruvi.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      changeDirection(Direction.up);
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      changeDirection(Direction.down);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      changeDirection(Direction.left);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      changeDirection(Direction.right);
    } else if (key == LogicalKeyboardKey.space) {
      if (gameState == GameState.playing || gameState == GameState.paused) {
        togglePause();
      } else if (gameState == GameState.idle) {
        startGame();
      }
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (gameState == GameState.idle) startGame();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C10),
      body: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: _onKeyEvent,
          child: Transform.translate(
            offset: Offset(screenShakeOffset, 0),
            child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy < -2) changeDirection(Direction.up);
              if (details.delta.dy > 2) changeDirection(Direction.down);
            },
            onHorizontalDragUpdate: (details) {
              if (details.delta.dx < -2) changeDirection(Direction.left);
              if (details.delta.dx > 2) changeDirection(Direction.right);
            },
            child: Stack(
              children: [
                Column(
                  children: [
                    ScoreBoard(
                      score: score,
                      highScore: highScore,
                      level: level,
                      gameMode: gameMode,
                      onModeChanged: (mode) {
                        if (gameState == GameState.idle) {
                          setState(() => gameMode = mode);
                        }
                      },
                    ),
                    if (gameMode == GameMode.timeAttack)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "⏱️ Vaqt qoldi: ${timeLeft}s",
                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    GameBoard(
                      rowCount: rowCount,
                      colCount: colCount,
                      snake: snake,
                      food: food,
                      bonusFood: bonusFood,
                      direction: direction,
                      pulseValue: _pulseController.value,
                      floatingScores: floatingScores,
                      particles: particles,
                      skinColors: skinColors,
                      obstacles: obstacles,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0, left: 16, right: 16),
                      child: gameState == GameState.idle
                          ? AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                double scale = 1.0 + 0.03 * sin(_pulseController.value * 2 * pi);
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: skinColors.first.withValues(alpha: 0.35 + 0.15 * sin(_pulseController.value * 2 * pi)),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: skinColors.first,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        elevation: 12,
                                      ),
                                      onPressed: startGame,
                                      child: const Text(
                                        "B O S H L A S H",
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : _buildControlPanel(),
                    ),
                  ],
                ),
                // Level Up Banner Overlay
                if (showLevelUpBanner)
                  Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.amberAccent.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amberAccent.withValues(alpha: 0.6),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: const Text(
                                  "✨ DARAJA OSHDI! ✨",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                // Pauza pardasi
                if (gameState == GameState.paused)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.72),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "PAUZA",
                                  style: TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Davom ettirish uchun tugmani yoki bo'sh joyni bosing",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amberAccent,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: togglePause,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text(
                                  "DAVOM ETISH",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildControlPanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: togglePause,
          iconSize: 36,
          color: Colors.amberAccent,
          icon: Icon(gameState == GameState.playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
        ),
        Column(
          children: [
            _buildDpadBtn(Icons.keyboard_arrow_up, () => changeDirection(Direction.up)),
            Row(
              children: [
                _buildDpadBtn(Icons.keyboard_arrow_left, () => changeDirection(Direction.left)),
                const SizedBox(width: 40),
                _buildDpadBtn(Icons.keyboard_arrow_right, () => changeDirection(Direction.right)),
              ],
            ),
            _buildDpadBtn(Icons.keyboard_arrow_down, () => changeDirection(Direction.down)),
          ],
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildDpadBtn(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70),
        onPressed: onPressed,
        iconSize: 24,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }
}
