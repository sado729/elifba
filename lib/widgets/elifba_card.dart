import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../theme/theme.dart';
import 'squishy.dart';
import 'sun_mascot.dart';
import 'sunburst.dart';

/// Basılmayan kart səthi: ağ üz, 2 dp #E6E1F5 halqa, düz alt kənar.
/// `DecoratedBox`-dur, `AnimatedContainer` DEYİL. Basılan kart (heyvan, yazı)
/// `Squishy`-dir — eyni dəyərlərlə.
///
/// | istifadə                                   | radius | halqa | kənar | boşluq     |
/// |--------------------------------------------|--------|-------|-------|------------|
/// | hərf məlumat kartı, heyvan bölmə kartları  | 24     | 2     | 4     | ekrana görə|
/// | yazı lövhəsi                               | 28     | 2     | 6     | 0          |
/// | boş hərf kartı                             | 24     | 2     | 0     | 16 / 18    |
/// | pazl səbəti                                | 20     | 2     | 0     | 10         |
///
/// Kənar layout qutusundan kənarda çəkilir: altındakı boşluğa ən azı [edge]
/// dp qoyun.
class ElifbaCard extends StatelessWidget {
  const ElifbaCard({
    super.key,
    required this.child,
    this.radius = ElifbaRadius.r28,
    this.color = ElifbaPalette.surface,
    this.ringColor = ElifbaPalette.outlineVariant,
    this.ringWidth = ElifbaRing.normal,
    this.edge = ElifbaEdge.e6,
    this.edgeColor = ElifbaPalette.outline,
    this.padding,
    this.clip = false,
  });

  /// Bölmə kartı preset-i: radius 24, kənar 4.
  const ElifbaCard.section({
    super.key,
    required this.child,
    this.padding,
    this.clip = false,
  }) : radius = ElifbaRadius.r24,
       color = ElifbaPalette.surface,
       ringColor = ElifbaPalette.outlineVariant,
       ringWidth = ElifbaRing.normal,
       edge = ElifbaEdge.e4,
       edgeColor = ElifbaPalette.outline;

  final Widget child;
  final double radius;
  final Color color;
  final Color ringColor;
  final double ringWidth;
  final double edge;
  final Color edgeColor;
  final EdgeInsetsGeometry? padding;

  /// `true` → məzmun kartın künclərinə kəsilir (məs. yazı lövhəsinin
  /// içindəki konfeti). Kənar və halqa kəsilmir.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
    );
    Widget content =
        padding == null ? child : Padding(padding: padding!, child: child);
    if (clip) {
      content = ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        child: content,
      );
    }
    return DecoratedBox(
      decoration: squishyDecoration(
        color: color,
        shape: shape,
        edge: edge,
        edgeColor: edgeColor,
        ringWidth: ringWidth,
        ringColor: ringColor,
      ),
      child: content,
    );
  }
}

/// Səhnənin təpəsinin həndəsəsi.
enum StageHill {
  /// Heyvan kartı: `left/right −20, bottom −34, height 64`.
  card,

  /// Heyvan səhifəsinin böyük səhnəsi: `left/right −10 %, bottom −60,
  /// height 120`.
  hero,

  /// Təpə yoxdur — DS "şəkil yoxdur · placeholder" kartı: düz #ECE7FF səma,
  /// ortada yatan günəş. Şəklin olmadığı əvvəlcədən bilinəndə işlədin
  /// (`errorBuilder` təpəni gizlətmir; `content_integrity_test` hər heyvan
  /// şəklinin olduğunu təmin edir, ona görə bu hal tətbiqdə görünmür).
  none,
}

