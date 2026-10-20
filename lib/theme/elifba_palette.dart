import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../core/config.dart';

/// Hərfin bəzək rəng dəsti (dizayn sistemi, `SETS` cədvəli).
///
/// Bu rənglər yalnız bəzəkdir, heç bir məna daşımır: uşaq "bənövşəyi = səhv"
/// kimi bir qayda öyrənməməlidir. Tamamlanmış hərf/heyvan isə dəsti
/// [asComplete] ilə qızılı üzə dəyişir.
@immutable
class LetterColorSet {
  const LetterColorSet({
    required this.name,
    required this.tint,
    required this.deep,
    required this.edge,
  });

  /// Dəstin dizayndakı adı: 'Lavanda', 'Çəhrayı' …
  final String name;

  /// Kartın / səhifənin üzü.
  final Color tint;

  /// Hərfin rəngi — [tint] üzərində iri mətn kimi ən azı 4.6:1 kontrast verir.
  final Color deep;

  /// "Squishy" alt kənarı.
  final Color edge;

  /// Tam bitmiş hərfin görünüşü: üz `complete`, kənar `completeEdge`, hərfin
  /// rəngi ([deep]) dəyişmir.
  LetterColorSet asComplete() => LetterColorSet(
    name: name,
    tint: ElifbaPalette.complete,
    deep: deep,
    edge: ElifbaPalette.completeEdge,
  );

  @override
  bool operator ==(Object other) =>
      other is LetterColorSet &&
      other.name == name &&
      other.tint == tint &&
      other.deep == deep &&
      other.edge == edge;

  @override
  int get hashCode => Object.hash(name, tint, deep, edge);
}

/// Dizayndakı bütün xam rənglər — tək həqiqət mənbəyi.
///
/// Ekranlar hex yazmır: rolu olan rəng `ElifbaColors.of(context)` və ya
/// `Theme.of(context).colorScheme` ilə, `BuildContext` olmayan yerdə
/// (`CustomPainter`, testlər) isə buradan götürülür. Şəffaflıq lazım olanda
/// alfa hex-in içindədir (məs. 55 % → `0x8C`).
abstract final class ElifbaPalette {
  // ------------------------------------------------- ColorScheme rolları (DS)

  /// Əsas düymələr, kitab oxları, «Yaşa!».
  static const Color primary = Color(0xFFFFB547);

  /// [primary] üzərində mətn (7.8:1).
  static const Color onPrimary = Color(0xFF2E2A55);

  /// «İpucu» fonu.
  static const Color primaryContainer = Color(0xFFFFE7C2);
  static const Color onPrimaryContainer = Color(0xFF5A3A00);

  /// Səs, seçilmiş tab, açarlar.
  static const Color secondary = Color(0xFF7C63D9);

  /// [secondary] üzərində mətn (4.6:1).
  static const Color onSecondary = Color(0xFFFFFDFB);

  /// «Oxuyur» halqası, yazı kartı.
  static const Color secondaryContainer = Color(0xFFE4DEFF);
  static const Color onSecondaryContainer = Color(0xFF2E2A55);

  /// Heyvan səsi düyməsi.
  static const Color tertiary = Color(0xFFB03A6E);
  static const Color onTertiary = Color(0xFFFFFDFB);
  static const Color tertiaryContainer = Color(0xFFFFE0EC);
  static const Color onTertiaryContainer = Color(0xFFB03A6E);

  /// Səhv — yalnız ✕ ilə birlikdə.
  static const Color error = Color(0xFFDD4A5A);
  static const Color onError = Color(0xFFFFFDFB);
  static const Color errorContainer = Color(0xFFFCE1E4);
  static const Color onErrorContainer = Color(0xFFA12838);

  /// Kart, dialoq, bulud.
  static const Color surface = Color(0xFFFFFDFB);

  /// Əsas mətn.
  static const Color onSurface = Color(0xFF2E2A55);

  /// İkinci dərəcəli mətn (6.5:1).
  static const Color onSurfaceVariant = Color(0xFF5E5888);

  /// Valideyn fonu, boş slot.
  static const Color surfaceContainerLow = Color(0xFFF8F5FF);
  static const Color surfaceContainer = Color(0xFFF1ECFF);

  /// Söndürülmüş fon.
  static const Color surfaceContainerHigh = Color(0xFFECE8F6);
  static const Color surfaceContainerHighest = Color(0xFFE4DEFF);

