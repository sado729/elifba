import 'package:flutter/material.dart';

// Hər üslubun ümumi qaydaları:
// * `letterSpacing: 0` AÇIQ yazılır: `ThemeData` bizim `TextTheme`-i M3
//   defoltlarının üstünə birləşdirir, onlarda isə hərf aralığı var
//   (`bodyLarge` 0.5, `labelLarge` 0.1 …) — boş sahə onu miras alardı.
// * `leadingDistribution: even`: dizayn CSS line-height ilə qurulub, orada
//   sətir boşluğu yuxarı və aşağı bərabər bölünür. Bu olmasa mətn pill-in
//   içində mərkəzdə oturmur (Andika-nın təbii sətri 1.61 em-dir).
// * `height` = DS sətir hündürlüyü / şrift ölçüsü.
// * Rəng üslubun hissəsi deyil: tema `onSurface`-i özü verir, ekran isə
//   `copyWith(color: …)` ilə.
// * Comfortaa yalnız 700 ilə gəlir (başqa çəki istəməyin — Flutter səssizcə
//   700 göstərər), Andika-nın italik faylı yoxdur (`FontStyle.italic`
//   süni əyilmə verərdi).
// * Heç bir UI mətnində `toUpperCase()` yoxdur (CLAUDE.md gotcha 2).

/// Dizayn sisteminin `TextTheme`-i (DS `TYPES` cədvəli).
abstract final class ElifbaTypography {
  /// Başlıqlar, düymələr, hərflər, sayğaclar.
  static const String display = 'Comfortaa';

  /// Mətn, tablar, çiplər, valideyn düymələri.
  static const String body = 'Andika';

