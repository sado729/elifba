import 'package:flutter/widgets.dart';

/// Boşluqlar — DS 4 dp şəbəkəsi.
abstract final class ElifbaSpace {
  /// İkon–mətn.
  static const double s1 = 4;

  /// Çiplər arası.
  static const double s2 = 8;

  /// Şəbəkə aralığı.
  static const double s3 = 12;

  /// Ekran kənarı. Ekran maketləri 360 və 412-də eyni 16 işlədir (DS 412 üçün
  /// 20 deyir) — ekran qalib gəlir.
  static const double s4 = 16;

  /// DS-in 412 dp ekran kənarı; ekranlar işlətmir.
  static const double s5 = 20;

  /// Kartın içi.
  static const double s6 = 24;

  /// Bölmələr arası.
  static const double s8 = 32;

  /// Təbrik kartı.
  static const double s10 = 40;

  /// Ekranın yan kənarı (360 və 412).
  static const double gutter = s4;
}

/// Künc radiusları.
abstract final class ElifbaRadius {
  /// Pazl lövhəsinin xanası.
  static const double r6 = 6;

  /// Tooltip, pazl səbətindəki parça.
  static const double r8 = 8;

  /// Kafel, slot, pazl miniatürü.
  static const double r14 = 14;

  /// Pazl lövhəsi, snackbar.
  static const double r16 = 16;

  /// Ayarlar qrupu, pazl səbəti.
  static const double r20 = 20;

  /// Heyvan kartının səhnəsi.
  static const double r22 = 22;

  /// Məlumat / bölmə kartları, şəkil baxışı.
  static const double r24 = 24;

  /// Kart, dialoq, yazı lövhəsi.
  static const double r28 = 28;

  /// Kitab səhifəsi, təbrik kartı, böyük səhnə.
  static const double r32 = 32;

  /// Düymə, tab, çip — əslində `StadiumBorder` / `CircleBorder` işlədin.
  static const double pill = 999;
}

/// "Kənar" — kölgənin yerinə düz alt kənarın hündürlüyü. Basanda 0 olur.
abstract final class ElifbaEdge {
  /// Düz — valideyn sahəsi.
  static const double e0 = 0;

  /// Səhnədəki ulduz nişanı.
  static const double e2 = 2;

  /// Toolbar ikonu, mute, ümumi ulduz pill-i.
  static const double e3 = 3;

  /// Çip, tab, kafel, məlumat kartı, 48 dp səs düyməsi, PillButton S.
  static const double e4 = 4;

  /// L/M düymələr, 56/64 dairəvi düymələr.
  static const double e5 = 5;

  /// Heyvan kartı, yazı lövhəsi.
  static const double e6 = 6;

  /// Kitab səhifəsi, təbrik kartı.
  static const double e8 = 8;
}

/// Xarici halqanın qalınlığı (`BoxShadow(spreadRadius: w)`, yer tutmur).
abstract final class ElifbaRing {
  /// Qapı düyməsinin daxili halqası, seqment konturu.
  static const double hairline = 1.5;

  /// Ağ səthlər.
  static const double normal = 2;

  /// Qırıq xətt: yazı kartı, boş slot.
  static const double dashed = 2.5;

  /// Doğru kafel, bitmiş lövhə, kitabdakı ✓ halqası, səhv qırıq xətt.
  static const double strong = 3;
}

/// Ölçülər (dp).
abstract final class ElifbaSize {
  /// Ən kiçik toxunma sahəsi.
  static const double touchMin = 48;

  /// Uşağın əsas hərəkətləri üçün toxunma sahəsi.
  static const double touchChild = 64;

  /// Bütün üst panellər.
  static const double toolbar = 64;

  /// Geri düyməsi, chevron-lar.
  static const double toolbarButton = 48;

  /// Kitab oxları.
  static const double navRound = 64;

  static const double buttonL = 64;
  static const double buttonM = 56;
  static const double buttonS = 52;

  /// Dairəvi səs düyməsi: böyük / orta.
  static const double audioL = 56;
  static const double audioM = 48;

  static const double tab = 48;
  static const double chip = 56;
  static const double chipImage = 44;

  static const double badgeS = 18;
  static const double badgeM = 20;
  static const double badgeL = 22;
  static const double badgeBook = 32;

  static const double gateHold = 72;
  static const double gateRingBox = 112;

  static const double snackbar = 52;
  static const double parentButton = 48;

  static const double dialogMaxWidth = 320;
  static const double gateMaxWidth = 312;
  static const double creditsMaxWidth = 340;

  static const double celebrationSmallMaxWidth = 280;
  static const double celebrationBigMaxWidth = 300;

  static const double puzzleThumb = 60;
  static const double heroBadgeHeight = 32;
  static const double pageChipHeight = 40;
  static const double totalStarsHeight = 44;

  /// Söz kafeli heç vaxt 44 dp-dən kiçilmir (DS), ən çox 56.
  static const double minTile = 44;
  static const double maxTile = 56;
}

/// Ekran ölçüsünə görə qərarlar.
abstract final class ElifbaLayout {
  /// Ekran maketləri `w >= 400`-də dəyişir (360 və 412 dizaynları).
  static const double largeBreakpoint = 400;

  /// 412 dp maketi tətbiq olunurmu.
  static bool isLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= largeBreakpoint;
}
