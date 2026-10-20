import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Nazik tərəqqi zolağı: 6 dp, radius 3, yol #E6E1F5, dolu hissə #7C63D9;
/// tam olanda bütün en yaşıl #2E9460.
///
/// Öz widget-idir, `LinearProgressIndicator` DEYİL: M3-ün yeni variantı sonda
/// nöqtə və yolda boşluq çəkə bilir. «Heyvanlar» sırasında `Expanded`-in
/// içində işlənir.
class ElifbaProgressBar extends StatelessWidget {
  const ElifbaProgressBar({
    super.key,
    required this.value,
    this.complete = false,
  });

  /// 0..1; aralıqdan kənar dəyər kəsilir.
  final double value;

  /// `true` → yaşıl və tam (dəyərdən asılı olmayaraq).
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final v = complete ? 1.0 : value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(v * 100).round()} %',
      child: SizedBox(
        height: 6,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(3)),
          child: ColoredBox(
            color: ElifbaPalette.outlineVariant,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                // Dolu hissənin sağ ucu da yuvarlaqdır (DS: radius 3).
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        complete
                            ? ElifbaPalette.correct
                            : ElifbaPalette.secondary,
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
