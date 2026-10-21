import 'package:flutter/material.dart';

class FloatingScore {
  final String text;
  final Offset position;
  final Color color;
  double opacity;
  double yOffset;

  FloatingScore({
    required this.text,
    required this.position,
    required this.color,
    this.opacity = 1.0,
    this.yOffset = 0.0,
  });
}

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double opacity;
  double life;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    this.opacity = 1.0,
    this.life = 1.0,
  });
}
