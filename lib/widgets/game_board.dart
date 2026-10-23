import 'dart:math';
import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../models/animation_models.dart';

class GameBoard extends StatelessWidget {
  final int rowCount;
  final int colCount;
  final List<int> snake;
  final int food;
  final int bonusFood;
  final Direction direction;
  final double pulseValue;
  final List<FloatingScore> floatingScores;
  final List<Particle> particles;
  final List<Color> skinColors;
  final List<int> obstacles;

  const GameBoard({
    super.key,
    required this.rowCount,
    required this.colCount,
    required this.snake,
    required this.food,
    required this.bonusFood,
    required this.direction,
    required this.pulseValue,
    required this.floatingScores,
    required this.particles,
    required this.skinColors,
    this.obstacles = const [],
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
              gradient: const LinearGradient(
                colors: [Color(0xFF030508), Color(0xFF0D1424)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: skinColors.first.withValues(alpha: 0.7 + 0.3 * sin(pulseValue * 2 * pi)),
                width: 3.0,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: skinColors.first.withValues(alpha: 0.35),
                  blurRadius: 35,
                  spreadRadius: 4,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: CustomPaint(
                painter: UltraSnakePainter(
                  rowCount: rowCount,
                  colCount: colCount,
                  snake: snake,
                  food: food,
                  bonusFood: bonusFood,
                  direction: direction,
                  pulseValue: pulseValue,
                  floatingScores: floatingScores,
                  particles: particles,
                  skinColors: skinColors,
                  obstacles: obstacles,
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
  final double pulseValue;
  final List<FloatingScore> floatingScores;
  final List<Particle> particles;
  final List<Color> skinColors;
  final List<int> obstacles;

  UltraSnakePainter({
    required this.rowCount,
    required this.colCount,
    required this.snake,
    required this.food,
    required this.bonusFood,
    required this.direction,
    required this.pulseValue,
    required this.floatingScores,
    required this.particles,
    required this.skinColors,
    required this.obstacles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double cellWidth = size.width / colCount;
    double cellHeight = size.height / rowCount;

    // Cyberpunk Neon Grid
    Paint gridPaint = Paint()
      ..color = skinColors.first.withValues(alpha: 0.045)
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

    // To'siqlar (Obstacles)
    for (int obs in obstacles) {
      double ox = (obs % colCount) * cellWidth + cellWidth / 2;
      double oy = (obs ~/ colCount) * cellHeight + cellHeight / 2;
      Paint obsGlow = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(ox, oy), cellWidth * 0.45, obsGlow);

      Paint obsPaint = Paint()..color = Colors.redAccent;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(ox, oy), width: cellWidth * 0.75, height: cellHeight * 0.75),
          const Radius.circular(8),
        ),
        obsPaint,
      );
    }

    // Zarrachalar va Trail (Particles)
    for (var particle in particles) {
      Paint particlePaint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(particle.position, particle.size, particlePaint);
    }

    // Ovqatlarni chizish
    _drawFood(canvas, food, cellWidth, cellHeight, Colors.redAccent, false);
    if (bonusFood != -1) {
      _drawFood(canvas, bonusFood, cellWidth, cellHeight, Colors.amberAccent, true);
    }

    if (snake.isNotEmpty) {
      for (int i = 0; i < snake.length - 1; i++) {
        int p1 = snake[i];
        int p2 = snake[i + 1];

        int r1 = p1 ~/ colCount;
        int c1 = p1 % colCount;
        int r2 = p2 ~/ colCount;
        int c2 = p2 % colCount;

        if ((r1 - r2).abs() <= 1 && (c1 - c2).abs() <= 1) {
          double x1 = c1 * cellWidth + cellWidth / 2;
          double y1 = r1 * cellHeight + cellHeight / 2;
          double x2 = c2 * cellWidth + cellWidth / 2;
          double y2 = r2 * cellHeight + cellHeight / 2;

          Paint glowLine = Paint()
            ..color = skinColors.first.withValues(alpha: 0.45)
            ..strokeWidth = cellWidth * 0.9
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), glowLine);

          Paint darkLine = Paint()
            ..color = const Color(0xFF081C0E)
            ..strokeWidth = cellWidth * 0.75;
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), darkLine);

          Paint coreLine = Paint()
            ..shader = LinearGradient(
              colors: skinColors,
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
            ..strokeWidth = cellWidth * 0.45
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), coreLine);
        }
      }