/// Yarı-real heyvan şəklini çərçivələyən yumşaq "səhnə": #ECE7FF səma,
/// #F3D9EC təpə, üstündə uşaq (şəkil).
///
/// [complete] → səma əvəzinə statik günəş şüaları (`at 50% 70%`). Şəklin
/// içəri boşluğu çağıranındır: kartda `fromLTRB(22, 16, 22, 8)`,
/// `cacheWidth: kAnimalThumbDecodeWidth`; böyük səhnədə 150 dp (412-də 180)
/// enində mərkəzdə qutu, `top 12, bottom 10`, `kAnimalHeroDecodeWidth`.
/// İçində `AnimatedContainer` YOXDUR.
class AnimalStage extends StatelessWidget {
  const AnimalStage({
    super.key,
    required this.child,
    this.radius = ElifbaRadius.r22,
    this.complete = false,
    this.hill = StageHill.card,
  });

  final Widget child;
  final double radius;
  final bool complete;
  final StageHill hill;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth.isFinite ? box.maxWidth : 0.0;
          final hillBox =
              hill == StageHill.card
                  ? const (
                    left: -20.0,
                    right: -20.0,
                    bottom: -34.0,
                    height: 64.0,
                  )
                  : (
                    left: -0.1 * w,
                    right: -0.1 * w,
                    bottom: -60.0,
                    height: 120.0,
                  );
          return Stack(
            fit: StackFit.expand,
            children: [
              if (complete)
                const CustomPaint(
                  painter: SunburstPainter(center: Alignment(0, 0.4)),
                )
              else
                const ColoredBox(color: ElifbaPalette.stageSky),
              if (hill != StageHill.none)
                Positioned(
                  left: hillBox.left,
                  right: hillBox.right,
                  bottom: hillBox.bottom,
                  height: hillBox.height,
                  child: const DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: OvalBorder(),
                      color: ElifbaPalette.stageHill,
                    ),
                  ),
                ),
              child,
            ],
          );
        },
      ),
    );
  }
}

/// Hər çatışmayan şəklin yerinə: buludun arxasında yatan günəş
/// (`Icons.pets`, `Icons.image_not_supported`, `Icons.fastfood` əvəzinə).
/// Boş hərf kartında ölçü 72, bulud #ECE7FF.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    this.size = 92,
    this.cloudColor = ElifbaPalette.surface,
  });

  final double size;
  final Color cloudColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SunMascot.sleepy(size: size, cloudColor: cloudColor),
      ),
    );
  }
}

/// CSS `border: Npx dashed C` — qutunun İÇİNDƏ qırıq xətt (`box-sizing:
/// border-box`). `CustomPaint.foregroundPainter` kimi işlədin.
///
/// İstifadə: yazı kartı (2.5, #7C63D9, r28), boş slot (2.5, #C6B8F5, r14),
/// səhv kafel (3, #DD4A5A, r14), səhv pazl xanasının xarici xətti (2,
/// #DD4A5A, [outset] 2).
class DashedRRectPainter extends CustomPainter {
  const DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    this.dash = 6,
    this.gap = 4,
    this.outset = 0,
  });

  final Color color;
  final double strokeWidth;

  /// Qutunun xarici radiusu.
  final double radius;
  final double dash;
  final double gap;

  /// > 0 → xətt qutunun KƏNARINDA, bu qədər aralı çəkilir (CSS
  /// `outline-offset`).
  final double outset;

  @override
  void paint(Canvas canvas, Size size) {
    final half = strokeWidth / 2;
    final rect =
        outset > 0
            ? (Offset.zero & size).inflate(outset + half)
            : (Offset.zero & size).deflate(half);
    final r = outset > 0 ? radius + outset + half : radius - half;
    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(r < 0 ? 0 : r)),
        );
    canvas.drawPath(
      dashPath(path, dashArray: CircularIntervalList<double>([dash, gap])),
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(DashedRRectPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius ||
      old.dash != dash ||
      old.gap != gap ||
      old.outset != outset;
}

/// Ekran spesifikasiyalarındakı ad (letter.md).
typedef DashedRRectBorderPainter = DashedRRectPainter;
