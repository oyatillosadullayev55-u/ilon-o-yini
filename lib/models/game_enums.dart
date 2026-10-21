import 'package:flutter/material.dart';

enum Direction { up, down, left, right }

enum GameMode {
  classic,
  endless,
  timeAttack,
  obstacle,
  challenge,
  survival,
}

enum GameState { idle, playing, paused, gameOver }

class SnakeSkinInfo {
  final String id;
  final String name;
  final int price;
  final List<Color> colors;

  const SnakeSkinInfo({
    required this.id,
    required this.name,
    required this.price,
    required this.colors,
  });
}

class GameSkins {
  static const List<SnakeSkinInfo> availableSkins = [
    SnakeSkinInfo(id: 'classic', name: 'Classic Neon', price: 0, colors: [Colors.greenAccent, Colors.cyanAccent]),
    SnakeSkinInfo(id: 'fire', name: 'Fire Snake', price: 50, colors: [Colors.deepOrange, Colors.amber]),
    SnakeSkinInfo(id: 'ice', name: 'Ice Snake', price: 100, colors: [Colors.lightBlueAccent, Colors.indigoAccent]),
    SnakeSkinInfo(id: 'galaxy', name: 'Galaxy Snake', price: 200, colors: [Colors.purpleAccent, Colors.pinkAccent]),
    SnakeSkinInfo(id: 'golden', name: 'Golden Snake', price: 500, colors: [Colors.amber, Colors.yellowAccent]),
  ];
}
