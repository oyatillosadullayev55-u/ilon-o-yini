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
  final double interpolation;
  final int prevLength;
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
    required this.interpolation,
    required this.prevLength,
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
                colors: [Color(0xFF04060A), Color(0xFF0A0F18)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(color: skinColors.first.withValues(alpha: 0.6), width: 2.5),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: skinColors.first.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 3,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: CustomPaint(
                painter: UltraSnakePainter(
                  rowCount: rowCount,
                  colCount: colCount,
                  snake: snake,
                  food: food,
                  bonusFood: bonusFood,
                  direction: direction,
                  pulseValue: pulseValue,
                  interpolation: interpolation,
                  prevLength: prevLength,
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

/// Bir nuqta: tan markazidagi koordinata va boshdan bo'lgan yoy uzunligi.
class _BodySample {
  final Offset p;
  final double s;
  Offset tangent;

  _BodySample(this.p, this.s, this.tangent);
}

class UltraSnakePainter extends CustomPainter {
  final int rowCount;
  final int colCount;
  final List<int> snake;
  final int food;
  final int bonusFood;
  final Direction direction;
  final double pulseValue;
  final double interpolation;
  final int prevLength;
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
    required this.interpolation,
    required this.prevLength,
    required this.floatingScores,
    required this.particles,
    required this.skinColors,
    required this.obstacles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / colCount;
    final double cellHeight = size.height / rowCount;

    // Grid panjarasi
    final Paint gridPaint = Paint()
      ..color = skinColors.first.withValues(alpha: 0.035)
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
      final Offset o = _cellCenter(obs, cellWidth, cellHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: o,
            width: cellWidth * 0.8,
            height: cellHeight * 0.8,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = Colors.redAccent.withValues(alpha: 0.8),
      );
    }

    // Zarrachalar (Particles)
    for (var particle in particles) {
      canvas.drawCircle(
        particle.position,
        particle.size,
        Paint()
          ..color = particle.color.withValues(alpha: particle.opacity.clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Ovqat
    _drawFood(canvas, food, cellWidth, cellHeight, Colors.redAccent, false);
    if (bonusFood != -1) {
      _drawFood(canvas, bonusFood, cellWidth, cellHeight, Colors.amberAccent, true);
    }

    // Ilon
    _drawSnake(canvas, cellWidth, cellHeight);

    // Floating Score matnlari
    for (var fs in floatingScores) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: fs.text,
          style: TextStyle(
            color: fs.color.withValues(alpha: fs.opacity.clamp(0.0, 1.0)),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: fs.color.withValues(alpha: 0.9), blurRadius: 10),
              const Shadow(color: Colors.black, blurRadius: 3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(fs.position.dx - textPainter.width / 2, fs.position.dy + fs.yOffset),
      );
    }
  }

  Offset _cellCenter(int index, double cw, double ch) => Offset(
        (index % colCount) * cw + cw / 2,
        (index ~/ colCount) * ch + ch / 2,
      );

  void _drawFood(Canvas canvas, int index, double cw, double ch, Color color, bool isBonus) {
    final Offset c = _cellCenter(index, cw, ch);
    final double pulseScale = 1.0 + 0.18 * sin(pulseValue * 2 * pi);
    final double radius = (min(cw, ch) / 2) * (isBonus ? 0.85 : 0.68) * pulseScale;

    canvas.drawCircle(
      c,
      radius + 5,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawCircle(c, radius, Paint()..color = color);
    canvas.drawCircle(
      Offset(c.dx - radius * 0.3, c.dy - radius * 0.3),
      radius * 0.25,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    canvas.drawLine(
      Offset(c.dx, c.dy - radius),
      Offset(c.dx + 2, c.dy - radius - 6),
      Paint()
        ..color = Colors.green.shade300
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  // ------------------------------------------------------------------ Ilon ---

  void _drawSnake(Canvas canvas, double cw, double ch) {
    if (snake.isEmpty) return;

    final int n = snake.length;
    final double cell = min(cw, ch);
    final double t = interpolation.clamp(0.0, 1.0);

    final List<Offset> pts = [for (int i = 0; i < n; i++) _cellCenter(snake[i], cw, ch)];

    // Tan yo'lagi: bosh eski katdan yangi katga qarab siljiydi,
    // qolgan qismi hozirgi katlar markazlaridan o'tadi.
    final List<Offset> poly = [];
    if (n > 1) {
      final Offset prevHead = pts[1];
      final bool headWrapped = (prevHead - pts.first).distance > cell * 1.6;
      poly.add(headWrapped ? pts.first : Offset.lerp(prevHead, pts.first, t)!);
    } else {
      poly.add(pts.first);
    }
    for (int i = 1; i < n; i++) {
      poly.add(pts[i]);
    }

    // O'smagan qadamda dum avvalgi katidan hamon chiqib turadi
    if (n > 1 && n <= prevLength) {
      final Offset dir = pts[n - 1] - pts[n - 2];
      if (dir.distance > cell * 0.1 && dir.distance <= cell * 1.6) {
        poly.add(pts[n - 1] + dir / dir.distance * (dir.distance * (1.0 - t)));
      }
    }

    final int m = poly.length;
    final List<double> arc = List<double>.filled(m, 0);
    final List<bool> wrapped = List<bool>.filled(m, false);
    for (int i = 1; i < m; i++) {
      final double d = (poly[i] - poly[i - 1]).distance;
      wrapped[i] = d > cell * 1.6;
      arc[i] = arc[i - 1] + (wrapped[i] ? cell : d);
    }
    final double bodyEnd = arc[m - 1];

    // Markaziy chiziqni bir tekis qadamlar bilan namunalar
    final double step = cell / 3.2;
    final List<_BodySample> raw = [];
    for (double s = 0; s < bodyEnd; s += step) {
      final Offset? p = _pointAt(poly, arc, wrapped, s);
      if (p != null) raw.add(_BodySample(p, s, Offset(1, 0)));
    }
    final Offset? endP = _pointAt(poly, arc, wrapped, bodyEnd);
    if (endP != null) raw.add(_BodySample(endP, bodyEnd, Offset(1, 0)));
    if (raw.isEmpty) return;

    // Uzluksiz zanjirlarga bo'lish (wrap va sakrashlar uchun)
    final List<List<_BodySample>> chains = [];
    List<_BodySample> current = [raw.first];
    for (int i = 1; i < raw.length; i++) {
      if ((raw[i].p - raw[i - 1].p).distance > step * 2.2) {
        chains.add(current);
        current = [];
      }
      current.add(raw[i]);
    }
    chains.add(current);

    for (final chain in chains) {
      _computeTangents(chain);
      _drawBodyChain(canvas, chain, bodyEnd, cell);
    }

    _drawHead(canvas, raw.first.p, raw.first.tangent, cell);
  }

  /// s — boshdan dumga qarab o'lchangan masofadagi markaziy chiziq nuqtasi.
  /// Wrap (taxta chetidan sakrash) oralayotgan bo'lsa null — tan shu yerda uziladi.
  Offset? _pointAt(List<Offset> poly, List<double> arc, List<bool> wrapped, double s) {
    final int m = poly.length;
    if (m == 1) return poly.first;
    if (s <= 0) return poly.first;
    if (s >= arc[m - 1]) return poly[m - 1];

    int i = 0;
    while (i < m - 1 && arc[i + 1] < s) {
      i++;
    }
    if (wrapped[i + 1]) return null;
    final double segLen = arc[i + 1] - arc[i];
    final double k = segLen <= 0 ? 0 : ((s - arc[i]) / segLen).clamp(0.0, 1.0);
    return Offset.lerp(poly[i], poly[i + 1], k);
  }

  void _computeTangents(List<_BodySample> chain) {
    for (int i = 0; i < chain.length; i++) {
      final _BodySample prev = chain[max(0, i - 1)];
      final _BodySample next = chain[min(chain.length - 1, i + 1)];
      // Tangent bosh tomoniga qarab yo'naladi (s kamayadigan tomonga).
      Offset dir = prev.p - next.p;
      if (dir.distanceSquared < 1e-6) {
        dir = i + 1 < chain.length ? chain[i].p - chain[i + 1].p : const Offset(1, 0);
      }
      chain[i].tangent = dir / max(dir.distance, 0.001);
    }
  }

  /// Boshdan s masofadagi tan kengligi: bo'yin keng, dum ingichka.
  double _widthAt(double s, double bodyEnd, double cell) {
    if (s <= 0) return cell * 0.62;
    final double tailZone = cell * 2.6;
    if (s > bodyEnd - tailZone) {
      final double k = ((bodyEnd - s) / tailZone).clamp(0.0, 1.0);
      return cell * (0.07 + 0.55 * pow(k, 0.6).toDouble());
    }
    final double k = s / max(bodyEnd, cell);
    return cell * (0.72 - 0.12 * k);
  }

  void _drawBodyChain(Canvas canvas, List<_BodySample> chain, double bodyEnd, double cell) {
    final Color base = skinColors.first;
    final Color accent = skinColors.length > 1 ? skinColors[1] : base;
    final Color dark = Color.lerp(base, Colors.black, 0.62)!;
    final Color light = Color.lerp(base, Colors.white, 0.30)!;

    final List<Offset> left = [];
    final List<Offset> right = [];
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (final sm in chain) {
      final double w = _widthAt(sm.s, bodyEnd, cell) / 2;
      final Offset normal = Offset(-sm.tangent.dy, sm.tangent.dx);
      final Offset a = sm.p + normal * w;
      final Offset b = sm.p - normal * w;
      left.add(a);
      right.add(b);
      minX = min(minX, min(a.dx, b.dx));
      maxX = max(maxX, max(a.dx, b.dx));
      minY = min(minY, min(a.dy, b.dy));
      maxY = max(maxY, max(a.dy, b.dy));
    }

    final Rect bounds = Rect.fromLTRB(minX, minY, maxX, maxY);

    final Path body = Path();
    body.moveTo(left.first.dx, left.first.dy);
    for (int i = 1; i < left.length; i++) {
      body.lineTo(left[i].dx, left[i].dy);
    }
    for (int i = right.length - 1; i >= 0; i--) {
      body.lineTo(right[i].dx, right[i].dy);
    }
    body.close();

    // Tashqi nur
    canvas.drawPath(
      body,
      Paint()
        ..color = base.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.35
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Soya
    canvas.save();
    canvas.translate(cell * 0.10, cell * 0.16);
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();

    // Tan: teri gradienti (boshdan duminga)
    canvas.drawPath(
      body,
      Paint()
        ..isAntiAlias = true
        ..shader = LinearGradient(
          colors: [light, base, accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
    );

    final Path spine = Path()..moveTo(chain.first.p.dx, chain.first.p.dy);
    for (int i = 1; i < chain.length; i++) {
      spine.lineTo(chain[i].p.dx, chain[i].p.dy);
    }

    // Tarang ichida: silindr soya + takya naqsh
    canvas.save();
    canvas.clipPath(body);
    _drawTubeShading(canvas, spine, chain, bodyEnd, cell, dark, light);
    _drawScales(canvas, chain, bodyEnd, cell, dark, light, accent);
    canvas.restore();

    // Chegara
    canvas.drawPath(
      body,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.055
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Tan yon tomonlari qorong'i, orqasi yorug' — yumaloq hajm effekti.
  void _drawTubeShading(
    Canvas canvas,
    Path spine,
    List<_BodySample> chain,
    double bodyEnd,
    double cell,
    Color dark,
    Color light,
  ) {
    canvas.drawPath(
      spine,
      Paint()
        ..color = light.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      spine,
      Paint()
        ..color = dark.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.95
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      spine,
      Paint()
        ..color = light.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.20
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Tan terisidagi takya naqsh: orqa bo'yladagi dog'lar va yon qatorlardagi pullar.
  void _drawScales(
    Canvas canvas,
    List<_BodySample> chain,
    double bodyEnd,
    double cell,
    Color dark,
    Color light,
    Color accent,
  ) {
    final Paint fill = Paint()..isAntiAlias = true;
    final Paint rim = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.02;

    for (int i = 0; i < chain.length; i++) {
      final _BodySample sm = chain[i];
      final double w = _widthAt(sm.s, bodyEnd, cell);
      if (w < cell * 0.14) continue;

      final Offset normal = Offset(-sm.tangent.dy, sm.tangent.dx);
      final Offset center = sm.p + sm.tangent * (w * 0.10);

      // Yon pullar qatorlari (juda nozik)
      if (i.isEven) {
        for (final double side in [-1.0, 1.0]) {
          _drawScale(
            canvas,
            fill..color = light.withValues(alpha: 0.10),
            rim..color = dark.withValues(alpha: 0.16),
            center + normal * (side * w * 0.26),
            sm.tangent,
            w * 0.17,
            w * 0.26,
          );
        }
      }

      // Orqa belgular (rombimon naqsh)
      if (i % 4 == 0) {
        _drawScale(
          canvas,
          fill..color = dark.withValues(alpha: 0.28),
          rim..color = light.withValues(alpha: 0.22),
          center,
          sm.tangent,
          w * 0.26,
          w * 0.40,
        );
        _drawScale(
          canvas,
          fill..color = accent.withValues(alpha: 0.30),
          rim..color = const Color(0x00000000),
          center + sm.tangent * (w * 0.06),
          sm.tangent,
          w * 0.15,
          w * 0.24,
        );
      }
    }
  }

  /// Takya shakli: oldinga qaratilgan yumaloq romb (oval).
  void _drawScale(
    Canvas canvas,
    Paint fill,
    Paint rim,
    Offset center,
    Offset tangent,
    double along,
    double across,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(atan2(tangent.dy, tangent.dx));
    final Rect r = Rect.fromCenter(center: Offset.zero, width: along * 2, height: across * 2);
    canvas.drawOval(r, fill);
    canvas.drawOval(r, rim);
    canvas.restore();
  }

  /// Haqiqiy ilon boshi: cho'ziq burun, badovmat ko'zlar, tanaq va tishli til.
  void _drawHead(Canvas canvas, Offset p, Offset tangent, double cell) {
    final Color base = skinColors.first;
    final Color accent = skinColors.length > 1 ? skinColors[1] : base;
    final Color dark = Color.lerp(base, Colors.black, 0.62)!;
    final Color light = Color.lerp(base, Colors.white, 0.35)!;

    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(atan2(tangent.dy, tangent.dx));

    // Siluet: orqasi keng, oldi cho'ziq uchburchaksimon
    final Path head = Path()
      ..moveTo(-0.66 * cell, 0)
      ..cubicTo(-0.58 * cell, -0.42 * cell, -0.05 * cell, -0.52 * cell, 0.34 * cell, -0.30 * cell)
      ..cubicTo(0.56 * cell, -0.17 * cell, 0.62 * cell, -0.06 * cell, 0.62 * cell, 0)
      ..cubicTo(0.62 * cell, 0.06 * cell, 0.56 * cell, 0.17 * cell, 0.34 * cell, 0.30 * cell)
      ..cubicTo(-0.05 * cell, 0.52 * cell, -0.58 * cell, 0.42 * cell, -0.66 * cell, 0)
      ..close();

    canvas.drawPath(
      head,
      Paint()
        ..color = base.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      head,
      Paint()
        ..isAntiAlias = true
        ..shader = LinearGradient(
          colors: [dark, base, light],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(-cell, -cell * 0.6, cell * 1.8, cell * 1.2)),
    );
    canvas.drawPath(
      head,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.05,
    );

    // Bosh plastinkalari
    final Paint plate = Paint()
      ..isAntiAlias = true
      ..color = light.withValues(alpha: 0.22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0.02 * cell, -0.17 * cell),
        width: 0.52 * cell,
        height: 0.26 * cell,
      ),
      plate,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0.02 * cell, 0.17 * cell),
        width: 0.52 * cell,
        height: 0.26 * cell,
      ),
      plate,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0.30 * cell, 0),
        width: 0.34 * cell,
        height: 0.24 * cell,
      ),
      Paint()
        ..isAntiAlias = true
        ..color = accent.withValues(alpha: 0.35),
    );

    // Ko'zlar: badovmat bema + tik qorachiqoq
    for (final double side in [-1.0, 1.0]) {
      final Offset eye = Offset(0.10 * cell, side * 0.31 * cell);
      canvas.drawOval(
        Rect.fromCenter(center: eye, width: 0.30 * cell, height: 0.22 * cell),
        Paint()..color = const Color(0xFFFFF3C4),
      );
      canvas.drawCircle(
        eye,
        0.095 * cell,
        Paint()..color = Color.lerp(accent, Colors.orange, 0.6)!,
      );
      canvas.drawOval(
        Rect.fromCenter(center: eye, width: 0.17 * cell, height: 0.045 * cell),
        Paint()..color = Colors.black,
      );
      canvas.drawCircle(
        eye + Offset(0.03 * cell, -side * 0.03 * cell),
        0.022 * cell,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }

    // Burun tanaqlari
    for (final double side in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(0.50 * cell, side * 0.10 * cell),
        0.028 * cell,
        Paint()..color = dark,
      );
    }

    // Og'iz chizig'i
    canvas.drawPath(
      Path()
        ..moveTo(0.60 * cell, 0)
        ..quadraticBezierTo(0.42 * cell, -0.10 * cell, 0.24 * cell, -0.16 * cell)
        ..moveTo(0.60 * cell, 0)
        ..quadraticBezierTo(0.42 * cell, 0.10 * cell, 0.24 * cell, 0.16 * cell),
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.035,
    );

    // Ayryuli til: muntazam artiladi
    final double flick = pow(max(0.0, sin(pulseValue * 2 * pi)), 0.6).toDouble();
    if (flick > 0.02) {
      final double len = cell * (0.45 + 0.85 * flick);
      final double baseX = 0.60 * cell;
      final Paint tongue = Paint()
        ..color = const Color(0xFFE8365D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.07
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(baseX, 0), Offset(baseX + len * 0.62, 0), tongue);
      canvas.drawLine(
        Offset(baseX + len * 0.62, 0),
        Offset(baseX + len, -0.13 * cell),
        tongue,
      );
      canvas.drawLine(
        Offset(baseX + len * 0.62, 0),
        Offset(baseX + len, 0.13 * cell),
        tongue,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant UltraSnakePainter oldDelegate) {
    return oldDelegate.snake != snake ||
        oldDelegate.food != food ||
        oldDelegate.bonusFood != bonusFood ||
        oldDelegate.direction != direction ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.interpolation != interpolation ||
        oldDelegate.prevLength != prevLength ||
        oldDelegate.floatingScores != floatingScores ||
        oldDelegate.particles != particles ||
        oldDelegate.skinColors != skinColors ||
        oldDelegate.obstacles != obstacles;
  }
}
