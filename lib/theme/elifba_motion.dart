import 'package:flutter/animation.dart';

import '../core/settings.dart';

/// Bütün müddətlər və əyrilər, azaldılmış variantları ilə.
///
/// "Azaldılmış hərəkət" YALNIZ `AppSettings.instance.reduceMotion` deməkdir —
/// sistemin `MediaQuery.disableAnimations` bayrağı bilərəkdən oxunmur (bu
/// günkü tətbiq də oxumur). Squish basışı və 500 ms səhifə çevrilməsi
/// azaldılmır: onlar birbaşa toxunuş cavabıdır. Təbriklər, qida uçuşu,
/// doğru/səhv pop + silkələnmə, səsin "oxuyur" nəbzi, günəş şüalarının
/// fırlanması və yazının silkələnməsi/nəbzi azaldılır — forma və ikon qalır,
/// hərəkət gedir.
///
/// Sonsuz animasiyalar (səs nəbzi, böyük təbrikin şüaları) yalnız öz
/// vəziyyətləri aktiv olanda işləyir, ona görə boş ekranda `pumpAndSettle`
/// bitir. UI mərhələləri üçün `Timer`/`Future.delayed` YOX, yalnız
/// `AnimationController` işlənir.
abstract final class ElifbaMotion {
  /// Tək azaldılmış-hərəkət açarı. Animasiyanın BAŞLADIĞI anda oxuyun
  /// (`GatedPlayer`-in `isOn()`-u çalma anında oxuduğu kimi).
  static bool get reduced => AppSettings.instance.reduceMotion;

  /// Widget-lərin `bool? reduceMotion` parametri üçün: verilibsə o, yoxdursa
  /// [reduced]. Testlər dəyəri ayarlara toxunmadan məcbur edə bilsin deyə.
  static bool isReduced([bool? override]) => override ?? reduced;

  // ------------------------------------------------- squish (azaldılmır)

  static const Duration pressIn = Duration(milliseconds: 90);
  static const Curve pressInCurve = Curves.easeOut;
  static const Duration release = Duration(milliseconds: 140);

  /// Buraxılış "easeOutBack": təxminən 10 % yuxarı aşıb yerinə oturur.
  static const Curve releaseCurve = Curves.easeOutBack;

  /// Geri dönən controller üçün ([CurvedAnimation.reverseCurve]):
  /// `CurvedAnimation` əyrini 1 → 0 gedən dəyərə tətbiq edir, ona görə
  /// çevrilmiş forma lazımdır.
  static final Curve releaseCurveReversed = Curves.easeOutBack.flipped;

  // ------------------------------------- naviqasiya (mövcud, dəyişməyib)

  static const Duration bookFlip = Duration(milliseconds: 500);
  static const Curve bookFlipCurve = Curves.easeInOutCubic;
  static const Duration routeSlide = Duration(milliseconds: 500);
  static const Curve routeSlideCurve = Curves.easeInOutCubic;
  static const Duration imageFadeIn = Duration(milliseconds: 400);

  /// Hərf məlumat kartının açılıb-bağlanması.
  static const Duration expand = Duration(milliseconds: 250);
  static const Curve expandCurve = Curves.easeInOut;

  /// Seçim rənginin keçidi (tab, rejim düyməsi).
  static const Duration selection = Duration(milliseconds: 140);

  // --------------------------------------------------------- doğru / səhv

  static const Duration correctPop = Duration(milliseconds: 240);
  static const double correctPopScale = 1.12;
  static const Duration wrongShake = Duration(milliseconds: 280);

  /// `dx = sin(3πt) · 6 · (1 − t)` — `TracingCanvas`-dakı sönən sinus.
  static const double wrongShakeAmplitude = 6;

  /// Səhv kafelin əyilməsi — statik formadır, azaldılmış hərəkətdə də qalır.
  static const double wrongTiltDegrees = -5;

  /// Pazl lövhəsinin "bitdi" görünüşünə keçidi (`AnimatedContainer`).
  static const Duration boardDone = Duration(milliseconds: 200);

  // ------------------------------------------------------- yazı oyunu
  // trace.md §2.1.1, §4.6, §7.

  /// Səhv toxunuşda kartın silkələnməsi: 280 ms ([wrongShake]), 8 dp.
  static const double traceShakeAmplitude = 8;

  /// Səhv toxunuşun ✕ nişanı: cəmi 900 ms; 0.6 → 1 miqyas ilk 160 ms
  /// easeOutBack (azaldılmışda 1-dən başlayır); 700 ms-dən 900-ə xətti itir.
  static const Duration traceRejectMarker = Duration(milliseconds: 900);
  static const Duration traceRejectScaleIn = Duration(milliseconds: 160);
  static const Curve traceRejectScaleInCurve = Curves.easeOutBack;
  static const double traceRejectScaleFrom = 0.6;
  static const Duration traceRejectFadeStart = Duration(milliseconds: 700);