      for (int i = 0; i < snake.length; i++) {
        int pos = snake[i];
        double cx = (pos % colCount) * cellWidth + cellWidth / 2;
        double cy = (pos ~/ colCount) * cellHeight + cellHeight / 2;

        if (i == 0) {
          _drawCyberSnakeHead(canvas, snake.first, cellWidth, cellHeight);
        } else {
          Paint bodyDot = Paint()..color = skinColors.first;
          canvas.drawCircle(Offset(cx, cy), cellWidth * 0.32, bodyDot);
          Paint innerDot = Paint()..color = Colors.white.withValues(alpha: 0.85);
          canvas.drawCircle(Offset(cx, cy), cellWidth * 0.12, innerDot);
        }
      }
    }

    // Floating Score Matnlari
    for (var fs in floatingScores) {
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: fs.text,
          style: TextStyle(
            color: fs.color.withValues(alpha: fs.opacity.clamp(0.0, 1.0)),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: fs.color.withValues(alpha: 0.95), blurRadius: 12),
              const Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(fs.position.dx - textPainter.width / 2, fs.position.dy + fs.yOffset),
      );
    }
  }

  void _drawFood(Canvas canvas, int index, double cw, double ch, Color color, bool isBonus) {
    double cx = (index % colCount) * cw + cw / 2;
    double cy = (index ~/ colCount) * ch + ch / 2;
    
    double pulseScale = 1.0 + 0.22 * sin(pulseValue * 2 * pi);
    double radius = (cw / 2) * (isBonus ? 0.88 : 0.7) * pulseScale;

    Paint glow = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(cx, cy), radius + 6, glow);

    Paint foodPaint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), radius, foodPaint);

    Paint highlight = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(cx - radius * 0.3, cy - radius * 0.3), radius * 0.28, highlight);

    Paint stemPaint = Paint()
      ..color = Colors.green.shade300
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - radius), Offset(cx + 2, cy - radius - 7), stemPaint);
  }

  void _drawCyberSnakeHead(Canvas canvas, int headIndex, double cw, double ch) {
    double cx = (headIndex % colCount) * cw + cw / 2;
    double cy = (headIndex ~/ colCount) * ch + ch / 2;
    double radius = cw * 0.52;

    Paint headGlow = Paint()
      ..color = skinColors.first.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(cx, cy), radius + 5, headGlow);

    Paint headPaint = Paint()..color = skinColors.first;
    canvas.drawCircle(Offset(cx, cy), radius, headPaint);

    Paint innerHead = Paint()..color = skinColors.length > 1 ? skinColors[1] : skinColors.first;
    canvas.drawCircle(Offset(cx, cy), radius * 0.68, innerHead);

    double eyeOffset = radius * 0.45;
    Offset leftEye = Offset.zero;
    Offset rightEye = Offset.zero;
    Offset tongueStart = Offset(cx, cy);
    Offset tongueEnd = Offset.zero;

    switch (direction) {
      case Direction.up:
        leftEye = Offset(cx - eyeOffset, cy - eyeOffset * 0.4);
        rightEye = Offset(cx + eyeOffset, cy - eyeOffset * 0.4);
        tongueEnd = Offset(cx, cy - radius - 12);
        break;
      case Direction.down:
        leftEye = Offset(cx - eyeOffset, cy + eyeOffset * 0.4);
        rightEye = Offset(cx + eyeOffset, cy + eyeOffset * 0.4);
        tongueEnd = Offset(cx, cy + radius + 12);
        break;
      case Direction.left:
        leftEye = Offset(cx - eyeOffset * 0.4, cy - eyeOffset);
        rightEye = Offset(cx - eyeOffset * 0.4, cy + eyeOffset);
        tongueEnd = Offset(cx - radius - 12, cy);
        break;
      case Direction.right:
        leftEye = Offset(cx + eyeOffset * 0.4, cy - eyeOffset);
        rightEye = Offset(cx + eyeOffset * 0.4, cy + eyeOffset);
        tongueEnd = Offset(cx + radius + 12, cy);
        break;
    }

    Paint tonguePaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(tongueStart, tongueEnd, tonguePaint);

    Paint cyanGlow = Paint()
      ..color = Colors.cyanAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(leftEye, 5.0, cyanGlow);
    canvas.drawCircle(rightEye, 5.0, cyanGlow);

    Paint whiteEye = Paint()..color = Colors.white;
    Paint darkPupil = Paint()..color = Colors.black;

    canvas.drawCircle(leftEye, 3.8, whiteEye);
    canvas.drawCircle(leftEye, 1.9, darkPupil);

    canvas.drawCircle(rightEye, 3.8, whiteEye);
    canvas.drawCircle(rightEye, 1.9, darkPupil);
  }

  @override
  bool shouldRepaint(covariant UltraSnakePainter oldDelegate) {
    return oldDelegate.snake != snake ||
        oldDelegate.food != food ||
        oldDelegate.bonusFood != bonusFood ||
        oldDelegate.direction != direction ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.floatingScores != floatingScores ||
        oldDelegate.particles != particles ||
        oldDelegate.skinColors != skinColors ||
        oldDelegate.obstacles != obstacles;
  }
}
