import 'package:flutter/material.dart';

/// Suzib chiquvchi ochko yozuvi. [position] va [yOffset] kata (grid)
/// birliklarida: x 0..colCount, y 0..rowCount oraliqda.
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

/// Portlash zarachasi. [position] va [velocity] kata birliklarida,
/// [size] esa kata tomonining ulushida (0..1).
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
