import 'package:flutter/material.dart';

import '../core/config.dart';
import 'elifba_palette.dart';

/// Uşaq ekranlarının `ColorScheme`-də olmayan rəng rolları (DS `EXT` cədvəli +
/// ekran maketlərindən gələn adsız rənglər).
///
/// Oxumaq üçün həmişə [ElifbaColors.of] işlədin: tema bu genişlənməni
/// daşımırsa (məs. testdə çılpaq `MaterialApp`), [light] qaytarılır, ona görə
/// widget heç vaxt `!` ilə sınmır. `CustomPainter`-lər isə temanı oxumur —
/// rəngi konstruktordan alır, defoltu `ElifbaPalette`-dəndir.
@immutable
class ElifbaColors extends ThemeExtension<ElifbaColors> {
  const ElifbaColors({
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.primaryEdge,
    required this.secondaryEdge,
    required this.surfaceEdge,
    required this.star,
    required this.starEdge,
    required this.starOff,
    required this.starOffEdge,
    required this.correct,
    required this.correctContainer,
    required this.onCorrectContainer,
    required this.mutedContainer,
    required this.onMuted,
    required this.complete,
    required this.completeEdge,
    required this.burst,
    required this.sun,
    required this.quietIcon,
    required this.stageSky,
    required this.stageHill,
    required this.burstLight,
    required this.sunFace,
    required this.sunRayCheer,
    required this.cheek,
    required this.primaryPressed,
    required this.tertiaryEdge,
    required this.hintEdge,
    required this.playingRing,
    required this.playingEdge,
    required this.traceCentre,
    required this.traceInkDone,
    required this.traceRoad,
    required this.snackIcon,
    required this.switchOnDisabledTrack,
    required this.switchOffDisabled,
    required this.parentDisabledIcon,
    required this.discRing,
    required this.scrim55,
    required this.navFadeSky,
    required this.navFadeParent,
    required this.confetti,
    required this.letterSets,
  });

  // ------------------------------------------------------------ DS rolları

  /// Ekran fonunun yuxarısı (0 %).
  final Color skyTop;

  /// Ekran fonunun ortası (46 %); həm də Scaffold-un ehtiyat fonu.
  final Color skyMid;

  /// Ekran fonunun aşağısı (100 %).
  final Color skyBottom;

  /// Əsas düymənin alt kənarı.
  final Color primaryEdge;

  /// Bənövşəyi düymənin / seçilmiş tabın alt kənarı; ayar başlıqları.
  final Color secondaryEdge;

  /// Kartın və çipin alt kənarı.
  final Color surfaceEdge;

  /// Dolu ulduz.
  final Color star;

  /// Dolu ulduzun konturu.
  final Color starEdge;

  /// Boş ulduz.
  final Color starOff;

  /// Boş ulduzun konturu; qeyri-aktiv chevron.
  final Color starOffEdge;

  /// Doğru — yalnız ✓ ilə birlikdə.
  final Color correct;

  /// Doğru kafelin fonu.
  final Color correctContainer;

  /// Doğru kafelin hərfi.
  final Color onCorrectContainer;

  /// Söndürülmüş səs düyməsinin fonu.
  final Color mutedContainer;

  /// Söndürülmüş/qeyri-aktiv məzmun.
  final Color onMuted;

  /// Tam bitmiş hərf / heyvan kartının üzü.
  final Color complete;

  /// Tam bitmiş kartın halqası və kənarı.
  final Color completeEdge;

  /// Günəş şüaları.
  final Color burst;

  /// Maskotun şüaları.
  final Color sun;

  /// Ayarlar dişlisi kimi sakit ikonlar.
  final Color quietIcon;

  /// Heyvan səhnəsinin səması.
  final Color stageSky;

  /// Heyvan səhnəsinin təpəsi.
  final Color stageHill;

  // ------------------------------------------ ekran maketlərindən rollar

  /// Şüaların arası; azaldılmış hərəkətdə düz halqa.
  final Color burstLight;

  /// Maskotun üzü.
  final Color sunFace;

