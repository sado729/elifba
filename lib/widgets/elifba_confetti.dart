import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Konfetinin iki ölçüsü (DS: "ən çox 40 hissəcik").
enum ConfettiPreset {
  /// Kiçik qələbə: 26 hissəcik, 1.2 s.
  small(particles: 26, duration: ElifbaMotion.confettiSmall),

  /// Böyük qələbə: 40 hissəcik, 2 s.
  big(particles: 40, duration: ElifbaMotion.confettiBig);

  const ConfettiPreset({required this.particles, required this.duration});

  final int particles;
  final Duration duration;

  /// Bu preset üçün controller — sahibi (`State`) yaradır və `dispose` edir.
  ConfettiController createController() =>
      ConfettiController(duration: duration);
}

/// Konfeti hissəciyinin forması: hündürlük 8–16 bərabər paylanır, ona görə
/// təxminən hər üçdən biri 8 dp dairə, qalanları radius 2 olan düzbucaqlıdır.
Path elifbaConfettiPath(Size size) =>
    size.height < 10.67
        ? (Path()..addOval(const Rect.fromLTWH(0, 0, 8, 8)))
        : (Path()..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
        ));

/// `confetti` paketinin dizayna uyğun quraşdırılmış `ConfettiWidget`-i.
///
/// * `emissionFrequency: 0` → ilk kadrda DƏQİQ [ConfettiPreset.particles]
///   hissəcik çıxır, sonra heç vaxt əlavə olunmur (`confetti-0.8.0`
///   `ParticleSystem.update()`): DS həddi "gözlə ayarlamadan" qorunur.
/// * Widget HƏMİŞƏ ağacda qalır; `play()` isə çağırış yerində
///   `if (!AppSettings.instance.reduceMotion)` ilə bükülür (CLAUDE.md
///   gotcha 16). Bu widget özü heç vaxt `play()` çağırmır.
/// * Testlərdə konfeti oynayarkən `pumpAndSettle` etməyin: paket fiziki
///   addımı real saatla ölçür.
class ElifbaConfetti extends StatelessWidget {
  const ElifbaConfetti({
    super.key,
    required this.controller,
    this.preset = ConfettiPreset.small,
  });

  final ConfettiController controller;
  final ConfettiPreset preset;

  @override
  Widget build(BuildContext context) {
    return ConfettiWidget(
      confettiController: controller,
      blastDirectionality: BlastDirectionality.explosive,
      emissionFrequency: 0,
      numberOfParticles: preset.particles,
      maxBlastForce: 20,
      minBlastForce: 8,
      gravity: 0.25,
      particleDrag: 0.05,
      shouldLoop: false,
      colors: kConfettiColors,
      minimumSize: const Size(6, 8),
      maximumSize: const Size(12, 16),
      createParticlePath: elifbaConfettiPath,
    );
  }
}