  static const TextTheme textTheme = TextTheme(
    // Hərf səhifəsindəki böyük hərf (412-də [displayLargeWide]).
    displayLarge: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 72,
      height: 80 / 72,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // Kitab səhifəsindəki hərf (412-də [displayMediumWide]).
    displayMedium: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 58,
      height: 64 / 58,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // DS-də yoxdur — yer boş qalmasın deyə doldurulub.
    displaySmall: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 36,
      height: 44 / 36,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // Təbrik başlığı.
    headlineLarge: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 28,
      height: 34 / 28,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // DS-də yoxdur — [headlineSmall] ilə eynidir.
    headlineMedium: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 26,
      height: 32 / 26,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // Söz tapmaca kafeli.
    headlineSmall: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 26,
      height: 32 / 26,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // Üst panel başlığı.
    titleLarge: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 22,
      height: 28 / 22,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // Bölmə başlığı, heyvan adı.
    titleMedium: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 18,
      height: 24 / 18,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // Sayğaclar: «41/96», «9/30», «Tamam!».
    titleSmall: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 15,
      height: 20 / 15,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // Uşaq düymələri M (L üçün [ElifbaTextStyles.buttonL]).
    labelLarge: TextStyle(
      fontFamily: display,
      fontWeight: FontWeight.w700,
      fontSize: 16,
      height: 20 / 16,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // Heyvan haqqında mətn.
    bodyLarge: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w400,
      fontSize: 18,
      height: 28 / 18,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // Hərf təsviri, dialoq mətni.
    bodyMedium: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // Ayarlarda alt mətn.
    bodySmall: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // Çip, tab, valideyn düyməsi.
    labelMedium: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w700,
      fontSize: 15,
      height: 20 / 15,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    // Tooltip.
    labelSmall: TextStyle(
      fontFamily: body,
      fontWeight: FontWeight.w700,
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
  );

  /// 412 dp ekranda [TextTheme.displayLarge] (DS "412: 80").
  static const TextStyle displayLargeWide = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w700,
    fontSize: 80,
    height: 88 / 80,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 412 dp ekranda [TextTheme.displayMedium] (DS "412: 64").
  static const TextStyle displayMediumWide = TextStyle(
    fontFamily: display,
    fontWeight: FontWeight.w700,
    fontSize: 64,
    height: 70 / 64,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );
}

/// Ekranların `TextTheme`-ə sığmayan adlı üslubları. Hamısı `letterSpacing: 0`,
/// `even`, rəngsiz — rəngi çağıran yer verir.
abstract final class ElifbaTextStyles {
  /// Kitab diskindəki hərf: 58, sətir 1.0 (maketdə `line-height:1`).
  static const TextStyle bookGlyph = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 58,
    height: 1.0,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 412 dp-də kitab hərfi: 64, sətir 1.0.
  static const TextStyle bookGlyphLarge = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 64,
    height: 1.0,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// PillButton L, «Yaşa!»: Comfortaa 18/20.
  static const TextStyle buttonL = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    height: 20 / 18,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// PillButton M: Comfortaa 16/20 (= `labelLarge`).
  static const TextStyle buttonM = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Kiçik təbrikdəki «Yenidən»: Comfortaa 17/20.
  static const TextStyle buttonMCelebration = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 17,
    height: 20 / 17,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// PillButton S (pazl idarələri): Comfortaa 14/18.
  static const TextStyle buttonS = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 18 / 14,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Sayğaclar: «41/96», «9/30», «4 / 16» (= `titleSmall`).
  static const TextStyle counter = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Səhnədəki ulduz nişanı «2/4»: Comfortaa 14/18.
  static const TextStyle heroCount = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 18 / 14,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Heyvan kartının adı: Comfortaa 17/22.
  static const TextStyle cardName = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 17,
    height: 22 / 17,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// «B hərfi haqqında oxu»: Comfortaa 16/22.
  static const TextStyle infoCardTitle = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 22 / 16,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// «Heyvanın adını düzgün doldur»: Comfortaa 17/23.
  static const TextStyle wordHeading = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 17,
    height: 23 / 17,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Söz kafeli (eni ≥ 52 dp): Comfortaa 26/32.
  static const TextStyle tileGlyph = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    height: 32 / 26,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Dar söz kafeli (eni < 52 dp): Comfortaa 24/30.
  static const TextStyle tileGlyphCompact = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 30 / 24,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// «B hərfini yaz» (oxların arasında, mərkəzdə): Comfortaa 20/26.
  static const TextStyle traceTitle = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 26 / 20,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Pazl lövhəsindəki «2 s» çipi: Comfortaa 13/16.
  static const TextStyle hintChip = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 13,
    height: 16 / 13,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Hər iki təbrik səviyyəsinin başlığı: Comfortaa 28/34 (= `headlineLarge`).
  static const TextStyle celebrationTitle = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 34 / 28,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Təbrik mətni: Andika 16/23.
  static const TextStyle celebrationBody = TextStyle(
    fontFamily: ElifbaTypography.body,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 23 / 16,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Valideyn dialoqlarının başlığı: Comfortaa 20/26.
  static const TextStyle dialogTitle = TextStyle(
    fontFamily: ElifbaTypography.display,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 26 / 20,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Valideyn qapısının başlığı — bilərəkdən sakit Andika 700 20/26.
  static const TextStyle gateTitle = TextStyle(
    fontFamily: ElifbaTypography.body,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 26 / 20,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Dialoq mətni: Andika 15/22.
  static const TextStyle dialogBody = TextStyle(
    fontFamily: ElifbaTypography.body,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 22 / 15,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Qida çipi: Andika 700 16/20.
  static const TextStyle chipLabel = TextStyle(
    fontFamily: ElifbaTypography.body,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Pill tablar, rejim və səviyyə düymələri: Andika 700 15/20 (= `labelMedium`).
  static const TextStyle tabLabel = TextStyle(
    fontFamily: ElifbaTypography.body,
    fontWeight: FontWeight.w700,
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Valideyn düymələri («Ləğv et», «Bağla», «Bəli, sil»): = [tabLabel].
  static const TextStyle parentButton = tabLabel;

  /// Ayar sətrinin başlığı: Andika 700 16/22.
  static const TextStyle listTitle = TextStyle(
    fontFamily: ElifbaTypography.body,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 22 / 16,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Ayar sətrinin alt mətni: Andika 14/20 (= `bodySmall`).
  static const TextStyle listSubtitle = TextStyle(
    fontFamily: ElifbaTypography.body,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Ayar bölməsinin başlığı («Səs», «Valideyn»): Andika 700 14/20, #5C45B5.
  /// Bu üslubda rəng bilərəkdən var — başlıq heç vaxt başqa rəngdə deyil.
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: ElifbaTypography.body,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
    color: Color(0xFF5C45B5),
  );

  /// Snackbar: Andika 15/20.
  static const TextStyle snackbar = TextStyle(
    fontFamily: ElifbaTypography.body,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// «Bu hərflə başlayan heyvan yoxdur, amma …»: Andika 16/23.
  static const TextStyle emptyState = TextStyle(
    fontFamily: ElifbaTypography.body,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 23 / 16,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Söz kafelinin hərf üslubu kafelin eninə görə: 52 dp-dən dar kafeldə 24.
  static TextStyle tileGlyphFor(double tileWidth) =>
      tileWidth >= 52 ? tileGlyph : tileGlyphCompact;

  /// Uzun abzasın ən böyük eni (DS: sətir ən çox 34 em) — yalnız planşetdə
  /// təsir edir.
  static double maxLineWidth(TextStyle style) => 34 * (style.fontSize ?? 16);
}