  /// Böyük təbrikdə maskotun şüaları.
  final Color sunRayCheer;

  /// Maskotun yanağı (70 % ilə çəkilir).
  final Color cheek;

  /// Basılmış əsas düymənin üzü.
  final Color primaryPressed;

  /// Heyvan səsi düyməsinin kənarı.
  final Color tertiaryEdge;

  /// «İpucu» düyməsinin kənarı.
  final Color hintEdge;

  /// Oxuyan səs düyməsinin halqası.
  final Color playingRing;

  /// Oxuyan səs düyməsinin kənarı; qırıq sərhədlər.
  final Color playingEdge;

  /// Yazı yolunun orta xətti.
  final Color traceCentre;

  /// Bitmiş ştrix.
  final Color traceInkDone;

  /// Yazı yolu.
  final Color traceRoad;

  /// Snackbar-dakı ✓.
  final Color snackIcon;

  /// Açar: açıq + qeyri-aktiv.
  final Color switchOnDisabledTrack;

  /// Açar: bağlı + qeyri-aktiv.
  final Color switchOffDisabled;

  /// Qeyri-aktiv ayar sətrinin ikonu.
  final Color parentDisabledIcon;

  /// Kitab hərf diskinin halqası (70 %).
  final Color discRing;

  /// Hər scrim: #2E2A55 55 % ilə.
  final Color scrim55;

  /// Səma səhifəsində nav bar solğunlaşması.
  final Color navFadeSky;

  /// Ayarlarda nav bar solğunlaşması.
  final Color navFadeParent;

  /// Konfetinin beş rəngi.
  final List<Color> confetti;

  /// Altı hərf dəsti, DS sırası ilə (bax [letterSetAt]).
  final List<LetterColorSet> letterSets;

  /// Tətbiqin yeganə (açıq) nüsxəsi.
  static const ElifbaColors light = ElifbaColors(
    skyTop: ElifbaPalette.skyTop,
    skyMid: ElifbaPalette.skyMid,
    skyBottom: ElifbaPalette.skyBottom,
    primaryEdge: ElifbaPalette.primaryEdge,
    secondaryEdge: ElifbaPalette.secondaryEdge,
    surfaceEdge: ElifbaPalette.surfaceEdge,
    star: ElifbaPalette.star,
    starEdge: ElifbaPalette.starEdge,
    starOff: ElifbaPalette.starOff,
    starOffEdge: ElifbaPalette.starOffEdge,
    correct: ElifbaPalette.correct,
    correctContainer: ElifbaPalette.correctContainer,
    onCorrectContainer: ElifbaPalette.onCorrectContainer,
    mutedContainer: ElifbaPalette.mutedContainer,
    onMuted: ElifbaPalette.onMuted,
    complete: ElifbaPalette.complete,
    completeEdge: ElifbaPalette.completeEdge,
    burst: ElifbaPalette.burst,
    sun: ElifbaPalette.sun,
    quietIcon: ElifbaPalette.quietIcon,
    stageSky: ElifbaPalette.stageSky,
    stageHill: ElifbaPalette.stageHill,
    burstLight: ElifbaPalette.burstLight,
    sunFace: ElifbaPalette.sunFace,
    sunRayCheer: ElifbaPalette.sunRayCheer,
    cheek: ElifbaPalette.cheek,
    primaryPressed: ElifbaPalette.primaryPressed,
    tertiaryEdge: ElifbaPalette.tertiaryEdge,
    hintEdge: ElifbaPalette.hintEdge,
    playingRing: ElifbaPalette.playingRing,
    playingEdge: ElifbaPalette.playingEdge,
    traceCentre: ElifbaPalette.traceCentre,
    traceInkDone: ElifbaPalette.traceInkDone,
    traceRoad: ElifbaPalette.traceRoad,
    snackIcon: ElifbaPalette.snackIcon,
    switchOnDisabledTrack: ElifbaPalette.switchOnDisabledTrack,
    switchOffDisabled: ElifbaPalette.switchOffDisabled,
    parentDisabledIcon: ElifbaPalette.parentDisabledIcon,
    discRing: ElifbaPalette.discRing,
    scrim55: ElifbaPalette.scrim55,
    navFadeSky: ElifbaPalette.navFadeSky,
    navFadeParent: ElifbaPalette.navFadeParent,
    confetti: ElifbaPalette.confetti,
    letterSets: ElifbaPalette.letterSets,
  );