  /// Ulduzun dolması (boş → dolu) — `AnimatedSwitcher` fade; azaldılmış
  /// hərəkətdə də qalır.
  static const Duration starFillFade = Duration(milliseconds: 200);

  // --------------------------------------------------- səs "oxuyur" nəbzi

  /// 0 → 6 → 0 = 1.2 s dövr.
  static const Duration audioPulseHalf = Duration(milliseconds: 600);
  static const Curve audioPulseCurve = Curves.easeInOut;
  static const double audioRingMax = 6;

  /// Azaldılmış hərəkətdə dairəvi düymənin sabit halqası.
  static const double audioRingStatic = 5;

  /// Azaldılmış hərəkətdə «Dinlə» pill-inin sabit halqası.
  static const double audioRingStaticPill = 4;

  // ----------------------------------------------------------------- qida
  // animal.md §7.4 (qidalandırma hərəkətinin sahibi) — ScreenAnimal-ın
  // keyframe-ləri DS-in "easeInOutCubic" qısaltmasından üstündür.

  /// Uçuş (bir controller, 900 ms).
  static const Duration foodFlight = Duration(milliseconds: 900);

  /// Uçuşun Y və miqyas əyrisi; X XƏTTİDİR (`lerp(s.dx, e.dx, t)`) — qövs
  /// buradan alınır.
  static const Curve foodFlightCurve = Cubic(0.2, 0.9, 0.35, 1.0);
  static const double foodFlightEndScale = 0.6;

  /// Çatma (uçuşdan sonra bir controller, 400 ms): parıltı 1 → 0 easeOut
  /// bütün 400 ms; qida 0.6 → 1.15 → 1 ilk [foodArrivalPop]-da, sonra son
  /// [foodPopFade]-də itir.
  static const Duration foodArrival = Duration(milliseconds: 400);
  static const Duration foodArrivalPop = Duration(milliseconds: 240);
  static const double foodArrivalPopScale = 1.15;
  static const Duration foodPopFade = Duration(milliseconds: 160);
  static const Duration foodGlow = Duration(milliseconds: 400);
  static const double foodGlowStartAlpha = 0.40;

  /// Azaldılmış hərəkət: uçuş yox; qida heyvanın üstündə 200 ms görünür,
  /// 200 ms qalır, 200 ms itir — 600 ms-də "yedi" sayılır ([foodReducedTotal]).
  static const Duration foodReducedFade = Duration(milliseconds: 200);
  static const Duration foodReducedHold = Duration(milliseconds: 200);
  static const Duration foodReducedTotal = Duration(milliseconds: 600);

  // ------------------------------------------------------------- təbriklər

  static const Duration celebrationEnter = Duration(milliseconds: 320);
  static const Curve celebrationEnterCurve = Curves.easeOutBack;
  static const double celebrationEnterFromScale = 0.85;
  static const Duration celebrationEnterReducedSmall = Duration(
    milliseconds: 200,
  );
  static const Duration celebrationEnterReducedBig = Duration(
    milliseconds: 250,
  );

  /// Scrim-in görünməsi.
  static const Duration scrimFade = Duration(milliseconds: 200);

  /// Böyük təbrikin tək giriş controller-i; aşağıdakılar onun `Interval`-larıdır.
  static const Duration bigIntro = Duration(milliseconds: 800);

  /// Günəş aşağıdan sıçrayır: +40 dp → 0, 0–400 ms, easeOutBack.
  static const Duration sunRise = Duration(milliseconds: 400);
  static const double sunRiseOffset = 40;

  /// Günəşin görünməsi: 0–120 ms.
  static const Duration sunFadeIn = Duration(milliseconds: 120);

  /// Hər ulduz 0 → 1.12 → 1, 240 ms.
  static const Duration starPop = Duration(milliseconds: 240);

  /// Ulduzların başlama anları: sol, orta, sağ.
  static const List<int> starPopStartsMs = [200, 320, 440];

  /// Böyük təbrikin şüaları: 8 s-də bir dövr, xətti, təkrar.
  static const Duration haloTurn = Duration(seconds: 8);

  /// Kiçik təbrikdə ulduzun sayğaca uçuşu (istəyə bağlı, P2).
  static const Duration starFlight = Duration(milliseconds: 600);

  static const Duration confettiSmall = Duration(milliseconds: 1200);
  static const Duration confettiBig = Duration(milliseconds: 2000);

  // ------------------------------- mövcud davranış vaxtları (dəyişməyib)

  /// Pazl bitəndən sonra təbrik dialoqu.
  static const Duration puzzleDialogDelay = Duration(milliseconds: 1500);

  /// «İpucu» 2 s göstərilir.
  static const Duration hint = Duration(seconds: 2);

  /// Valideyn qapısı dolandan sonra 200 ms "tamam" anı.
  static const Duration gateDoneBeat = Duration(milliseconds: 200);
  static const Duration tracePulse = Duration(milliseconds: 1600);
  static const Duration traceDemoPerUnit = Duration(milliseconds: 900);
}
