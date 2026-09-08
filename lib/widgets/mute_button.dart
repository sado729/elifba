import 'package:flutter/material.dart';

import '../core/settings.dart';

/// Əsas ekrandakı sürətli səs açarı.
///
/// Valideyn qapısının ARXASINDA deyil: səsi susdurmaq təcili ehtiyacdır
/// (avtobus, yatmaq vaxtı) və 3 saniyə düymə saxlamağı tələb etmək mənasızdır.
/// Kanal-kanal incə ayarlar isə qapının arxasında qalır.
class MuteButton extends StatelessWidget {
  const MuteButton({super.key, this.color});

  /// İkonun rəngi — tünd bənövşəyi başlıqda ağ verilir.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final on = settings.masterSound;
        return IconButton(
          icon: Icon(on ? Icons.volume_up : Icons.volume_off, color: color),
          tooltip: on ? 'Səsi söndür' : 'Səsi aç',
          onPressed: () => settings.masterSound = !on,
        );
      },
    );
  }
}