  /// Temadakı genişlənmə, yoxdursa [light].
  static ElifbaColors of(BuildContext context) =>
      Theme.of(context).extension<ElifbaColors>() ?? light;

  /// DS qaydası: `letters[i % 6]`.
  LetterColorSet letterSetAt(int alphabetIndex) =>
      letterSets[(alphabetIndex < 0 ? 0 : alphabetIndex) % letterSets.length];

  /// Hərfin dəsti (`AppConfig.alphabet`-dakı indeksə görə); [complete] olanda
  /// qızılı üz və kənar.
  LetterColorSet letterSetFor(String letter, {bool complete = false}) {
    final set = letterSetAt(AppConfig.alphabet.indexOf(letter));
    return complete ? set.asComplete() : set;
  }

  @override
  ElifbaColors copyWith({
    Color? skyTop,
    Color? skyMid,
    Color? skyBottom,
    Color? primaryEdge,
    Color? secondaryEdge,
    Color? surfaceEdge,
    Color? star,
    Color? starEdge,
    Color? starOff,
    Color? starOffEdge,
    Color? correct,
    Color? correctContainer,
    Color? onCorrectContainer,
    Color? mutedContainer,
    Color? onMuted,
    Color? complete,
    Color? completeEdge,
    Color? burst,
    Color? sun,
    Color? quietIcon,
    Color? stageSky,
    Color? stageHill,
    Color? burstLight,
    Color? sunFace,
    Color? sunRayCheer,
    Color? cheek,
    Color? primaryPressed,
    Color? tertiaryEdge,
    Color? hintEdge,
    Color? playingRing,
    Color? playingEdge,
    Color? traceCentre,
    Color? traceInkDone,
    Color? traceRoad,
    Color? snackIcon,
    Color? switchOnDisabledTrack,
    Color? switchOffDisabled,
    Color? parentDisabledIcon,
    Color? discRing,
    Color? scrim55,
    Color? navFadeSky,
    Color? navFadeParent,
    List<Color>? confetti,
    List<LetterColorSet>? letterSets,
  }) {
    return ElifbaColors(
      skyTop: skyTop ?? this.skyTop,
      skyMid: skyMid ?? this.skyMid,
      skyBottom: skyBottom ?? this.skyBottom,
      primaryEdge: primaryEdge ?? this.primaryEdge,
      secondaryEdge: secondaryEdge ?? this.secondaryEdge,
      surfaceEdge: surfaceEdge ?? this.surfaceEdge,
      star: star ?? this.star,
      starEdge: starEdge ?? this.starEdge,
      starOff: starOff ?? this.starOff,
      starOffEdge: starOffEdge ?? this.starOffEdge,
      correct: correct ?? this.correct,
      correctContainer: correctContainer ?? this.correctContainer,
      onCorrectContainer: onCorrectContainer ?? this.onCorrectContainer,
      mutedContainer: mutedContainer ?? this.mutedContainer,
      onMuted: onMuted ?? this.onMuted,
      complete: complete ?? this.complete,
      completeEdge: completeEdge ?? this.completeEdge,
      burst: burst ?? this.burst,
      sun: sun ?? this.sun,
      quietIcon: quietIcon ?? this.quietIcon,
      stageSky: stageSky ?? this.stageSky,
      stageHill: stageHill ?? this.stageHill,
      burstLight: burstLight ?? this.burstLight,
      sunFace: sunFace ?? this.sunFace,
      sunRayCheer: sunRayCheer ?? this.sunRayCheer,
      cheek: cheek ?? this.cheek,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      tertiaryEdge: tertiaryEdge ?? this.tertiaryEdge,
      hintEdge: hintEdge ?? this.hintEdge,
      playingRing: playingRing ?? this.playingRing,
      playingEdge: playingEdge ?? this.playingEdge,
      traceCentre: traceCentre ?? this.traceCentre,
      traceInkDone: traceInkDone ?? this.traceInkDone,
      traceRoad: traceRoad ?? this.traceRoad,
      snackIcon: snackIcon ?? this.snackIcon,
      switchOnDisabledTrack:
          switchOnDisabledTrack ?? this.switchOnDisabledTrack,
      switchOffDisabled: switchOffDisabled ?? this.switchOffDisabled,
      parentDisabledIcon: parentDisabledIcon ?? this.parentDisabledIcon,
      discRing: discRing ?? this.discRing,
      scrim55: scrim55 ?? this.scrim55,
      navFadeSky: navFadeSky ?? this.navFadeSky,
      navFadeParent: navFadeParent ?? this.navFadeParent,
      confetti: confetti ?? this.confetti,
      letterSets: letterSets ?? this.letterSets,
    );
  }

