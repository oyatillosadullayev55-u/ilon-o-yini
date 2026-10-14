import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Vibratsiya (HapticFeedback) uchun
import '../models/direction.dart';
import '../widgets/game_board.dart';
import '../widgets/score_board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int rowCount = 20;
  static const int colCount = 15;

  List<int> snake = [45, 44, 43];
  int food = 100;
  int bonusFood = -1;
  Direction direction = Direction.right;
  Timer? timer;
  Timer? bonusTimer;

  GameMode gameMode = GameMode.classic;
  GameState gameState = GameState.idle;

  int score = 0;
  int highScore = 0;
  int level = 1;
  int speed = 200;
  int eatenFoodCount = 0;

  void startGame() {
    setState(() {
      snake = [45, 44, 43];
      direction = Direction.right;
      score = 0;
      level = 1;
      speed = 200;
      eatenFoodCount = 0;
      bonusFood = -1;
      gameState = GameState.playing;
      generateNewFood();
    });

    resetTimer();
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
    final random = Random();
    int newFood;
    do {
      newFood = random.nextInt(rowCount * colCount);
    } while (snake.contains(newFood) || newFood == bonusFood);

    setState(() {
      food = newFood;
    });
  }

  void generateBonusFood() {
    final random = Random();
    int newBonus;
    do {
      newBonus = random.nextInt(rowCount * colCount);
    } while (snake.contains(newBonus) || newBonus == food);

    setState(() {
      bonusFood = newBonus;
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

  void updateGame() {
    setState(() {
      int nextHead = getNextHeadPosition();

      // Devorga yoki o'ziga urilganda
      if (checkCollision(nextHead)) {
        timer?.cancel();
        bonusTimer?.cancel();
        gameState = GameState.gameOver;

        // Game Over bo'lganda kuchliroq vibratsiya berish
        HapticFeedback.vibrate();

        if (score > highScore) {
          highScore = score;
        }
        showGameOverDialog();
        return;
      }

      snake.insert(0, nextHead);

      // Oddiy ovqat yeyilganda
      if (nextHead == food) {
        score += 10;
        eatenFoodCount++;

        // Qisqa va yengil vibratsiya
        HapticFeedback.lightImpact();

        if (eatenFoodCount % 5 == 0) {
          level++;
          if (speed > 70) speed -= 15;
          resetTimer();
          generateBonusFood();
        }

        generateNewFood();
      }
      // Bonus ovqat yeyilganda
      else if (nextHead == bonusFood) {
        score += 30;
        bonusFood = -1;

        // Bonus yemak uchun ham vibratsiya
        HapticFeedback.mediumImpact();
      } else {
        snake.removeLast();
      }
    });
  }

  int getNextHeadPosition() {
    int head = snake.first;
    int currentCol = head % colCount;

    if (gameMode == GameMode.endless) {
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

    if (gameMode == GameMode.classic) {
      if (nextHead < 0 || nextHead >= rowCount * colCount) return true;

      int currentHeadCol = snake.first % colCount;
      if (direction == Direction.left && currentHeadCol == 0) return true;
      if (direction == Direction.right && currentHeadCol == colCount - 1) return true;
    }

    return false;
  }

  void changeDirection(Direction newDirection) {
    if (gameState != GameState.playing) return;
    if (newDirection == Direction.up && direction != Direction.down) direction = Direction.up;
    if (newDirection == Direction.down && direction != Direction.up) direction = Direction.down;
    if (newDirection == Direction.left && direction != Direction.right) direction = Direction.left;
    if (newDirection == Direction.right && direction != Direction.left) direction = Direction.right;
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        title: const Text(
          "O'YIN TUGADI",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("To'plangan ochko: $score", style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text("Erishilgan daraja: $level", style: const TextStyle(color: Colors.amberAccent, fontSize: 16)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
              child: const Text("QAYTA BOSHLASH", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    bonusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C10),
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy < -2) changeDirection(Direction.up);
            if (details.delta.dy > 2) changeDirection(Direction.down);
          },
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx < -2) changeDirection(Direction.left);
            if (details.delta.dx > 2) changeDirection(Direction.right);
          },
          child: Column(
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
              GameBoard(
                rowCount: rowCount,
                colCount: colCount,
                snake: snake,
                food: food,
                bonusFood: bonusFood,
                direction: direction,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0, left: 16, right: 16),
                child: gameState == GameState.idle
                    ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 10,
                    shadowColor: Colors.greenAccent.withOpacity(0.5),
                  ),
                  onPressed: startGame,
                  child: const Text(
                    "B O S H L A S H",
                    style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
                    : _buildControlPanel(),
              ),
            ],
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