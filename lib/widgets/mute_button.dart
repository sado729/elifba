import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../theme/theme.dart';
import 'squishy.dart';

/// Əsas ekrandakı sürətli səs açarı.
///
/// Valideyn qapısının ARXASINDA deyil: səsi susdurmaq təcili ehtiyacdır
/// (avtobus, yatmaq vaxtı) və 3 saniyə düymə saxlamağı tələb etmək mənasızdır.
/// Kanal-kanal incə ayarlar isə qapının arxasında qalır.
///
/// Görünüş (DS "mute"): 48 dp ağ dairə, 3 dp kənar.
/// * **açıq:** kənar #D2C8F2, `volume_up_rounded` #5C45B5, «Səsi söndür»;
/// * **söndürülüb:** qırmızı halqa + kənar #DD4A5A, `volume_off_rounded`
///   #A12838, «Səsi aç». Söndürülmüş halda da basıla bilən görünməlidir —
///   səs yenidən onunla açılır. Bu, düz və kənarsız "söndürülmüş səs
///   düyməsi" (`AudioButton`) ilə qarışmamalıdır.
class MuteButton extends StatelessWidget {
  const MuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final on = settings.masterSound;
        return Squishy(
          onTap: () => settings.masterSound = !on,
          tooltip: on ? 'Səsi söndür' : 'Səsi aç',
          shape: const CircleBorder(),
          color: ElifbaPalette.surface,
          pressedColor: ElifbaPalette.surfaceContainerLow,
          edge: ElifbaEdge.e3,
          edgeColor: on ? ElifbaPalette.outline : ElifbaPalette.error,
          ringColor: on ? null : ElifbaPalette.error,
          ringWidth: on ? 0 : ElifbaRing.normal,
          width: ElifbaSize.touchMin,
          height: ElifbaSize.touchMin,
          alignment: Alignment.center,
          child: Icon(
            on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            size: 26,
            color:
                on
                    ? ElifbaPalette.secondaryEdge
                    : ElifbaPalette.onErrorContainer,
          ),
        );
      },
    );
  }
}
