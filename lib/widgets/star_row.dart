import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../core/progress.dart';
import '../theme/theme.dart';

/// Dolu ulduzun üzü.
const Color kStarFill = ElifbaPalette.star;

/// Dolu ulduzun konturu.
const Color kStarEdge = ElifbaPalette.starEdge;

/// Boş ulduzun üzü.
const Color kStarOffFill = ElifbaPalette.starOff;

/// Boş ulduzun konturu.
const Color kStarOffEdge = ElifbaPalette.starOffEdge;

/// Köhnə ad (əvvəl #FFD54F idi) — hələ restyle olunmamış səhifələr
/// kompilyasiya olunsun deyə saxlanılır. İstifadə qalmayanda silin.
const Color kStarGold = kStarFill;

/// Ekran spesifikasiyalarındakı ad (letter.md, animal.md).
typedef ElifbaStar = StarGlyph;

/// Tək ulduz — dizaynın konturlu ulduz path-i (viewBox 24 × 24).
///
/// Boş ulduz rəngsiz deyil, solğun üz + kontur ilə çəkilir (DS: "Boş ulduz
/// kontur ilə göstərilir, rəng yox") — bütün fonlar artıq açıqdır, ona görə
/// fona görə boş rəng seçmək lazım deyil. Testlər ulduzları
/// `w is StarGlyph && w.filled` ilə sayır.
class StarGlyph extends StatelessWidget {
  const StarGlyph({
    super.key,
    required this.filled,
    this.size = 20,
    this.strokeWidth = 1.6,
  });

  final bool filled;

  /// Ulduzun ölçüsü (dp).
  final double size;

  /// Konturun qalınlığı viewBox vahidi ilə: sıralarda 1.6, təbriklərdə 1.4.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _StarPainter(filled: filled, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.filled, required this.strokeWidth});

  final bool filled;
  final double strokeWidth;

  /// DS path-i, bir dəfə oxunur. Nöqtələr: (12,2.8) (14.75,8.4) (20.9,9.3)
  /// (16.45,13.65) (17.5,19.77) (12,16.9) (6.5,19.8) (7.55,13.68) (3.1,9.3)
  /// (9.25,8.4).
  static final Path _path = parseSvgPathData(
    'M12 2.8l2.75 5.6 6.15.9-4.45 4.35 1.05 6.12L12 16.9l-5.5 2.9 '
    '1.05-6.12L3.1 9.3l6.15-.9z',
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      _path,
      Paint()
        ..isAntiAlias = true
        ..color = filled ? kStarFill : kStarOffFill,
    );
    canvas.drawPath(
      _path,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = filled ? kStarEdge : kStarOffEdge,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.filled != filled || old.strokeWidth != strokeWidth;
}

/// Dolu/boş ulduz sırası.
///
/// Tətbiqdə ulduz çox yerdə görünür (kitab, hərf səhifəsi, heyvan kartı,
/// heyvan səhnəsi) və hamısında eyni forma və rəngdə olmalıdır, ona görə tək
/// widget-də toplanıb. [filled] qiyməti [total]-dan böyük olsa da
/// təhlükəsizdir. İçində `AnimatedContainer` YOXDUR (kartın test qarmağı,
/// bax `Squishy`).
///
/// Ölçülər: 18 «Heyvanlar» sırası və səhnə nişanı, 20 heyvan kartı, 26 kitab
/// (ağ pill-in içində).
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.filled,
    this.total = ProgressStore.maxStarsPerLetter,
    this.size = 18,
    this.spacing = 0,
    this.strokeWidth = 1.6,
  });

  /// Dolu ulduz sayı.
  final int filled;

  /// Ümumi ulduz sayı.
  final int total;

  /// Bir ulduzun ölçüsü (dp).
  final double size;

  /// Ulduzlar arasındaki boşluq.
  final double spacing;

  /// Konturun qalınlığı (viewBox vahidi).
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final safeFilled = filled.clamp(0, total);
    return Semantics(
      label: '$total ulduzdan $safeFilled',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Padding(
              padding: EdgeInsets.only(right: i == total - 1 ? 0 : spacing),
              child: StarGlyph(
                filled: i < safeFilled,
                size: size,
                strokeWidth: strokeWidth,
              ),
            ),
        ],
      ),
    );
  }
}
