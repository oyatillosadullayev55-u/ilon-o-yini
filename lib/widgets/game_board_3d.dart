import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/animation_models.dart';
import '../models/direction.dart';
import '../render3d/scene3d.dart';

/// 3D kubning biri yoqi: burchak indekslari va yorug'lik koeffitsienti.
class _BoxFace {
  final List<int> idx;
  final double shade;

  const _BoxFace(this.idx, this.shade);
}

/// 3D sahnani o'lcham-mustaqil ko'rinishda chizuvchi vidget.
class SnakeScene3D extends StatelessWidget {
  final int rowCount;
  final int colCount;
  final List<int> snake;
  final int food;
  final int bonusFood;
  final Direction direction;
  final double pulseValue;
  final double timeValue;
  final double interpolation;
  final int prevLength;
  final double deathGlow;
  final List<FloatingScore> floatingScores;
  final List<Particle> particles;
  final List<Color> skinColors;
  final List<int> obstacles;
  final bool wraps;
  final double radius;

  const SnakeScene3D({
    super.key,
    required this.rowCount,
    required this.colCount,
    required this.snake,
    required this.food,
    required this.bonusFood,
    required this.direction,
    required this.pulseValue,
    required this.timeValue,
    this.floatingScores = const [],
    this.particles = const [],
    required this.skinColors,
    this.interpolation = 1.0,
    this.prevLength = 0,
    this.deathGlow = 0.0,
    this.obstacles = const [],
    this.wraps = false,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final accent = skinColors.first;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.12),
            const Color(0xFF04070F),
            const Color(0xFF020408),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.45 + 0.35 * sin(pulseValue * 2 * pi)),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 40, spreadRadius: 3),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 2.0),
        child: CustomPaint(
          painter: Scene3DPainter(
            rowCount: rowCount,
            colCount: colCount,
            snake: snake,
            food: food,
            bonusFood: bonusFood,
            direction: direction,
            pulseValue: pulseValue,
            timeValue: timeValue,
            interpolation: interpolation,
            prevLength: prevLength,
            deathGlow: deathGlow,
            floatingScores: floatingScores,
            particles: particles,
            skinColors: skinColors,
            obstacles: obstacles,
            wraps: wraps,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class Scene3DPainter extends CustomPainter {
  final int rowCount;
  final int colCount;
  final List<int> snake;
  final int food;
  final int bonusFood;
  final Direction direction;
  final double pulseValue;
  final double timeValue;
  final double interpolation;
  final int prevLength;
  final double deathGlow;
  final List<FloatingScore> floatingScores;
  final List<Particle> particles;
  final List<Color> skinColors;
  final List<int> obstacles;
  final bool wraps;

  Scene3DPainter({
    required this.rowCount,
    required this.colCount,
    required this.snake,
    required this.food,
    required this.bonusFood,
    required this.direction,
    required this.pulseValue,
    required this.timeValue,
    required this.floatingScores,
    required this.particles,
    required this.skinColors,
    required this.obstacles,
    this.interpolation = 1.0,
    this.prevLength = 0,
    this.deathGlow = 0.0,
    this.wraps = false,
  });

  static const double _step = 0.24;

  final Map<int, Paint> _ballPaints = {};
  final Map<int, Paint> _decals = {};

  late Canvas _c;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 8 || size.height < 8) return;
    _c = canvas;

    final scene = Scene3D(
      size: size,
      cols: colCount,
      rows: rowCount,
      elevation: 0.80 + 0.02 * sin(timeValue * 0.4),
      yaw: 0.05 * sin(timeValue * 0.55),
      fill: 0.95,
      autoTiltTo: 1.24,
    );
    final cell = scene.cellPx;

    _drawSky(canvas, size);
    _drawFloor(canvas, scene, cell);
    _drawFarWalls(canvas, scene);

    final solids = <DepthSorted>[];
    _buildObstacles(scene, solids);
    _buildFood(scene, solids);
    _buildSnake(canvas, scene, cell, solids);

    solids.sort((a, b) => b.depth.compareTo(a.depth));
    for (final s in solids) {
      s.paint();
    }
    for (final overlay in _overlays) {
      overlay();
    }
    _overlays.clear();

    _drawParticles(canvas, scene);
    _drawFloatingScores(canvas, scene);
    if (deathGlow > 0) _drawDeathRing(canvas, scene);
  }

  // ------------------------------------------------------------- fon / pol

  void _drawSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final primary = _skinAt(0);

    // Boyitilgan cyber-gradient fon (qora bo'shliqlarni yo'qotib, neon nur beradi)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, size.height * 0.4),
          size.width * 0.85,
          [
            primary.withValues(alpha: 0.18),
            const Color(0xFF060B14),
            const Color(0xFF020408),
          ],
          [0.0, 0.55, 1.0],
        ),
    );

    // Nur taratuvchi markaziy nur dog'i
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.25);
    canvas.scale(size.width * 0.85, size.height * 0.35);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primary.withValues(alpha: 0.22 - 0.12 * deathGlow),
            primary.withValues(alpha: 0.0),
          ],
        ).createShader(const Rect.fromLTRB(-1, -1, 1, 1)),
    );
    canvas.restore();

    // Yulduzlar / yorug' zarrachalar
    final star = Paint()..color = Colors.white;
    for (int i = 0; i < 40; i++) {
      final sx = ((i * 137.5) % 100) / 100 * size.width;
      final sy = ((i * 61.3) % 60) / 60 * size.height * 0.55;
      final tw = (0.2 + 0.5 * pow(sin(timeValue * 1.6 + i * 1.7) * 0.5 + 0.5, 2.2)).clamp(0.0, 0.7);
      star.color = primary.withValues(alpha: tw * 0.8);
      canvas.drawCircle(Offset(sx, sy), size.width * 0.0024 + (i % 3) * 0.4, star);
    }
  }

  List<List<Projected>> _cornerGrid(Scene3D scene) => [
        for (int r = 0; r <= rowCount; r++)
          [
            for (int c = 0; c <= colCount; c++) scene.project(V3(c.toDouble(), r.toDouble(), 0)),
          ],
      ];

  void _drawFloor(Canvas canvas, Scene3D scene, double cell) {
    final g = _cornerGrid(scene);
    final outer = Path()
      ..addPolygon(
        [g[0][0].screen, g[0][colCount].screen, g[rowCount][colCount].screen, g[rowCount][0].screen],
        true,
      );

    canvas.save();
    canvas.clipPath(outer);

    // Pol dizayni: neon gradient va cyber tekstura
    canvas.drawPath(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F1E36), Color(0xFF14243D), Color(0xFF09121E)],
        ).createShader(scene.screenBounds()),
    );

    // Katakcha dizayni (Checkerboard design with cyber glow)
    final tilePaint = Paint()..color = Colors.cyanAccent.withValues(alpha: 0.06);
    final tile = Path();
    for (int r = 0; r < rowCount; r++) {
      for (int c = 0; c < colCount; c++) {
        if ((r + c) % 2 != 0) continue;
        tile.reset();
        tile.addPolygon(
          [g[r][c].screen, g[r][c + 1].screen, g[r + 1][c + 1].screen, g[r + 1][c].screen],
          true,
        );
        canvas.drawPath(tile, tilePaint);
      }
    }

    // Neon grid panjarasi va tugun nuqtalari (Cyber nodes)
    final neon = wraps ? Colors.cyanAccent : _skinAt(0);
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.8, cell * 0.022)
      ..color = neon.withValues(alpha: 0.32);

    for (int r = 0; r <= rowCount; r++) {
      canvas.drawLine(g[r][0].screen, g[r][colCount].screen, gridPaint);
    }
    for (int c = 0; c <= colCount; c++) {
      canvas.drawLine(g[0][c].screen, g[rowCount][c].screen, gridPaint);
    }

    // Grid kesishmalarida yorug' neon nuqtalar (Cyber intersection nodes)
    final nodePaint = Paint()..color = neon.withValues(alpha: 0.65);
    for (int r = 0; r <= rowCount; r += 2) {
      for (int c = 0; c <= colCount; c += 2) {
        canvas.drawCircle(g[r][c].screen, max(1.2, cell * 0.04), nodePaint);
      }
    }

    canvas.restore();

    // Pol chegarasiga neon porlash (Neon border glow)
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, cell * 0.06)
        ..color = neon.withValues(alpha: 0.65)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, cell * 0.18),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.2, cell * 0.035)
        ..color = neon,
    );
  }

  void _drawFarWalls(Canvas canvas, Scene3D scene) {
    const h = 0.6;
    final rim = wraps ? Colors.cyanAccent : _skinAt(0);

    void wall(List<V3> base) {
      final top = [for (final p in base) scene.project(V3(p.x, p.y, h))].map((e) => e.screen);
      final bottom = [for (final p in base) scene.project(V3(p.x, p.y, 0))].map((e) => e.screen);
      canvas.drawPath(
        Path()..addPolygon([...top, ...bottom.toList().reversed], true),
        Paint()
          ..shader = ui.Gradient.linear(
            top.first,
            bottom.first,
            [rim.withValues(alpha: 0.35), rim.withValues(alpha: 0.02)],
          ),
      );
      canvas.drawPath(
        Path()..addPolygon(top.toList(), false),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = rim.withValues(alpha: 0.85),
      );
    }

    wall([V3(0, 0), V3(colCount.toDouble(), 0)]);
    wall([V3(0, 0), V3(0, rowCount.toDouble())]);
    wall([V3(colCount.toDouble(), 0), V3(colCount.toDouble(), rowCount.toDouble())]);
  }

  // ------------------------------------------------------- material yordamchi

  int _quant(Color c) => ((c.r * 31).toInt() << 10) | ((c.g * 31).toInt() << 5) | (c.b * 31).toInt();

  Paint _ballPaint(Color base) {
    final key = _quant(base);
    final cached = _ballPaints[key];
    if (cached != null) return cached;
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.34, -0.42),
        radius: 1.42,
        colors: [
          Color.lerp(base, Colors.white, 0.42)!,
          base,
          Color.lerp(base, const Color(0xFF03060A), 0.72)!,
        ],
        stops: const [0.0, 0.46, 1.0],
      ).createShader(const Rect.fromLTRB(-1, -1, 1, 1));
    _ballPaints[key] = paint;
    return paint;
  }

  Paint _decalPaint(Color color, double alpha) {
    final key = _quant(color) * 16 + (alpha * 12).round();
    final cached = _decals[key];
    if (cached != null) return cached;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0.0)],
        stops: const [0.32, 1.0],
      ).createShader(const Rect.fromLTRB(-1, -1, 1, 1));
    _decals[key] = paint;
    return paint;
  }

  void _unitCircle(Canvas canvas, Offset centre, double radius, Paint paint) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(max(radius, 0.01));
    canvas.drawCircle(Offset.zero, 1, paint);
    canvas.restore();
  }

  void _floorDecal(Canvas canvas, Offset centre, double rx, double squash, Paint paint) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(max(rx, 0.01), max(rx * squash, 0.01));
    canvas.drawRect(const Rect.fromLTRB(-1, -1, 1, 1), paint);
    canvas.restore();
  }

  Color _skinAt(double k) {
    Color c;
    if (skinColors.length <= 1) {
      c = skinColors.first;
    } else {
      final pos = k.clamp(0.0, 1.0) * (skinColors.length - 1);
      final i = pos.floor().clamp(0, skinColors.length - 2);
      c = Color.lerp(skinColors[i], skinColors[i + 1], pos - i)!;
    }
    return deathGlow > 0 ? Color.lerp(c, const Color(0xFFB01414), deathGlow)! : c;
  }

  // ------------------------------------------------------------------- ilon

  V3 _cellCentre(int index, {double z = 0}) =>
      V3((index % colCount) + 0.5, (index ~/ colCount) + 0.5, z);

  List<V3> _movingPath() {
    final n = snake.length;
    if (n == 0) return const [];
    final pts = [for (final i in snake) _cellCentre(i)];
    if (n == 1) return pts;

    final poly = <V3>[];
    final wrapped = (pts[1] - pts.first).abs() > 1.8;
    poly.add(wrapped ? pts.first : pts[1].lerp(pts.first, interpolation));
    for (int i = 1; i < n; i++) {
      poly.add(pts[i]);
    }
    if (n <= prevLength) {
      final dir = pts[n - 1] - pts[n - 2];
      final len = dir.abs();
      if (len > 0.1 && len < 1.8) {
        poly.add(pts[n - 1] + V3(dir.x / len, dir.y / len, 0) * (len * (1.0 - interpolation)));
      }
    }
    return poly;
  }

  void _buildSnake(Canvas canvas, Scene3D scene, double cell, List<DepthSorted> solids) {
    final path = _movingPath();
    if (path.isEmpty) return;

    final chains = <List<V3>>[];
    var current = <V3>[path.first];
    for (int i = 1; i < path.length; i++) {
      if ((path[i] - path[i - 1]).abs() > 1.8) {
        chains.add(current);
        current = <V3>[path[i]];
      } else {
        current.add(path[i]);
      }
    }
    chains.add(current);

    final arcs = [for (final chain in chains) _arcLengths(chain)];
    double totalLen = 0;
    for (final a in arcs) {
      totalLen += a.last;
    }
    if (totalLen <= 0) totalLen = 1;

    for (final chain in chains) {
      if (chain.length < 2) continue;
      canvas.drawPath(
        Path()..addPolygon([for (final p in chain) scene.project(p).screen], false),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = cell * 0.55
          ..color = _skinAt(0).withValues(alpha: 0.16 * (1 - deathGlow))
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, cell * 0.26),
      );
    }

    double offset = 0;
    int sample = 0;
    for (int ci = 0; ci < chains.length; ci++) {
      final chain = chains[ci];
      final arc = arcs[ci];
      for (double s = 0; s <= arc.last; s += _step) {
        final p = _pointAt(chain, arc, s);
        final r = _radiusAt(s + offset, totalLen);
        final floor = scene.project(V3(p.x, p.y, 0.005));
        _floorDecal(
          canvas,
          floor.screen,
          r * floor.unit * 1.2,
          0.4,
          _decalPaint(Colors.black, 0.34),
        );
      }
      for (double s = 0; s <= arc.last; s += _step) {
        final p = _pointAt(chain, arc, s);
        final r = _radiusAt(s + offset, totalLen);
        final pr = scene.project(V3(p.x, p.y, r * 0.88));
        final paint = _ballPaint(_skinAt((s + offset) / totalLen));
        final rPx = r * pr.unit;
        final glossy = pr.perspective > 0.82 && (sample % 3 == 0);
        sample++;
        solids.add(
          DepthSorted(pr.depth, () {
            _unitCircle(_c, pr.screen, rPx, paint);
            if (glossy) {
              _unitCircle(
                _c,
                pr.screen + Offset(-rPx * 0.30, -rPx * 0.40),
                rPx * 0.18,
                Paint()..color = Colors.white.withValues(alpha: 0.22),
              );
            }
          }),
        );
      }

      final belly = Path();
      bool started = false;
      for (double s = 0; s <= arc.last; s += _step * 2) {
        final p = _pointAt(chain, arc, s);
        final r = _radiusAt(s + offset, totalLen);
        final pr = scene.project(V3(p.x, p.y, r * 1.55));
        if (!started) {
          belly.moveTo(pr.screen.dx, pr.screen.dy);
          started = true;
        } else {
          belly.lineTo(pr.screen.dx, pr.screen.dy);
        }
      }
      _overlays.add(() {
        _c.drawPath(
          belly,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = cell * 0.14
            ..color = Colors.black.withValues(alpha: 0.16),
        );
        _c.drawPath(
          belly.shift(Offset(-cell * 0.08, -cell * 0.05)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = cell * 0.06
            ..color = Colors.white.withValues(alpha: 0.13),
        );
      });
      offset += arc.last;
    }

    const headR = 0.47;
    final headWorld = V3(path.first.x, path.first.y, headR * 0.84);
    final headPr = scene.project(headWorld);
    _floorDecal(
      canvas,
      scene.project(V3(path.first.x, path.first.y, 0.005)).screen,
      headR * headPr.unit * 1.3,
      0.4,
      _decalPaint(Colors.black, 0.42),
    );
    solids.add(DepthSorted(headPr.depth - 0.02, () => _drawHead(scene, path, headPr)));
  }

  final List<void Function()> _overlays = [];

  void _drawHead(Scene3D scene, List<V3> path, Projected pr) {
    const headR = 0.47;
    final canvas = _c;
    final head = V3(path.first.x, path.first.y, headR * 0.84);
    final rPx = headR * pr.unit;

    V3 fwd;
    if (path.length > 1) {
      final d = path.first - path[1];
      final len = d.abs();
      fwd = (len > 0.1 && len < 1.8) ? V3(d.x / len, d.y / len, 0) : _directionVector;
    } else {
      fwd = _directionVector;
    }

    final ahead = scene.project(V3(head.x + fwd.x * 0.85, head.y + fwd.y * 0.85, head.z));
    var dir = ahead.screen - pr.screen;
    if (dir.distance < 0.01) dir = const Offset(0, -1);
    dir /= dir.distance;

    final angle = atan2(dir.dy, dir.dx);
    canvas.save();
    canvas.translate(pr.screen.dx, pr.screen.dy);
    canvas.rotate(angle);
    canvas.scale(rPx, rPx);

    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.5,
        colors: [
          Color.lerp(_skinAt(0), Colors.white, 0.5)!,
          _skinAt(0),
          Color.lerp(_skinAt(0), const Color(0xFF03060A), 0.72)!,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(const Rect.fromLTRB(-1.05, -1.05, 1.05, 1.05));

    canvas.drawPath(
      Path()
        ..moveTo(-0.95, 0)
        ..cubicTo(-0.95, -0.86, 0.35, -0.95, 0.92, -0.26)
        ..cubicTo(1.05, -0.05, 1.05, 0.05, 0.92, 0.26)
        ..cubicTo(0.35, 0.95, -0.95, 0.86, -0.95, 0)
        ..close(),
      headPaint,
    );

    final irisColor = deathGlow > 0.35 ? const Color(0xFFFF5555) : Colors.amberAccent;
    for (final side in const [-1.0, 1.0]) {
      final eye = Offset(0.18, side * 0.40);
      canvas.drawOval(
        Rect.fromCenter(center: eye, width: 0.52, height: 0.40),
        Paint()..color = Colors.white.withValues(alpha: 0.94),
      );
      canvas.drawOval(
        Rect.fromCenter(center: eye + const Offset(0.05, 0), width: 0.30, height: 0.30),
        Paint()..color = irisColor.withValues(alpha: 0.95),
      );
      canvas.drawOval(
        Rect.fromCenter(center: eye + const Offset(0.06, 0), width: 0.09, height: 0.26),
        Paint()..color = Colors.black.withValues(alpha: 0.94),
      );
      canvas.drawCircle(
        eye + const Offset(-0.08, -0.10),
        0.05,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
      canvas.drawLine(
        eye + Offset(-0.20, -0.22 * side),
        eye + Offset(0.26, -0.08 * side),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.06
          ..color = Colors.black.withValues(alpha: 0.30),
      );
    }

    for (final side in const [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(0.84, side * 0.16),
        0.04,
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );
    }

    final flick = pow(max(0.0, sin(pulseValue * 2 * pi)), 0.5).toDouble();
    if (flick > 0.02) {
      final len = 0.95 + 0.85 * flick;
      final tongue = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.07
        ..color = const Color(0xFFE23A5B).withValues(alpha: 0.7 + 0.3 * flick);
      canvas.drawLine(const Offset(0.98, 0), Offset(len, 0), tongue);
      canvas.drawLine(Offset(len, 0), Offset(len + 0.26, -0.2), tongue);
      canvas.drawLine(Offset(len, 0), Offset(len + 0.26, 0.2), tongue);
    }
    canvas.restore();
  }

  V3 get _directionVector => switch (direction) {
        Direction.up => const V3(0, -1),
        Direction.down => const V3(0, 1),
        Direction.left => const V3(-1, 0),
        Direction.right => const V3(1, 0),
      };

  double _radiusAt(double s, double total) {
    const neck = 0.30, body = 0.355;
    double r = s < 1.4 ? neck + (body - neck) * (s / 1.4) : body;
    final distToEnd = total - s;
    const tailZone = 2.6;
    if (distToEnd < tailZone) {
      r *= 0.22 + 0.78 * pow((distToEnd / tailZone).clamp(0.0, 1.0), 0.7);
    }
    return max(r, 0.05);
  }

  List<double> _arcLengths(List<V3> chain) {
    final arc = [0.0];
    for (int i = 1; i < chain.length; i++) {
      arc.add(arc[i - 1] + (chain[i] - chain[i - 1]).abs());
    }
    return arc;
  }

  V3 _pointAt(List<V3> chain, List<double> arc, double s) {
    if (chain.length == 1) return chain.first;
    if (s <= 0) return chain.first;
    if (s >= arc.last) return chain.last;
    int i = 1;
    while (arc[i] < s) {
      i++;
    }
    final seg = arc[i] - arc[i - 1];
    final t = seg == 0 ? 0.0 : (s - arc[i - 1]) / seg;
    return chain[i - 1].lerp(chain[i], t);
  }

  void _buildFood(Scene3D scene, List<DepthSorted> solids) {
    if (food >= 0 && food < rowCount * colCount) {
      _pushApple(scene, _cellCentre(food), const Color(0xFFFF3B4E), solids);
    }
    if (bonusFood >= 0 && bonusFood < rowCount * colCount) {
      _pushGem(scene, _cellCentre(bonusFood), Colors.amberAccent, solids);
    }
  }

  void _pushApple(Scene3D scene, V3 base, Color color, List<DepthSorted> solids) {
    const radius = 0.34;
    final centre = V3(base.x, base.y, 0.60 + 0.16 * sin(pulseValue * 2 * pi));
    final pr = scene.project(centre);
    final rPx = radius * pr.unit;
    final glow = scene.project(V3(base.x, base.y, 0.005));

    solids.add(
      DepthSorted(pr.depth + 0.35, () {
        _floorDecal(_c, glow.screen, rPx * 2.3, 0.42, _decalPaint(color, 0.42));
      }),
    );
    solids.add(
      DepthSorted(pr.depth, () {
        final c = _c;
        _unitCircle(c, pr.screen, rPx, _ballPaint(color));
        _unitCircle(
          c,
          pr.screen + Offset(-rPx * 0.3, -rPx * 0.36),
          rPx * 0.26,
          Paint()..color = Colors.white.withValues(alpha: 0.5),
        );
        c.drawLine(
          pr.screen + Offset(0, -rPx * 0.85),
          pr.screen + Offset(rPx * 0.16, -rPx * 1.5),
          Paint()
            ..color = const Color(0xFF6B4A2A)
            ..strokeWidth = rPx * 0.16
            ..strokeCap = StrokeCap.round,
        );
        c.drawOval(
          Rect.fromCenter(
            center: pr.screen + Offset(rPx * 0.5, -rPx * 1.25),
            width: rPx * 0.95,
            height: rPx * 0.42,
          ),
          Paint()..color = const Color(0xFF3FBF6F),
        );
      }),
    );
  }

  void _pushGem(Scene3D scene, V3 base, Color color, List<DepthSorted> solids) {
    const a = 0.44;
    final spin = timeValue * 1.5;
    final cz = 0.72 + 0.14 * sin(pulseValue * 2 * pi + 1.2);
    final unit = [
      const V3(1, 0, 0),
      const V3(-1, 0, 0),
      const V3(0, 1, 0),
      const V3(0, -1, 0),
      const V3(0, 0, 1),
      const V3(0, 0, -1),
    ];
    final projected = <Projected>[];
    for (final p in unit) {
      final x = p.x * a, y = p.y * a, z = p.z * a;
      projected.add(
        scene.project(V3(
          base.x + x * cos(spin) - y * sin(spin),
          base.y + x * sin(spin) + y * cos(spin),
          cz + z,
        )),
      );
    }

    const faces = [
      [0, 2, 4], [2, 1, 4], [1, 3, 4], [3, 0, 4],
      [2, 0, 5], [1, 2, 5], [3, 1, 5], [0, 3, 5],
    ];
    for (final f in faces) {
      final verts = [projected[f[0]], projected[f[1]], projected[f[2]]];
      final depth = (verts[0].depth + verts[1].depth + verts[2].depth) / 3;
      final lit = f.contains(4);
      solids.add(
        DepthSorted(depth, () {
          final path = Path()..addPolygon([for (final v in verts) v.screen], true);
          _c.drawPath(
            path,
            Paint()
              ..color = (lit
                      ? Color.lerp(color, Colors.white, 0.42)!
                      : Color.lerp(color, Colors.black, 0.42)!)
                  .withValues(alpha: 0.96),
          );
          _c.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.9
              ..color = Colors.white.withValues(alpha: 0.45),
          );
        }),
      );
    }

    final glow = projected[4];
    solids.add(
      DepthSorted(glow.depth + 0.6, () {
        _floorDecal(_c, scene.project(V3(base.x, base.y, 0.005)).screen,
            a * glow.unit * 3.4, 0.4, _decalPaint(color, 0.35));
      }),
    );
  }

  void _buildObstacles(Scene3D scene, List<DepthSorted> solids) {
    for (final o in obstacles) {
      _pushBox(scene, _cellCentre(o), 0.46, 0.82, const Color(0xFF38455A), const Color(0xFFFF5364), solids);
    }
  }

  void _pushBox(
    Scene3D scene,
    V3 centre,
    double half,
    double height,
    Color base,
    Color accent,
    List<DepthSorted> solids,
  ) {
    final corners = <Projected>[];
    for (final z in [0.0, height]) {
      for (final p in [
        const V3(-1, -1),
        const V3(1, -1),
        const V3(1, 1),
        const V3(-1, 1),
      ]) {
        corners.add(scene.project(V3(centre.x + p.x * half, centre.y + p.y * half, z)));
      }
    }
    const faces = <_BoxFace>[
      _BoxFace([4, 5, 6, 7], 1.00),
      _BoxFace([0, 1, 5, 4], 0.70),
      _BoxFace([3, 2, 6, 7], 0.78),
      _BoxFace([3, 0, 4, 7], 0.52),
      _BoxFace([1, 2, 6, 5], 0.56),
    ];

    for (final f in faces) {
      final verts = [corners[f.idx[0]], corners[f.idx[1]], corners[f.idx[2]], corners[f.idx[3]]];
      final shade = f.shade;
      final depth = verts.map((v) => v.depth).reduce((a, b) => a + b) / verts.length;
      solids.add(
        DepthSorted(depth, () {
          final path = Path()..addPolygon([for (final v in verts) v.screen], true);
          _c.drawPath(
            path,
            Paint()
              ..shader = ui.Gradient.linear(
                verts.first.screen,
                verts.last.screen,
                [
                  Color.lerp(base, accent, 0.22 * shade)!,
                  Color.lerp(base, Colors.black, 0.55 * (1 - shade))!,
                ],
              ),
          );
          _c.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.1
              ..color = accent.withValues(alpha: 0.5 * shade),
          );
        }),
      );
    }
  }

  void _drawParticles(Canvas canvas, Scene3D scene) {
    for (final p in particles) {
      final pr = scene.project(V3(p.position.dx, p.position.dy, p.z.clamp(0.0, 3.0)));
      final r = max(p.size * pr.unit, 0.6);
      final alpha = p.opacity.clamp(0.0, 1.0);
      _unitCircle(
        canvas,
        pr.screen,
        r * 2.2,
        Paint()
          ..shader = RadialGradient(
            colors: [p.color.withValues(alpha: alpha * 0.8), p.color.withValues(alpha: 0)],
          ).createShader(const Rect.fromLTRB(-1, -1, 1, 1)),
      );
      canvas.drawCircle(
        pr.screen,
        r * 0.45,
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.8),
      );
    }
  }

  void _drawFloatingScores(Canvas canvas, Scene3D scene) {
    for (final fs in floatingScores) {
      final pr = scene.project(V3(fs.position.dx, fs.position.dy, fs.z));
      final painter = TextPainter(
        text: TextSpan(
          text: fs.text,
          style: TextStyle(
            color: fs.color.withValues(alpha: fs.opacity.clamp(0.0, 1.0)),
            fontSize: max(9.0, pr.unit * 0.7),
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: fs.color.withValues(alpha: 0.55), blurRadius: 12)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(pr.screen.dx - painter.width / 2, pr.screen.dy - painter.height / 2),
      );
    }
  }

  void _drawDeathRing(Canvas canvas, Scene3D scene) {
    if (snake.isEmpty) return;
    final centre = _cellCentre(snake.first);
    final radius = 0.6 + 5.5 * deathGlow;
    final ring = Path();
    for (int i = 0; i <= 40; i++) {
      final a = i / 40 * 2 * pi;
      final p = scene.project(V3(centre.x + cos(a) * radius, centre.y + sin(a) * radius, 0.02));
      if (i == 0) {
        ring.moveTo(p.screen.dx, p.screen.dy);
      } else {
        ring.lineTo(p.screen.dx, p.screen.dy);
      }
    }
    canvas.drawPath(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, 5.0 * (1 - deathGlow))
        ..color = Colors.redAccent.withValues(alpha: (1 - deathGlow).clamp(0.0, 1.0)),
    );
  }

  @override
  bool shouldRepaint(covariant Scene3DPainter oldDelegate) =>
      oldDelegate.snake != snake ||
      oldDelegate.food != food ||
      oldDelegate.bonusFood != bonusFood ||
      oldDelegate.direction != direction ||
      oldDelegate.pulseValue != pulseValue ||
      oldDelegate.timeValue != timeValue ||
      oldDelegate.interpolation != interpolation ||
      oldDelegate.prevLength != prevLength ||
      oldDelegate.deathGlow != deathGlow ||
      oldDelegate.skinColors != skinColors ||
      oldDelegate.obstacles != obstacles ||
      oldDelegate.wraps != wraps;
}