  /// Rənglər [Color.lerp] ilə keçir; siyahılar (konfeti, hərf dəstləri)
  /// yarıda birdən dəyişir. Tətbiqdə tək tema var, bu yalnız
  /// `ThemeExtension` müqaviləsi üçündür.
  @override
  ElifbaColors lerp(ElifbaColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return ElifbaColors(
      skyTop: c(skyTop, other.skyTop),
      skyMid: c(skyMid, other.skyMid),
      skyBottom: c(skyBottom, other.skyBottom),
      primaryEdge: c(primaryEdge, other.primaryEdge),
      secondaryEdge: c(secondaryEdge, other.secondaryEdge),
      surfaceEdge: c(surfaceEdge, other.surfaceEdge),
      star: c(star, other.star),
      starEdge: c(starEdge, other.starEdge),
      starOff: c(starOff, other.starOff),
      starOffEdge: c(starOffEdge, other.starOffEdge),
      correct: c(correct, other.correct),
      correctContainer: c(correctContainer, other.correctContainer),
      onCorrectContainer: c(onCorrectContainer, other.onCorrectContainer),
      mutedContainer: c(mutedContainer, other.mutedContainer),
      onMuted: c(onMuted, other.onMuted),
      complete: c(complete, other.complete),
      completeEdge: c(completeEdge, other.completeEdge),
      burst: c(burst, other.burst),
      sun: c(sun, other.sun),
      quietIcon: c(quietIcon, other.quietIcon),
      stageSky: c(stageSky, other.stageSky),
      stageHill: c(stageHill, other.stageHill),
      burstLight: c(burstLight, other.burstLight),
      sunFace: c(sunFace, other.sunFace),
      sunRayCheer: c(sunRayCheer, other.sunRayCheer),
      cheek: c(cheek, other.cheek),
      primaryPressed: c(primaryPressed, other.primaryPressed),
      tertiaryEdge: c(tertiaryEdge, other.tertiaryEdge),
      hintEdge: c(hintEdge, other.hintEdge),
      playingRing: c(playingRing, other.playingRing),
      playingEdge: c(playingEdge, other.playingEdge),
      traceCentre: c(traceCentre, other.traceCentre),
      traceInkDone: c(traceInkDone, other.traceInkDone),
      traceRoad: c(traceRoad, other.traceRoad),
      snackIcon: c(snackIcon, other.snackIcon),
      switchOnDisabledTrack: c(
        switchOnDisabledTrack,
        other.switchOnDisabledTrack,
      ),
      switchOffDisabled: c(switchOffDisabled, other.switchOffDisabled),
      parentDisabledIcon: c(parentDisabledIcon, other.parentDisabledIcon),
      discRing: c(discRing, other.discRing),
      scrim55: c(scrim55, other.scrim55),
      navFadeSky: c(navFadeSky, other.navFadeSky),
      navFadeParent: c(navFadeParent, other.navFadeParent),
      confetti: t < 0.5 ? confetti : other.confetti,
      letterSets: t < 0.5 ? letterSets : other.letterSets,
    );
  }
}
