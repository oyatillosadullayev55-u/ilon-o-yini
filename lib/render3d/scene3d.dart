import 'dart:math';
import 'dart:ui' show Offset, Rect, Size;

/// Oddiy 3D nuqta (kata birliklarida: 1 birlik = 1 katak tomoni).
class V3 {
  final double x;
  final double y;

  /// Balandlik: pol sathi = 0, yuqoriga oshadi.
  final double z;

  const V3(this.x, this.y, [this.z = 0.0]);

  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  V3 operator *(double k) => V3(x * k, y * k, z * k);

  /// Tekislikdagi masofa (z hisobga olinmaydi).
  double abs() => sqrt(x * x + y * y);

  V3 lerp(V3 o, double t) =>
      V3(x + (o.x - x) * t, y + (o.y - y) * t, z + (o.z - z) * t);
}

/// Proyeksiya natijasi.
class Projected {
  final Offset screen;

  /// Kameradan masofa — katta bo'lsa uzoqroq (chuqurlik saralashi uchun).
  final double depth;

  /// 1.0 = taxta markazi; uzoqroq nuqtalarda 1 dan kichik.
  final double perspective;

  /// O'sha chuqurlikda 1 katagiga to'g'ri keladigan piksel.
  final double unit;

  const Projected({
    required this.screen,
    required this.depth,
    required this.perspective,
    required this.unit,
  });
}

/// Chuqurlik bo'yicha saralash uchun vizual element.
class DepthSorted {
  final double depth;
  final void Function() paint;

  const DepthSorted(this.depth, this.paint);
}

/// Pinhole kamera asosidagi yengil 3D sahna.
///
/// Dunyo: x — o'ngga, y — kameradan uzoqqa (taxta qatorlari), z — yuqoriga.
/// Kamera taxta markazini nishon oladi; [elevation] — pol ustidan ko'tarilish
/// burchagi (radian), [yaw] — atrofida burilish.
class Scene3D {
  final Size size;
  final int cols;
  final int rows;
  final double elevation;
  final double yaw;

  /// Kamera masofasi = distanceFactor × taxta yarim diagonali.
  final double distanceFactor;

  /// Sahna egallaydigan maydon ulushi.
  final double fill;

  /// Sahnani vertikal siljitish (0..1).
  final double verticalBias;

  /// Berilsa, bo'sh joy qolganda kamera qiyaligi shu gacha ko'tariladi
  /// (vertikal cho'ziq panellarda taxtani to'ldirish uchun).
  final double? autoTiltTo;

  Scene3D({
    required this.size,
    required this.cols,
    required this.rows,
    this.elevation = 0.80,
    this.yaw = 0.0,
    this.distanceFactor = 2.15,
    this.fill = 0.94,
    this.verticalBias = 0.10,
    this.autoTiltTo,
  }) {
    _distance = distanceFactor * 0.5 * sqrt(cols * cols + rows * rows);
    _sy = sin(yaw);
    _cy = cos(yaw);

    var used = elevation;
    // Faqat vertikal bo'sh joy qolganda (cho'ziq panel) kamerani tiklaymiz.
    final hasVerticalSlack = size.height / size.width > (rows / cols) * 1.15;
    if (autoTiltTo != null && hasVerticalSlack && autoTiltTo! > elevation) {
      var best = -double.infinity;
      for (int i = 0; i <= 8; i++) {
        final e = elevation + (autoTiltTo! - elevation) * i / 8.0;
        _se = sin(e);
        _ce = cos(e);
        final b = _ndcBounds(withLift: false);
        final score = min(size.height * fill / b.height, size.width * fill / b.width);
        if (score > best) {
          best = score;
          used = e;
        }
      }
    }
    _se = sin(used);
    _ce = cos(used);
    final bounds = _ndcBounds(withLift: false);
    final minX = bounds.left, maxX = bounds.right;
    final minY = bounds.top, maxY = bounds.bottom;

    _f = min(size.width * fill / (maxX - minX), size.height * fill / (maxY - minY));
    _origin = Offset(
      size.width / 2 - (minX + maxX) / 2 * _f,
      size.height / 2 - (minY + maxY) / 2 * _f + verticalBias * size.height * 0.1,
    );
    _centerDepth = _view(V3(cols / 2.0, rows / 2.0, 0)).dy;
  }

  /// f = 1 holida sahnaning NDC chegarasi.
  ///
  /// [withLift] false bo'lsa faqat pol hisobga olinadi — devor va jismalar
  /// osmonga chiqib ketadi, shunda taxta paneldan to'liq joy oladi.
  Rect _ndcBounds({bool withLift = true}) {
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final c in [0.0, cols.toDouble()]) {
      for (final r in [0.0, rows.toDouble()]) {
        for (final z in withLift ? [0.0, _lift] : const [0.0]) {
          final n = _ndc(V3(c, r, z));
          minX = min(minX, n.dx);
          maxX = max(maxX, n.dx);
          minY = min(minY, n.dy);
          maxY = max(maxY, n.dy);
        }
      }
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static const double _lift = 0.72;

  late final double _distance;
  late double _se;
  late double _ce;
  late final double _sy;
  late final double _cy;
  late final double _f;
  late final Offset _origin;
  late final double _centerDepth;

  double get cellPx => _f / _centerDepth;

  Offset3 _view(V3 p) {
    final bx = p.x - cols / 2.0;
    // 0-qator kameradan uzoqda (ekranning yuqori qismi) bo'ladi
    final by = rows / 2.0 - p.y;
    final x1 = bx * _cy - by * _sy;
    final y1 = bx * _sy + by * _cy;

    // eye = (0, -R*ce, R*se), forward = (0, ce, -se), up = (0, se, ce)
    final vx = x1;
    final vy = y1 + _distance * _ce;
    final vz = p.z - _distance * _se;

    return Offset3(vx, max(vy * _ce - vz * _se, 0.05), vy * _se + vz * _ce);
  }

  Offset _ndc(V3 p) {
    final v = _view(p);
    return Offset(v.dx / v.dy, -v.dz / v.dy);
  }

  Projected project(V3 p) {
    final v = _view(p);
    final s = _f / v.dy;
    return Projected(
      screen: Offset(_origin.dx + v.dx * s, _origin.dy - v.dz * s),
      depth: v.dy,
      perspective: _centerDepth / v.dy,
      unit: s,
    );
  }

  /// Butun sahnaning ekran to'rtburchagi (devor/rama uchun qulay).
  Rect screenBounds() {
    final pts = <Offset>[];
    for (final c in [0.0, cols.toDouble()]) {
      for (final r in [0.0, rows.toDouble()]) {
        pts.add(project(V3(c, r, 0)).screen);
        pts.add(project(V3(c, r, _lift)).screen);
      }
    }
    double minX = pts.first.dx, maxX = minX, minY = pts.first.dy, maxY = minY;
    for (final o in pts) {
      minX = min(minX, o.dx);
      maxX = max(maxX, o.dx);
      minY = min(minY, o.dy);
      maxY = max(maxY, o.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

/// Uch komponentli yordamchi vektor (faqat sahna matematikasi uchun).
class Offset3 {
  final double dx;
  final double dy;
  final double dz;

  const Offset3(this.dx, this.dy, this.dz);
}
