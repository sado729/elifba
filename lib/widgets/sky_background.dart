import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Fonun növü.
enum SkyStyle {
  /// Səma qradiyenti (hərf, heyvan, yazı səhifələri).
  sky,

  /// Səma + buludlar və torpaq (yalnız ana səhifə).
  skyWithClouds,

  /// Valideyn sahəsi: düz #F8F5FF.
  parent,
}

/// Tam ekran fon — status və nav bar-ın da ARXASINDA çəkilir (gotcha 10).
///
/// İstifadə: `SkyBackground(child: Scaffold(backgroundColor:
/// Colors.transparent, …))` — qradiyent `AppBar`-ın və status bar-ın altında
/// da görünsün. Qradiyent statikdir, heç vaxt animasiya olunmur.
///
/// Səma: `#E4DEFF → #F1ECFF (46 %) → #FFF3EA`, yuxarıdan aşağı (DS skyTop,
/// skyMid, skyBottom).
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key, this.style = SkyStyle.sky, this.child});

  final SkyStyle style;
  final Widget? child;

  static const Gradient skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      ElifbaPalette.skyTop,
      ElifbaPalette.skyMid,
      ElifbaPalette.skyBottom,
    ],
    stops: [0, 0.46, 1],
  );

  @override
  Widget build(BuildContext context) {
    final decoration =
        style == SkyStyle.parent
            ? const BoxDecoration(color: ElifbaPalette.surfaceContainerLow)
            : const BoxDecoration(gradient: skyGradient);
    Widget? content = child;
    if (style == SkyStyle.skyWithClouds) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: _Clouds()),
          if (child != null) child!,
        ],
      );
    }
    return DecoratedBox(
      decoration: decoration,
      child: content ?? const SizedBox.expand(),
    );
  }
}

/// Ana səhifənin buludları və ağ torpağı (ScreenHome, home.md §4.2).
/// Buludlar status bar-ın ALTINDAN ölçülür (`top + 76`, `top + 50`;
/// maketlərin 24 dp status bar-ı ilə 100 / 74), torpaq isə fiziki ekranın
/// altından (`bottom: −80`).
class _Clouds extends StatelessWidget {
  const _Clouds();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Bulud A: 170 × 60 pill, 80 %.
              Positioned(
                top: top + 76,
                left: -50,
                width: 170,
                height: 60,
                child: const DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: StadiumBorder(),
                    color: Color(0xCCFFFDFB),
                  ),
                ),
              ),
              // Bulud B: 90 dp dairə, 80 %.
              Positioned(
                top: top + 50,
                left: 20,
                width: 90,
                height: 90,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xCCFFFDFB),
                  ),
                ),
              ),
              // Torpaq: ekranın 140 %-i enində ellips, aşağıdan −80.
              Positioned(
                bottom: -80,
                left: -0.2 * w,
                width: 1.4 * w,
                height: 180,
                child: const DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: OvalBorder(),
                    color: ElifbaPalette.surface,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Jest nav bar-ının arxasında yumşaq solğunlaşma (maketlərdəki 24 dp zolaq).
///
/// `Stack`-in içində qoyulur; nav bar-ın hündürlüyü 0 olanda heç nə çəkmir.
/// Tutacaq xəttini ÇƏKMİR — onu sistem çəkir.
class NavBarFade extends StatelessWidget {
  const NavBarFade({super.key, this.parent = false});

  /// `true` → ayarlar səhifəsinin düz fonuna uyğun.
  final bool parent;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.viewPaddingOf(context).bottom;
    if (h <= 0) return const SizedBox.shrink();
    final end = parent ? ElifbaPalette.navFadeParent : ElifbaPalette.navFadeSky;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: h,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [end.withAlpha(0), end],
            ),
          ),
        ),
      ),
    );
  }
}
