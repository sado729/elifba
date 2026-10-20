import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

/// Wordmark-ın rəng dəsti: brend aktivlərindəki (Claude Design, 4.1) dörd
/// variant, hər fon üçün biri. Hex-lər `branding/wordmark/*.svg` ilə eynidir.
class ElifbaWordmarkColors {
  const ElifbaWordmarkColors({required this.ink, required this.sun, this.ring});

  /// Hərflərin rəngi.
  final Color ink;

  /// «ı»-nın üstündəki günəş.
  final Color sun;

  /// Günəşin halqası. Monoxrom variantda halqa yoxdur.
  final Color? ring;

  /// Əsas variant: açıq fon (səma, #E4DEFF → #FFF3EA).
  static const light = ElifbaWordmarkColors(
    ink: Color(0xFF2E2A55),
    sun: Color(0xFFFFA62B),
    ring: Color(0xFFFFF1CC),
  );

  /// Lavanda fon (#7C63D9).
  static const lavender = ElifbaWordmarkColors(
    ink: Color(0xFFFFFDFB),
    sun: Color(0xFFFFC547),
    ring: Color(0xFF9A84EC),
  );

  /// Tək rəng, halqasız.
  static const mono = ElifbaWordmarkColors(
    ink: Color(0xFF2E2A55),
    sun: Color(0xFF2E2A55),
  );

  /// Tünd fon (#2E2A55).
  static const dark = ElifbaWordmarkColors(
    ink: Color(0xFFFFFDFB),
    sun: Color(0xFFFFC547),
    ring: Color(0xFF4A4578),
  );
}

/// "Əlifba" loqosu: Comfortaa Bold-dan kontura çevrilmiş yazı, nöqtəsiz «ı»-nın
/// üstündəki günəş onu «i» kimi oxutdurur.
///
/// Brend qaydasına görə loqo `Text` kimi yox, kontur kimi çəkilir: başqa şriftlə
/// yazmaq, günəşi adi nöqtəyə çevirmək, hərfləri rəngləmək və uzatmaq olmaz.
/// Ona görə rəsm həmişə eyni nisbətdə miqyaslanır, verilən yerə sığmasa belə
/// dartılmır. 24 dp-dən alçaq ölçüdə halqa seçilmir — orada ikon işlədilir.
class ElifbaWordmark extends StatelessWidget {
  const ElifbaWordmark({
    super.key,
    this.height = 48,
    this.colors = ElifbaWordmarkColors.light,
  });

  /// Rəsmin hündürlüyü (dp); eni nisbətdən gəlir.
  final double height;

  final ElifbaWordmarkColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Əlifba',
      excludeSemantics: true,
      child: CustomPaint(
        size: Size(height * kElifbaWordmarkViewBox.aspectRatio, height),
        painter: _WordmarkPainter(colors),
      ),
    );
  }
}

/// Konturun koordinat sahəsi (SVG `viewBox`).
const Size kElifbaWordmarkViewBox = Size(319.7, 132);

/// Günəşin mərkəzi və radiusları — «ı»-nın oxu üzərindədir.
const Offset kElifbaWordmarkSunCenter = Offset(130.1, 26.7);
const double kElifbaWordmarkSunRadius = 17;
const double kElifbaWordmarkRingRadius = 26;