  /// Sərhəd və squishy kənar.
  static const Color outline = Color(0xFFD2C8F2);

  /// Ayırıcı, kartın halqası.
  static const Color outlineVariant = Color(0xFFE6E1F5);

  /// Snackbar, tooltip.
  static const Color inverseSurface = Color(0xFF2E2A55);
  static const Color onInverseSurface = Color(0xFFFFFDFB);

  /// DS-də yoxdur: snackbar düyməsinin rəngi.
  static const Color inversePrimary = Color(0xFFFFC547);

  /// Dialoq arxası (55 % ilə işlənir, bax [scrim55]).
  static const Color scrim = Color(0xFF2E2A55);

  // ----------------------------------------------- ElifbaColors rolları (DS)

  static const Color skyTop = Color(0xFFE4DEFF);
  static const Color skyMid = Color(0xFFF1ECFF);
  static const Color skyBottom = Color(0xFFFFF3EA);
  static const Color primaryEdge = Color(0xFFDE8D12);
  static const Color secondaryEdge = Color(0xFF5C45B5);
  static const Color surfaceEdge = Color(0xFFD2C8F2);
  static const Color star = Color(0xFFFFC547);
  static const Color starEdge = Color(0xFFE0A019);
  static const Color starOff = Color(0xFFE6E1F5);
  static const Color starOffEdge = Color(0xFFD0C8EA);
  static const Color correct = Color(0xFF2E9460);
  static const Color correctContainer = Color(0xFFDDF2E4);
  static const Color onCorrectContainer = Color(0xFF1A5A39);
  static const Color mutedContainer = Color(0xFFECE8F6);
  static const Color onMuted = Color(0xFFA9A2C6);
  static const Color complete = Color(0xFFFFF0C9);
  static const Color completeEdge = Color(0xFFF0C24E);
  static const Color burst = Color(0xFFFFD98A);
  static const Color sun = Color(0xFFFFA62B);
  static const Color quietIcon = Color(0xFF8A84AE);
  static const Color stageSky = Color(0xFFECE7FF);
  static const Color stageHill = Color(0xFFF3D9EC);

  // ------------------------------- Ekran maketlərindən gələn adsız rənglər

  /// Günəş şüalarının arası; azaldılmış hərəkətdə düz halqa.
  static const Color burstLight = Color(0xFFFFF1CC);

  /// Maskotun üzü ([star] ilə eyni hex).
  static const Color sunFace = Color(0xFFFFC547);

  /// Böyük təbrikdəki maskotun şüaları.
  static const Color sunRayCheer = Color(0xFFFF9A1F);

  /// Maskotun yanaqları, konfeti.
  static const Color cheek = Color(0xFFFF7FA8);

  /// Yanaqlar 70 % şəffaflıqla çəkilir.
  static const Color cheek70 = Color(0xB3FF7FA8);

  /// Basılmış əsas düymənin üzü.
  static const Color primaryPressed = Color(0xFFF5A938);

  /// Heyvan səsi düyməsinin kənarı (= Çəhrayı dəstin kənarı).
  static const Color tertiaryEdge = Color(0xFFF5B3CE);

  /// «İpucu» düyməsinin kənarı.
  static const Color hintEdge = Color(0xFFF0C987);

  /// Oxuyan səs düyməsinin halqası (= [secondaryContainer]).
  static const Color playingRing = Color(0xFFE4DEFF);

  /// Oxuyan səs düyməsinin kənarı; qırıq sərhədlər; sürüklənən kafelin kənarı.
  static const Color playingEdge = Color(0xFFC6B8F5);

  /// Yazı yolunun qırıq orta xətti.
  static const Color traceCentre = Color(0xFFA99FE0);

  /// Bitmiş ştrix.
  static const Color traceInkDone = Color(0xFF9C86E6);

  /// Yazı yolu (= Lavanda dəstinin üzü).
  static const Color traceRoad = Color(0xFFE9E2FF);

  /// Snackbar-dakı ✓ (= Nanə dəstinin kənarı).
  static const Color snackIcon = Color(0xFFA0D9C3);

  /// Açar: açıq + qeyri-aktiv.
  static const Color switchOnDisabledTrack = Color(0xFFCFC6EE);

