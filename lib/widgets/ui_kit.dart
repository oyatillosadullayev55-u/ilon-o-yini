import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../render3d/scene3d.dart';

/// Sahifalar orqasidagi animatsion 3D neon fon.
class NeonBackground extends StatefulWidget {
  final Widget child;
  final Color accent;
  final Color accent2;

  /// Fon to'sig'ining zichligi (menyu uchun katta, dialoglar uchun kichik).
  final double intensity;

  const NeonBackground({
    super.key,
    required this.child,
    this.accent = const Color(0xFF00E5A0),
    this.accent2 = const Color(0xFF35C4FF),
    this.intensity = 1.0,
  });

  @override
  State<NeonBackground> createState() => _NeonBackgroundState();
}

class _NeonBackgroundState extends State<NeonBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _t,
          builder: (context, _) => CustomPaint(
            painter: _BackdropPainter(
              t: _t.value,
              accent: widget.accent,
              accent2: widget.accent2,
              intensity: widget.intensity,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final double t;
  final Color accent;
  final Color accent2;
  final double intensity;

  const _BackdropPainter({
    required this.t,
    required this.accent,
    required this.accent2,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 4 || size.height < 4) return;
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF05070C), Color(0xFF0A1220), Color(0xFF06090F)],
        ).createShader(rect),
    );

    // Yuqoridagi nur dog'lari
    for (int i = 0; i < 3; i++) {
      final phase = (t * 2 * pi + i * 2.1);
      final cx = size.width * (0.22 + 0.3 * i) + sin(phase) * size.width * 0.06;
      final cy = size.height * (0.16 + 0.09 * i) + cos(phase * 0.8) * size.height * 0.05;
      final r = size.width * (0.30 - 0.06 * i);
      final c = i.isEven ? accent : accent2;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(r);
      canvas.drawCircle(
        Offset.zero,
        1,
        Paint()
          ..shader = RadialGradient(
            colors: [
              c.withValues(alpha: 0.11 * intensity),
              c.withValues(alpha: 0.0),
            ],
          ).createShader(const Rect.fromLTRB(-1, -1, 1, 1)),
      );
      canvas.restore();
    }

    // Perspektiv to'r — pastki qismda "pol" effekti
    final scene = Scene3D(
      size: size,
      cols: 16,
      rows: 16,
      elevation: 0.42,
      yaw: 0.22 * sin(t * 2 * pi),
      fill: 2.6,
      verticalBias: 3.4,
    );
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = accent.withValues(alpha: 0.10 * intensity);
    for (int r = 0; r <= 16; r++) {
      canvas.drawLine(
        scene.project(V3(0, r.toDouble())).screen,
        scene.project(V3(16, r.toDouble())).screen,
        linePaint,
      );
    }
    for (int c = 0; c <= 16; c++) {
      canvas.drawLine(
        scene.project(V3(c.toDouble(), 0)).screen,
        scene.project(V3(c.toDouble(), 16)).screen,
        linePaint,
      );
    }

    // Vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.25,
          colors: [const Color(0x00000000), const Color(0x99000000)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) =>
      old.t != t || old.accent != accent || old.intensity != intensity;
}

/// Xira shisha panel (glassmorphism).
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color? glowColor;
  final double blur;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.borderColor,
    this.glowColor,
    this.blur = 14,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? Colors.white.withValues(alpha: 0.10);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? Colors.black).withValues(alpha: glowColor == null ? 0.45 : 0.32),
            blurRadius: glowColor == null ? 18 : 28,
            spreadRadius: glowColor == null ? 0 : 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.085),
                  Colors.white.withValues(alpha: 0.025),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: border, width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Neon gradient tugma: bosilganda siqiladi, doimiy nur pulsasi.
class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final List<Color> colors;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.colors = const [Color(0xFF00E5A0), Color(0xFF35C4FF)],
    this.padding = const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
    this.fontSize = 16,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);
  bool _pressed = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glow = enabled ? 0.22 + 0.20 * _pulse.value : 0.0;
          return Transform.scale(
            scale: _pressed ? 0.96 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: widget.colors.first.withValues(alpha: glow),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? widget.colors
                  : widget.colors.map((c) => c.withValues(alpha: 0.35)).toList(),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: widget.padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: widget.fontSize + 3, color: Colors.black),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ikkinchi darajali shisha tugma (belgi + matn).
class GlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const GlassButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = const Color(0xFF00E5A0),
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kichik ko'rsatkichi (tanga, daraja va h.k.).
class StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const StatPill({super.key, required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x22000000),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sarlavha uchun gradient + soyali matn.
class NeonTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final List<Color> colors;

  const NeonTitle(
    this.text, {
    super.key,
    this.fontSize = 30,
    this.colors = const [Color(0xFF00E5A0), Color(0xFF35C4FF)],
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(colors: colors).createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
          shadows: [Shadow(color: colors.first.withValues(alpha: 0.45), blurRadius: 22)],
        ),
      ),
    );
  }
}

/// Silliq sahifa o'tishi: xira + masshtab + opacity.
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  FadeScaleRoute({required Widget child})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (context, animation, secondary) => child,
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Kirish matni uchun mayda yo'l-yo'lak sarlavha.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.4,
      ),
    );
  }
}
