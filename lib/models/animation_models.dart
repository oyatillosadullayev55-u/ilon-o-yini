import 'package:flutter/material.dart';

/// Suzib chiquvchi ochko yozuvi. [position] kata (grid) birliklarida:
/// x 0..colCount, y 0..rowCount. [z] — pol ustidagi balandlik (kata ulushida).
class FloatingScore {
  final String text;
  final Offset position;
  final Color color;
  double opacity;
  double z;

  FloatingScore({
    required this.text,
    required this.position,
    required this.color,
    this.opacity = 1.0,
    this.z = 0.6,
  });
}

/// Portlash zarachasi. [position] va [velocity] kata birliklarida,
/// [z]/[vz] — balandlik va undagi tezlik, [size] kata tomonining ulushi.
class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double opacity;
  double life;
  double z;
  double vz;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    this.opacity = 1.0,
    this.life = 1.0,
    this.z = 0.45,
    this.vz = 0.09,
  });
}
