import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Maskotun pozaları.
enum SunPose {
  /// Ana səhifədə kitabın üstündən baxır (60 dp).
  idle,

  /// Böyük təbrik: gülən gözlər, açıq ağız, uzun şüalar (100 dp, 128 halqada).
  cheer,

  /// Şəkil yoxdur / boş hərf: buludun arxasında yatır (92, boş vəziyyətdə 72).
  sleepy,
}

/// Günəş maskotu — dizayn fayllarının SVG həndəsəsi (viewBox 120 × 120)
/// `CustomPainter`-ə köçürülüb, `size / 120` miqyasla.
///
/// Statikdir (boş-dayanma animasiyası yoxdur), ona görə ana səhifədə
/// `pumpAndSettle` bitir. Bəzəkdir — semantikası yoxdur. Valideyn sahəsində
/// heç vaxt göstərilmir.
class SunMascot extends StatelessWidget {
  const SunMascot({
    super.key,
    this.pose = SunPose.idle,
    this.size = 60,
    this.cloudColor = ElifbaPalette.surface,
  });

  /// Yatan günəş (`ImagePlaceholder`, boş hərf kartı).
  const SunMascot.sleepy({
    super.key,
    this.size = 92,
    this.cloudColor = ElifbaPalette.surface,
  }) : pose = SunPose.sleepy;

  /// Sevinən günəş (böyük təbrik).
  const SunMascot.cheer({super.key, this.size = 100})
    : pose = SunPose.cheer,
      cloudColor = ElifbaPalette.surface;

  final SunPose pose;
  final double size;

  /// Yalnız [SunPose.sleepy]: buludun rəngi (kartda #FFFDFB, boş vəziyyətdə
  /// #ECE7FF).
  final Color cloudColor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: SunMascotPainter(pose: pose, cloudColor: cloudColor),
        ),
      ),
    );
  }
}

/// [SunMascot]-un rəssamı. Ayrıca açıqdır ki, başqa rəssamın içində də
/// çəkilə bilsin.
class SunMascotPainter extends CustomPainter {
  const SunMascotPainter({
    this.pose = SunPose.idle,
    this.cloudColor = ElifbaPalette.surface,
  });

  final SunPose pose;
  final Color cloudColor;

  static const Offset _c = Offset(60, 60);
  static const Color _ink = ElifbaPalette.onSurface;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // SVG kökü öz qutusunu kəsir: `cheer` şüalarının ucu (y −2) görünmür.
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 120, size.height / 120);

    // 1. Şüalar: `<rect>` (60, 60) ətrafında k·45° fırladılır.
    final cheer = pose == SunPose.cheer;
    final ray =
        cheer
            ? RRect.fromLTRBR(54, -2, 66, 24, const Radius.circular(6))
            : RRect.fromLTRBR(55, 2, 65, 22, const Radius.circular(5));
    final rayPaint =
        Paint()
          ..isAntiAlias = true
          ..color = cheer ? ElifbaPalette.sunRayCheer : ElifbaPalette.sun;
    final angles =
        pose == SunPose.sleepy
            ? const [-1, 0, 1]
            : const [0, 1, 2, 3, 4, 5, 6, 7];
    for (final k in angles) {
      canvas.save();
      canvas.translate(_c.dx, _c.dy);
      canvas.rotate(k * math.pi / 4);
      canvas.translate(-_c.dx, -_c.dy);
      canvas.drawRRect(ray, rayPaint);
      canvas.restore();
    }

    // 2. Üz.
    canvas.drawCircle(
      _c,
      33,
      Paint()
        ..isAntiAlias = true
        ..color = ElifbaPalette.sunFace,
    );

    final stroke =
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..color = _ink;
    final fill =
        Paint()
          ..isAntiAlias = true
          ..color = _ink;
    final cheek =
        Paint()
          ..isAntiAlias = true
          ..color = ElifbaPalette.cheek70;

    switch (pose) {
      case SunPose.idle:
        // Gözlər, yanaqlar, təbəssüm `M51 67Q60 75 69 67`.
        canvas.drawCircle(const Offset(49, 56), 4.5, fill);
        canvas.drawCircle(const Offset(71, 56), 4.5, fill);
        canvas.drawCircle(const Offset(42, 67), 5, cheek);
        canvas.drawCircle(const Offset(78, 67), 5, cheek);
        canvas.drawPath(
          Path()
            ..moveTo(51, 67)
            ..quadraticBezierTo(60, 75, 69, 67),
          stroke,
        );
      case SunPose.cheer:
        // Gülən gözlər `M43 57Q49 49 55 57M65 57Q71 49 77 57`, yanaqlar,
        // açıq ağız `M49 64Q60 82 71 64Z`.
        canvas.drawPath(
          Path()
            ..moveTo(43, 57)
            ..quadraticBezierTo(49, 49, 55, 57)
            ..moveTo(65, 57)
            ..quadraticBezierTo(71, 49, 77, 57),
          stroke,
        );
        canvas.drawCircle(const Offset(42, 66), 5, cheek);
        canvas.drawCircle(const Offset(78, 66), 5, cheek);
        canvas.drawPath(
          Path()
            ..moveTo(49, 64)
            ..quadraticBezierTo(60, 82, 71, 64)
            ..close(),
          fill,
        );
      case SunPose.sleepy:
        // Yumulu gözlər `M43 56Q49 61 55 56M65 56Q71 61 77 56`, kiçik ağız,
        // ən sonda bulud.
        canvas.drawPath(
          Path()
            ..moveTo(43, 56)
            ..quadraticBezierTo(49, 61, 55, 56)
            ..moveTo(65, 56)
            ..quadraticBezierTo(71, 61, 77, 56),
          stroke,
        );
        canvas.drawCircle(const Offset(60, 66), 3, fill);
        final cloud =
            Paint()
              ..isAntiAlias = true
              ..color = cloudColor;
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(60, 96), width: 116, height: 44),
          cloud,
        );
        canvas.drawCircle(const Offset(34, 80), 18, cloud);
        canvas.drawCircle(const Offset(80, 78), 20, cloud);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SunMascotPainter old) =>
      old.pose != pose || old.cloudColor != cloudColor;
}
