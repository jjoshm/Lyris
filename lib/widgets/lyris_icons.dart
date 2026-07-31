import 'package:flutter/material.dart';

/// Custom Lyris icons — clean, modern, no emojis.
class LyrisIcons {
  LyrisIcons._();

  // ─── Brand Logo (crescent moon) ──────────────────────────────────────
  static Widget logo({double size = 48, Color? color}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MoonPainter(color: color),
    );
  }

  // ─── Phase Icons ─────────────────────────────────────────────────────
  static const IconData period = Icons.water_drop_rounded;
  static const IconData follicular = Icons.spa_rounded;
  static const IconData fertile = Icons.eco_rounded;
  static const IconData ovulation = Icons.brightness_high_rounded;
  static const IconData pms = Icons.waves_rounded;

  // ─── Navigation ──────────────────────────────────────────────────────
  static const IconData home = Icons.home_rounded;
  static const IconData calendar = Icons.calendar_month_rounded;
  static const IconData insights = Icons.insights_rounded;
  static const IconData settings = Icons.settings_rounded;

  // ─── Partner / Sync ──────────────────────────────────────────────────
  static const IconData sync = Icons.sync_rounded;
  static const IconData pair = Icons.qr_code_scanner_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData partner = Icons.visibility_rounded;

  // ─── Symptoms ────────────────────────────────────────────────────────
  static const IconData insomnia = Icons.nightlight_round;
  static const IconData spotting = Icons.water_drop_outlined;

  // ─── Misc ────────────────────────────────────────────────────────────
  static const IconData darkMode = Icons.dark_mode_rounded;
  static const IconData lightMode = Icons.light_mode_rounded;
  static const IconData systemMode = Icons.brightness_auto_rounded;

  static IconData phaseIcon(String phase) {
    switch (phase) {
      case 'period':
        return period;
      case 'follicular':
        return follicular;
      case 'fertile':
        return fertile;
      case 'ovulation':
        return ovulation;
      case 'pms':
        return pms;
      default:
        return Icons.circle_rounded;
    }
  }
}

/// Crescent moon painter — the Lyris brand mark.
class _MoonPainter extends CustomPainter {
  final Color? color;

  _MoonPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? Color(0xFFE8527A)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Full circle
    canvas.drawCircle(center, radius, paint);

    // Cut out crescent with background-colored circle
    final cutPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.dstOut;

    canvas.drawCircle(
      Offset(center.dx + radius * 0.35, center.dy - radius * 0.1),
      radius * 0.75,
      cutPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Animated Lyris logo — subtle breathing glow.
class LyrisLogoAnimated extends StatefulWidget {
  final double size;
  final Color? color;

  LyrisLogoAnimated({super.key, this.size = 64, this.color});

  @override
  State<LyrisLogoAnimated> createState() => _LyrisLogoAnimatedState();
}

class _LyrisLogoAnimatedState extends State<LyrisLogoAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: LyrisIcons.logo(size: widget.size, color: widget.color),
    );
  }
}