/// "Əlifba" hərflərinin konturu. Bu fayldakı bütün ölçülər
/// `branding/wordmark/*.svg` ilə hərfi-hərfinə eynidir; `wordmark_test.dart`
/// bunu yoxlayır.
const String kElifbaWordmarkPath =
    'M43.7 122.9L43.7 122.9Q35.7 122.9 28.9 120.0Q22.1 117.2 17.1 112'
    'Q12 106.8 9.2 99.8Q6.4 92.9 6.4 84.7L6.4 84.7Q6.4 81.9 8.3 80.2'
    'Q10.2 78.4 13.1 78.4L13.1 78.4L68.6 78.4Q67.8 72.3 65 67.3L65 67.3'
    'Q61 60.3 54.1 56.3Q47.2 52.4 38.5 52.4L38.5 52.4Q33.5 52.4 29.0 53.9'
    'Q24.4 55.4 20.5 58L20.5 58Q18.9 59.1 17.2 58.9Q15.5 58.7 14.3 57.4'
    'L14.3 57.4Q13.1 56 13.2 54.3Q13.2 52.5 14.6 51.4L14.6 51.4'
    'Q19.7 47.3 25.8 45.1Q31.9 43 39.5 43L39.5 43Q47.8 43 55.0 46'
    'Q62.1 49 67.5 54.5Q72.8 59.9 75.8 67.3Q78.7 74.6 78.7 83.4L78.7 83.4'
    'Q78.7 91.8 76.0 99Q73.4 106.2 68.7 111.5Q63.9 116.9 57.6 119.9'
    'Q51.2 122.9 43.7 122.9ZM68.7 87.6L68.7 87.6L16.7 87.6Q17.3 94.5 20.5 100'
    'L20.5 100Q24.1 106.3 30.2 110.0Q36.3 113.6 43.7 113.6L43.7 113.6'
    'Q50.9 113.6 56.6 109.7Q62.3 105.7 65.6 98.8L65.6 98.8'
    'Q68.1 93.7 68.7 87.6ZM107.2 122L107 122Q102.6 122 99.2 119.6'
    'Q95.8 117.2 93.9 113.0Q92 108.9 92 103.5L92 103.5L92 48.9'
    'Q92 46.7 93.4 45.3Q94.8 43.9 97 43.9L97 43.9Q99.2 43.9 100.6 45.3'
    'Q102 46.7 102 48.9L102 48.9L102 103.5Q102 107.2 103.4 109.6'
    'Q104.8 112 107 112L107 112L109.5 112Q111.5 112 112.8 113.4'
    'Q114 114.8 114 117L114 117Q114 119.2 112.1 120.6Q110.2 122 107.2 122'
    'L107.2 122ZM130.1 122L130.1 122Q127.9 122 126.5 120.5'
    'Q125 119.1 125 116.9L125 116.9L125 72.4Q125 70.1 126.5 68.7'
    'Q127.9 67.3 130.1 67.3L130.1 67.3Q132.4 67.3 133.8 68.7'
    'Q135.2 70.1 135.2 72.4L135.2 72.4L135.2 116.9Q135.2 119.1 133.8 120.5'
    'Q132.4 122 130.1 122ZM160.1 122L160.1 122Q158.2 122 156.7 120.6'
    'Q155.2 119.2 155.2 116.9L155.2 116.9L155.2 77.9L150.9 77.9'
    'Q148.8 77.9 147.5 76.7Q146.2 75.5 146.2 73.7L146.2 73.7'
    'Q146.2 71.7 147.5 70.5Q148.8 69.3 150.9 69.3L150.9 69.3L155.2 69.3'
    'L155.2 67.6Q155.2 60.4 158.0 55.1Q160.9 49.8 166 46.8'
    'Q171.1 43.9 177.8 43.9L177.8 43.9Q180 43.9 181.4 45.2'
    'Q182.9 46.5 182.9 48.5L182.9 48.5Q182.9 50.4 181.4 51.8'
    'Q180 53.1 177.8 53.1L177.8 53.1Q174.1 53.1 171.3 54.8'
    'Q168.5 56.5 166.9 59.5Q165.4 62.5 165.4 66.6L165.4 66.6L165.4 69.3'
    'L175.6 69.3Q177.7 69.3 179 70.5Q180.3 71.7 180.3 73.7L180.3 73.7'
    'Q180.3 75.5 179 76.7Q177.7 77.9 175.6 77.9L175.6 77.9L165.4 77.9'
    'L165.4 116.9Q165.4 119.2 164 120.6Q162.6 122 160.1 122ZM218.4 122.4'
    'L218.4 122.4Q210.6 122.4 204.4 118.8Q198.2 115.1 194.6 108.8'
    'Q191.0 102.5 190.9 94.6L190.9 94.6L190.9 49Q190.9 46.7 192.3 45.3'
    'Q193.8 43.9 196.0 43.9L196.0 43.9Q198.3 43.9 199.7 45.3'
    'Q201.1 46.7 201.1 49L201.1 49L201.1 76Q204.6 71.8 209.5 69.3'
    'Q214.5 66.9 220.4 66.9L220.4 66.9Q227.7 66.9 233.5 70.5'
    'Q239.3 74.2 242.6 80.4Q246 86.7 246 94.6L246 94.6Q246 102.5 242.3 108.8'
    'Q238.7 115.1 232.5 118.8Q226.3 122.4 218.4 122.4ZM218.4 113.4'
    'L218.4 113.4Q223.5 113.4 227.5 111.0Q231.5 108.5 233.8 104.2'
    'Q236.2 99.9 236.2 94.6L236.2 94.6Q236.2 89.2 233.8 85'
    'Q231.5 80.8 227.5 78.3Q223.5 75.9 218.4 75.9L218.4 75.9'
    'Q213.4 75.9 209.3 78.3Q205.3 80.8 203.0 85Q200.7 89.2 200.7 94.6'
    'L200.7 94.6Q200.7 99.9 203.0 104.2Q205.3 108.5 209.3 111.0'
    'Q213.4 113.4 218.4 113.4ZM284 122.4L284 122.4Q276.7 122.4 270.9 118.8'
    'Q265.1 115.1 261.8 108.8Q258.4 102.6 258.4 94.7Q258.4 86.8 262.1 80.5'
    'Q265.7 74.2 271.9 70.5Q278.2 66.9 286 66.9Q293.8 66.9 300 70.5'
    'Q306.2 74.2 309.9 80.5Q313.5 86.8 313.5 94.7L313.5 94.7L313.5 117'
    'Q313.5 119.2 312.1 120.7Q310.6 122.1 308.4 122.1Q306.2 122.1 304.8 120.7'
    'Q303.3 119.2 303.3 117L303.3 117L303.3 113.3Q300.7 116.5 297.1 118.7'
    'L297.1 118.7Q291.3 122.4 284 122.4ZM286 113.4L286 113.4'
    'Q291.1 113.4 295.1 111.0Q299.1 108.5 301.4 104.3Q303.7 100 303.7 94.7'
    'L303.7 94.7Q303.7 89.3 301.4 85.0Q299.1 80.8 295.1 78.3'
    'Q291.1 75.9 286 75.9L286 75.9Q281 75.9 276.9 78.3Q272.9 80.8 270.6 85.0'
    'Q268.2 89.3 268.2 94.7L268.2 94.7Q268.2 100 270.6 104.3'
    'Q272.9 108.5 276.9 111.0Q281 113.4 286 113.4Z';