  /// Açar: bağlı + qeyri-aktiv (kontur və düymə).
  static const Color switchOffDisabled = Color(0xFFD9D3EA);

  /// Qeyri-aktiv ayar sətrinin ikonu.
  static const Color parentDisabledIcon = Color(0xFFC6BFDD);

  /// Kitab hərf diskinin halqası (`rgba(255,253,251,.7)`).
  static const Color discRing = Color(0xB3FFFDFB);

  /// Hər scrim: `#2E2A55` 55 % ilə.
  static const Color scrim55 = Color(0x8C2E2A55);

  /// Səma səhifələrində nav bar-ın arxasındakı solğunlaşma.
  static const Color navFadeSky = Color(0xE6FFF3EA);

  /// Ayarlar səhifəsində nav bar-ın arxasındakı solğunlaşma.
  static const Color navFadeParent = Color(0xFFF8F5FF);

  /// Tooltip fonu (= [inverseSurface]).
  static const Color tooltipBg = Color(0xFF2E2A55);

  /// Tam şəffaf — "kölgə yoxdur" yerinə həmişə iki kölgə saxlamaq üçün.
  static const Color transparent = Color(0x00000000);

  // ------------------------------------------------------------- siyahılar

  /// Konfetinin rəngləri (DS `CC`).
  static const List<Color> confetti = [
    Color(0xFFFFC547),
    Color(0xFF7C63D9),
    Color(0xFFFF7FA8),
    Color(0xFFA0D9C3),
    Color(0xFFAED2F5),
  ];

  /// Qida çipindəki şəkil diskinin fonu, qidanın sırasına görə: `[i % 3]`
  /// (Limon, Səma, Çəhrayı dəstlərinin üzü).
  static const List<Color> foodDiscTints = [
    Color(0xFFFFF1C2),
    Color(0xFFDDEEFF),
    Color(0xFFFFE0EC),
  ];

  /// Qida çipinin şəkil fonu: [foodDiscTints]`[index % 3]`.
  static Color foodDiscTint(int index) =>
      foodDiscTints[(index < 0 ? 0 : index) % foodDiscTints.length];

  /// Altı hərf dəsti, bu sırada (DS `SETS`).
  static const List<LetterColorSet> letterSets = [
    LetterColorSet(
      name: 'Lavanda',
      tint: Color(0xFFE9E2FF),
      deep: Color(0xFF5F45C2),
      edge: Color(0xFFC6B8F5),
    ),
    LetterColorSet(
      name: 'Çəhrayı',
      tint: Color(0xFFFFE0EC),
      deep: Color(0xFFB03A6E),
      edge: Color(0xFFF5B3CE),
    ),
    LetterColorSet(
      name: 'Limon',
      tint: Color(0xFFFFF1C2),
      deep: Color(0xFF8A6400),
      edge: Color(0xFFF0D47E),
    ),
    LetterColorSet(
      name: 'Səma',
      tint: Color(0xFFDDEEFF),
      deep: Color(0xFF1F66A6),
      edge: Color(0xFFAED2F5),
    ),
    LetterColorSet(
      name: 'Nanə',
      tint: Color(0xFFD6F2E7),
      deep: Color(0xFF17765A),
      edge: Color(0xFFA0D9C3),
    ),
    LetterColorSet(
      name: 'Şaftalı',
      tint: Color(0xFFFFE4D2),
      deep: Color(0xFFAE4F1E),
      edge: Color(0xFFF5BE9E),
    ),
  ];

  /// DS qaydası: `letters[i % 6]`, `i` hərfin [AppConfig.alphabet]-dakı
  /// indeksidir. Mənfi indeks (əlifbada olmayan hərf) 0-cı dəstə düşür.
  static LetterColorSet letterSetAt(int alphabetIndex) =>
      letterSets[(alphabetIndex < 0 ? 0 : alphabetIndex) % letterSets.length];

  /// Hərfin dəsti; [complete] olanda qızılı üz və kənar.
  static LetterColorSet letterSetFor(String letter, {bool complete = false}) {
    final set = letterSetAt(AppConfig.alphabet.indexOf(letter));
    return complete ? set.asComplete() : set;
  }
}

/// Konfetinin rəngləri — [ElifbaPalette.confetti]-nin qısa adı.
const List<Color> kConfettiColors = ElifbaPalette.confetti;
