import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'elifba_card.dart';
import 'squishy.dart';

/// Qida çipi (DS "Qida çipi"): 56 dp pill, solda 44 dp şəkil diski.
///
/// * **Sakit:** ağ üz, 2 dp halqa + 4 dp kənar #D2C8F2, yazı #2E2A55, disk
///   [imageTint] (`ElifbaPalette.foodDiscTint(i)`).
/// * **Basılı** (`Squishy`): üz #F8F5FF, 4 dp enir, kənar 0.
/// * **Uçur** ([imageHidden], şəkil heyvana uçarkən): bütün disk 35 %.
/// * **Yedizdirilib** ([fed]): üz #DDF2E4, halqa + kənar #2E9460, yazı
///   #1A5A39, disk ağ, sonda `check_circle_rounded` 24 #2E9460. Yedizdirilmiş
///   heç vaxt yalnız rənglə göstərilmir — ✓ + yaşıl çərçivə. Yenidən
///   yedizdirmək olar.
///
/// Şəkil `Image.asset(cacheWidth: cacheWidth)` ilə açılır. [cacheWidth]
/// MƏCBURİDİR və hər yerdə `kFoodDecodeWidth` olmalıdır (gotcha 8 — fərqli en
/// fərqli keş açarıdır). Şəkil yoxdursa `ImagePlaceholder(size: 44)`.
class FoodChip extends StatelessWidget {
  const FoodChip({
    super.key,
    required this.name,
    required this.imagePath,
    required this.fed,
    required this.onTap,
    required this.cacheWidth,
    this.imageTint = const Color(0xFFFFF1C2),
    this.imageHidden = false,
    this.imageKey,
  });

  final String name;
  final String imagePath;
  final bool fed;
  final VoidCallback? onTap;

  /// `kFoodDecodeWidth` (animal_detail_page.dart).
  final int cacheWidth;

  /// Diskin fonu (yedizdiriləndə ağ olur).
  final Color imageTint;

  /// Şəkil uçarkən diskdə solğun qalır.
  final bool imageHidden;

  /// Uçuşun başlanğıc nöqtəsi üçün diskin açarı (bu günkü `_foodKeys`).
  final Key? imageKey;

  /// Şəklin diskin kənarından içəri boşluğu (44 dp disk → 36 dp şəkil).
  static const double _artInset = 4;

  @override
  Widget build(BuildContext context) {
    // Uçuş zamanı BÜTÜN disk (fon da) 35 %-dir (DS "Quru yem", ScreenAnimal).
    final disc = SizedBox.square(
      key: imageKey,
      dimension: ElifbaSize.chipImage,
      child: Opacity(
        opacity: imageHidden ? 0.35 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fed ? ElifbaPalette.surface : imageTint,
          ),
          // Şəkil diskin 4 dp içində (36 dp) — heyvan səhifəsindəki uçan disk
          // də belədir, uçuşun əvvəlində ölçü tullanmır.
          child: Padding(
            padding: const EdgeInsets.all(_artInset),
            child: Image.asset(
              imagePath,
              width: ElifbaSize.chipImage - 2 * _artInset,
              height: ElifbaSize.chipImage - 2 * _artInset,
              fit: BoxFit.contain,
              cacheWidth: cacheWidth,
              frameBuilder: (context, child, frame, wasSync) {
                if (wasSync) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: ElifbaMotion.imageFadeIn,
                  child: child,
                );
              },
              errorBuilder:
                  (context, error, stack) => const ImagePlaceholder(
                    size: ElifbaSize.chipImage - 2 * _artInset,
                  ),
            ),
          ),
        ),
      ),
    );

    return Squishy(
      onTap: onTap,
      color: fed ? ElifbaPalette.correctContainer : ElifbaPalette.surface,
      pressedColor:
          fed
              ? ElifbaPalette.correctContainer
              : ElifbaPalette.surfaceContainerLow,
      edge: ElifbaEdge.e4,
      edgeColor: fed ? ElifbaPalette.correct : ElifbaPalette.outline,
      ringColor: fed ? ElifbaPalette.correct : ElifbaPalette.outline,
      ringWidth: ElifbaRing.normal,
      height: ElifbaSize.chip,
      padding: EdgeInsetsDirectional.only(start: 6, end: fed ? 14 : 18),
      semanticLabel: fed ? '$name, yedizdirildi' : name,
      excludeChildSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          disc,
          SizedBox(width: fed ? 8 : 10),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: ElifbaTextStyles.chipLabel.copyWith(
                color:
                    fed
                        ? ElifbaPalette.onCorrectContainer
                        : ElifbaPalette.onSurface,
              ),
            ),
          ),
          if (fed) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_circle_rounded,
              size: 24,
              color: ElifbaPalette.correct,
            ),
          ],
        ],
      ),
    );
  }
}
