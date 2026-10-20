import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Günəş şüaları: CSS `repeating-conic-gradient(from 0deg, #FFD98A 0 12deg,
/// #FFF1CC 12deg 24deg)`. 0° saat 12-dir, saat əqrəbi istiqamətində — 15 şüa,
/// hər biri 12°, aralarında 12°.
///
/// Rəssam kəsmir: kəsməni çağıran edir (disk üçün `ClipOval`, kart səhnəsi
/// üçün `ClipRRect`). Temanı oxumur — rənglər parametrdir.
class SunburstPainter extends CustomPainter {
  const SunburstPainter({
    this.center = Alignment.center,
    this.turns = 0,
    this.ray = ElifbaPalette.burst,
    this.gap = ElifbaPalette.burstLight,
  });

  /// Şüaların mərkəzi. Tam heyvan kartının səhnəsində `Alignment(0, 0.4)`
  /// (CSS `at 50% 70%`).
  final Alignment center;

  /// Fırlanma, tam dövrlə (0..1).
  final double turns;

  final Color ray;
  final Color gap;

  static const int _rays = 15;
  static const double _sweep = 12 * math.pi / 180;
  static const double _step = 24 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = gap);
    final c = center.alongSize(size);
    // Ən uzaq küncə qədər — şüalar hər yeri örtsün.
    final r = [
      c.distance,
      (c - Offset(size.width, 0)).distance,
      (c - Offset(0, size.height)).distance,
      (c - Offset(size.width, size.height)).distance,
    ].reduce(math.max);
    final rect = Rect.fromCircle(center: c, radius: r);
    final paint = Paint()..color = ray;
    final start = -math.pi / 2 + turns * 2 * math.pi;
    for (var k = 0; k < _rays; k++) {
      canvas.drawArc(rect, start + k * _step, _sweep, true, paint);
    }
  }

  @override
  bool shouldRepaint(SunburstPainter old) =>
      old.turns != turns ||
      old.center != center ||
      old.ray != ray ||
      old.gap != gap;
}

/// Ekran spesifikasiyalarındakı ad (animal.md).
typedef BurstHaloPainter = SunburstPainter;

/// Dairəvi günəş halqası, istəyə görə ortasında uşaq widget (kubok, maskot).
///
/// * Hər yerdə **statikdir** (tam kitab diski, kiçik təbrik halqası), yalnız
///   böyük təbrikdə [rotating] — 8 s-də bir dövr, xətti. Yalnız şüalar
///   fırlanır, maskot yox.
/// * [flat] → zolaqsız düz #FFF1CC disk (kiçik təbrikin azaldılmış variantı).
/// * [rotating] olanda azaldılmış hərəkətdə disk düzdür və controller heç
///   başlamır. Fırlanan halqa açıq olanda `pumpAndSettle` BİTMİR.
/// * [size] verilməyəndə valideynin ölçüsünü tutur (məs. `Stack` içində).
class SunburstDisc extends StatefulWidget {
  const SunburstDisc({
    super.key,
    this.size,
    this.rotating = false,
    this.flat = false,
    this.child,
    this.reduceMotion,
  });

  final double? size;
  final bool rotating;
  final bool flat;
  final Widget? child;

  /// Testlər üçün `AppSettings.reduceMotion`-u əvəz edir.
  final bool? reduceMotion;

  @override
  State<SunburstDisc> createState() => _SunburstDiscState();
}

class _SunburstDiscState extends State<SunburstDisc>
    with SingleTickerProviderStateMixin {
  AnimationController? _turn;

  bool get _reduced => ElifbaMotion.isReduced(widget.reduceMotion);
  bool get _spins => widget.rotating && !widget.flat && !_reduced;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant SunburstDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (_spins) {
      final c =
          _turn ??= AnimationController(
            vsync: this,
            duration: ElifbaMotion.haloTurn,
          );
      if (!c.isAnimating) c.repeat();
    } else {
      _turn?.stop();
    }
  }

  @override
  void dispose() {
    _turn?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flat = widget.flat || (widget.rotating && _reduced);
    Widget burst =
        flat
            ? const ColoredBox(color: ElifbaPalette.burstLight)
            : const CustomPaint(painter: SunburstPainter());
    if (!flat && _spins && _turn != null) {
      burst = RotationTransition(
        turns: _turn!,
        child: RepaintBoundary(child: burst),
      );
    }
    Widget disc = ClipOval(
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [burst],
      ),
    );
    if (widget.child != null) {
      disc = Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [disc, Center(child: widget.child)],
      );
    }
    disc = ExcludeSemantics(child: disc);
    final size = widget.size;
    return size == null ? disc : SizedBox.square(dimension: size, child: disc);
  }
}
