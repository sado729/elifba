import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Nişanın ölçüsünə görə ikon ölçüsü: 18 → 13, 20 → 14, 22 → 16, 32 → 20.
double _iconSizeFor(double size) {
  if (size <= 18) return 13;
  if (size <= 20) return 14;
  if (size <= 22) return 16;
  return (size * 0.625).roundToDouble();
}

/// Dairəvi ✓ / ✕ nişanı. Adi `Container`-dir, heç vaxt `AnimatedContainer`
/// deyil (kartın test qarmağı, bax `Squishy`). Semantikası yoxdur — "doğru",
/// "səhv", "tamamlandı" sözünü sahibi özü deyir.
class _RoundBadge extends StatelessWidget {
  const _RoundBadge({
    required this.size,
    required this.ringWidth,
    required this.color,
    required this.icon,
  });

  final double size;
  final double ringWidth;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            if (ringWidth > 0)
              BoxShadow(color: ElifbaPalette.surface, spreadRadius: ringWidth),
          ],
        ),
        child: Icon(
          icon,
          size: _iconSizeFor(size),
          color: ElifbaPalette.surface,
        ),
      ),
    );
  }
}

/// Doğru / tamamlandı nişanı: yaşıl dairə + ✓, ağ halqa ilə.
///
/// Yerləri (`Stack(clipBehavior: Clip.none)`): tab ✓ 20 `top −6, right −6`;
/// söz kafeli ✓ 22 `top −9, right −9`; kitab səhifəsi ✓ 32, halqa 3,
/// `top 14, left 14`; pazl xanası ✓ 18, halqa 0, `bottom 3, right 3`.
/// Kitabda tam bitmiş hərfin test markeridir (`star_ui_test`).
class CheckBadge extends StatelessWidget {
  const CheckBadge({super.key, this.size = 20, this.ringWidth = 2});

  final double size;

  /// Ağ halqanın qalınlığı; 0 → halqa yoxdur.
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    return _RoundBadge(
      size: size,
      ringWidth: ringWidth,
      color: ElifbaPalette.correct,
      icon: Icons.check_rounded,
    );
  }
}

/// Səhv nişanı: qırmızı dairə + ✕. Rəng heç vaxt tək siqnal deyil — həmişə
/// qırıq çərçivə və əyilmə ilə birlikdə gəlir.
///
/// Yerləri: söz kafeli ✕ 22 `top −11, right −11`; pazl xanası ✕ 18, halqa 0,
/// `bottom 3, right 3`.
class CrossBadge extends StatelessWidget {
  const CrossBadge({super.key, this.size = 20, this.ringWidth = 2});

  final double size;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    return _RoundBadge(
      size: size,
      ringWidth: ringWidth,
      color: ElifbaPalette.error,
      icon: Icons.close_rounded,
    );
  }
}
