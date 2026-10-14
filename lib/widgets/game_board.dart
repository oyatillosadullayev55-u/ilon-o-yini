import 'dart:math';
import 'package:flutter/material.dart';
import '../models/direction.dart';

class GameBoard extends StatelessWidget {
  final int rowCount;
  final int colCount;
  final List<int> snake;
  final int food;
  final int bonusFood;
  final Direction direction;

  const GameBoard({
    super.key,
    required this.rowCount,
    required this.colCount,
    required this.snake,
    required this.food,
    required this.bonusFood,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: AspectRatio(
          aspectRatio: colCount / rowCount,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent.withOpacity(0.6), width: 2.5),
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF070B12),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.2),
                  blurRadius: 25,
                  spreadRadius: 2,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: CustomPaint(
                painter: UltraSnakePainter(
                  rowCount: rowCount,
                  colCount: colCount,
                  snake: snake,
                  food: food,
                  bonusFood: bonusFood,
                  direction: direction,
                ),
                child: Container(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UltraSnakePainter extends CustomPainter {
  final int rowCount;
  final int colCount;
  final List<int> snake;
  final int food;
  final int bonusFood;
  final Direction direction;

  UltraSnakePainter({
    required this.rowCount,
    required this.colCount,
    required this.snake,
    required this.food,
    required this.bonusFood,
    required this.direction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double cellWidth = size.width / colCount;
    double cellHeight = size.height / rowCount;

    // Grid Panjarasini chizish
    Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int r = 0; r < rowCount; r++) {
      for (int c = 0; c < colCount; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * cellWidth, r * cellHeight, cellWidth, cellHeight),
          gridPaint,
        );
      }
    }

    // Ovqatlarni chizish
    _drawFood(canvas, food, cellWidth, cellHeight, Colors.redAccent, false);
    if (bonusFood != -1) {
      _drawFood(canvas, bonusFood, cellWidth, cellHeight, Colors.amberAccent, true);
    }

    if (snake.isEmpty) return;

    // Ilon tanasini chizish (Multi-layer Glow & Path)
    Path snakePath = Path();
    for (int i = 0; i < snake.length; i++) {
      int pos = snake[i];
      double cx = (pos % colCount) * cellWidth + cellWidth / 2;
      double cy = (pos ~/ colCount) * cellHeight + cellHeight / 2;

      if (i == 0) {
        snakePath.moveTo(cx, cy);
      } else {
        snakePath.lineTo(cx, cy);
      }
    }

    // Tana atrofiga Neon Porlash (Outer Glow)
    Paint glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.greenAccent.withOpacity(0.35)
      ..strokeWidth = cellWidth * 0.85
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(snakePath, glowPaint);

    // Tana asosi (Dark Green Base)
    Paint darkBodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = cellWidth * 0.7;
    canvas.drawPath(snakePath, darkBodyPaint);

    // Tana ustki chizig'i (Neon Core)
    Paint coreBodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.greenAccent
      ..strokeWidth = cellWidth * 0.4;
    canvas.drawPath(snakePath, coreBodyPaint);

    // Ilon boshi, ko'zlari va tili
    _drawSnakeHead(canvas, snake.first, cellWidth, cellHeight);
  }

  void _drawFood(Canvas canvas, int index, double cw, double ch, Color color, bool isBonus) {
    double cx = (index % colCount) * cw + cw / 2;
    double cy = (index ~/ colCount) * ch + ch / 2;
    double radius = (cw / 2) * (isBonus ? 0.8 : 0.65);

    Paint glow = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(cx, cy), radius + 3, glow);

    Paint foodPaint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), radius, foodPaint);

    // Yemak ustidagi barg/poya
    Paint stemPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(cx, cy - radius), Offset(cx + 2, cy - radius - 4), stemPaint);
  }

  void _drawSnakeHead(Canvas canvas, int headIndex, double cw, double ch) {
    double cx = (headIndex % colCount) * cw + cw / 2;
    double cy = (headIndex ~/ colCount) * ch + ch / 2;
    double radius = cw * 0.45;

    // Boshdagi Glow va shakl
    Paint headGlow = Paint()
      ..color = Colors.greenAccent.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), radius + 2, headGlow);

    Paint headPaint = Paint()..color = Colors.greenAccent;
    canvas.drawCircle(Offset(cx, cy), radius, headPaint);

    double eyeOffset = radius * 0.45;
    Offset leftEye = Offset.zero;
    Offset rightEye = Offset.zero;
    Offset tongueStart = Offset(cx, cy);
    Offset tongueEnd = Offset.zero;

    switch (direction) {
      case Direction.up:
        leftEye = Offset(cx - eyeOffset, cy - eyeOffset / 2);
        rightEye = Offset(cx + eyeOffset, cy - eyeOffset / 2);
        tongueEnd = Offset(cx, cy - radius - 7);
        break;
      case Direction.down:
        leftEye = Offset(cx - eyeOffset, cy + eyeOffset / 2);
        rightEye = Offset(cx + eyeOffset, cy + eyeOffset / 2);
        tongueEnd = Offset(cx, cy + radius + 7);
        break;
      case Direction.left:
        leftEye = Offset(cx - eyeOffset / 2, cy - eyeOffset);
        rightEye = Offset(cx - eyeOffset / 2, cy + eyeOffset);
        tongueEnd = Offset(cx - radius - 7, cy);
        break;
      case Direction.right:
        leftEye = Offset(cx + eyeOffset / 2, cy - eyeOffset);
        rightEye = Offset(cx + eyeOffset / 2, cy + eyeOffset);
        tongueEnd = Offset(cx + radius + 7, cy);
        break;
    }

    // Arayali Qizil Til
    Paint tonguePaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(tongueStart, tongueEnd, tonguePaint);

    // Aniq va chiroyli Ko'zlar
    Paint whiteEye = Paint()..color = Colors.white;
    Paint blackPupil = Paint()..color = Colors.black;

    canvas.drawCircle(leftEye, 3.5, whiteEye);
    canvas.drawCircle(leftEye, 1.8, blackPupil);

    canvas.drawCircle(rightEye, 3.5, whiteEye);
    canvas.drawCircle(rightEye, 1.8, blackPupil);
  }

  @override
  bool shouldRepaint(covariant UltraSnakePainter oldDelegate) {
    return oldDelegate.snake != snake ||
        oldDelegate.food != food ||
        oldDelegate.bonusFood != bonusFood ||
        oldDelegate.direction != direction;
  }
}