class _WordmarkPainter extends CustomPainter {
  _WordmarkPainter(this.colors);

  final ElifbaWordmarkColors colors;

  // Path bir dəfə parse olunur — hər kadrda yox.
  static final Path _ink = parseSvgPathData(kElifbaWordmarkPath);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / kElifbaWordmarkViewBox.width,
      size.height / kElifbaWordmarkViewBox.height,
    );
    canvas.translate(
      (size.width - kElifbaWordmarkViewBox.width * scale) / 2,
      (size.height - kElifbaWordmarkViewBox.height * scale) / 2,
    );
    canvas.scale(scale);
    canvas.drawPath(_ink, Paint()..color = colors.ink);
    final ring = colors.ring;
    if (ring != null) {
      canvas.drawCircle(
        kElifbaWordmarkSunCenter,
        kElifbaWordmarkRingRadius,
        Paint()..color = ring,
      );
    }
    canvas.drawCircle(
      kElifbaWordmarkSunCenter,
      kElifbaWordmarkSunRadius,
      Paint()..color = colors.sun,
    );
  }

  @override
  bool shouldRepaint(_WordmarkPainter oldDelegate) =>
      oldDelegate.colors.ink != colors.ink ||
      oldDelegate.colors.sun != colors.sun ||
      oldDelegate.colors.ring != colors.ring;
}
