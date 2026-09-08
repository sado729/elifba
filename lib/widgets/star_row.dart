import 'package:flutter/material.dart';

import '../core/progress.dart';

/// Ulduzun qızıl rəngi. `letter_writing_page.dart`-dakı tək ulduz ilə eynidir —
/// bütün ekranlarda ulduz eyni rəngdə görünsün.
const Color kStarGold = Color(0xFFFFD54F);

/// Dolu/boş ulduz sırası.
///
/// Tətbiqdə ulduz üç yerdə görünür (əlifba kitabı, heyvan siyahısı, heyvan
/// detalı) və hər üçündə eyni forma və rəngdə olmalıdır, ona görə tək widget-də
/// toplanıb. [filled] qiyməti [total]-dan böyük olsa da təhlükəsizdir.
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.filled,
    this.total = ProgressStore.maxStarsPerLetter,
    this.size = 18,
    this.emptyColor = Colors.white38,
    this.spacing = 0,
  });

  /// Dolu ulduz sayı.
  final int filled;

  /// Ümumi ulduz sayı.
  final int total;

  /// Bir ulduzun ölçüsü (dp).
  final double size;

  /// Boş ulduzun rəngi — fona görə dəyişir (tünd fonda ağ, ağ kartda bənövşəyi).
  final Color emptyColor;

  /// Ulduzlar arasındaki boşluq.
  final double spacing;

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
              child: Icon(
                i < safeFilled
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: size,
                color: i < safeFilled ? kStarGold : emptyColor,
              ),
            ),
        ],
      ),
    );
  }
}
