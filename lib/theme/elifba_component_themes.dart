import 'package:flutter/material.dart';

import 'elifba_palette.dart';
import 'elifba_typography.dart';

// Komponent temaları ayrıca saxlanılır ki, tema daşımayan yerdə də (ayarlar
// testləri çılpaq `MaterialApp` ilə qurulur) eyni dəyərlər əllə verilə bilsin:
// `SwitchTheme(data: ElifbaSwitchTheme.data, …)`, `style: ParentButtonStyles.text`.

/// Valideyn sahəsinin açarı (DS "Açar (valideyn)", `sw()` cədvəli).
///
/// M3 `Switch`-in həndəsəsi maketlə eynidir (52 × 32 yol, 2 dp kontur, açıqda
/// 24, bağlıda 16 dp düymə), ona görə yalnız rənglər və ✓ ikonu verilir.
/// Yalnız `selected` / `disabled` vəziyyətləri oxunur: M3-ün basılı/hover
/// rəngləri `colorScheme.primary`-ni (indi narıncı) gətirərdi.
abstract final class ElifbaSwitchTheme {
  static final SwitchThemeData data = SwitchThemeData(
    // 52 dp en, yan boşluq yoxdur — sətrin sonu maketdəki kimi 16 dp qalır.
    padding: EdgeInsets.zero,
    trackOutlineWidth: const WidgetStatePropertyAll(2),
    trackColor: WidgetStateProperty.resolveWith((s) {
      final on = s.contains(WidgetState.selected);
      final off = s.contains(WidgetState.disabled);
      return on
          ? (off
              ? ElifbaPalette.switchOnDisabledTrack
              : ElifbaPalette.secondary)
          : (off
              ? ElifbaPalette.surfaceContainer
              : ElifbaPalette.surfaceContainerHigh);
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((s) {
      final on = s.contains(WidgetState.selected);
      final off = s.contains(WidgetState.disabled);
      return on
          ? (off
              ? ElifbaPalette.switchOnDisabledTrack
              : ElifbaPalette.secondary)
          : (off ? ElifbaPalette.switchOffDisabled : ElifbaPalette.onMuted);
    }),
    thumbColor: WidgetStateProperty.resolveWith((s) {
      final on = s.contains(WidgetState.selected);
      final off = s.contains(WidgetState.disabled);
      return on
          ? ElifbaPalette.surface
          : (off ? ElifbaPalette.switchOffDisabled : ElifbaPalette.onMuted);
    }),
    // Bağlıda MÜTLƏQ null: ikon verilsə M3 bağlı düyməni 16-dan 24 dp-yə
    // böyüdür.
    thumbIcon: WidgetStateProperty.resolveWith(
      (s) =>
          s.contains(WidgetState.selected)
              ? Icon(
                Icons.check_rounded,
                size: 16,
                color:
                    s.contains(WidgetState.disabled)
                        ? ElifbaPalette.onMuted
                        : ElifbaPalette.secondaryEdge,
              )
              : null,
    ),
    overlayColor: WidgetStateProperty.resolveWith(
      (s) =>
          s.contains(WidgetState.selected)
              ? const Color(0x1F7C63D9) // secondary 12 %
              : const Color(0x1A2E2A55), // onSurface 10 %
    ),
  );
}

/// Valideyn sahəsinin seqment idarəsi (pazl ölçüsü 3 × 3 / 4 × 4 / 5 × 5).
/// Uşaq ekranında eyni seçim `PillTab` + `GridGlyph` ilə qurulur.
abstract final class ElifbaSegmentedTheme {
  static final SegmentedButtonThemeData data = SegmentedButtonThemeData(
    selectedIcon: const Icon(Icons.check_rounded, size: 18),
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      // settings.md §6.5: 360 dp-də seqment ≈ 86.7 dp; 8 dp yan boşluq
      // «✓ 5 × 5»-i bir sətirdə saxlayır (M3-ün 12-si ~1 dp ehtiyat qoyur).
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8),
      ),
      iconSize: const WidgetStatePropertyAll(18),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.padded,
      elevation: const WidgetStatePropertyAll(0),
      side: const WidgetStatePropertyAll(
        BorderSide(color: ElifbaPalette.onMuted, width: 1.5),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected)
                ? ElifbaPalette.secondaryContainer
                : ElifbaPalette.transparent,
      ),
      foregroundColor: const WidgetStatePropertyAll(ElifbaPalette.onSurface),
      iconColor: const WidgetStatePropertyAll(ElifbaPalette.onSurface),
      overlayColor: const WidgetStatePropertyAll(Color(0x1F7C63D9)),
      textStyle: const WidgetStatePropertyAll(ElifbaTextStyles.tabLabel),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
    ),
  );
}

/// Valideyn düymələri: 48 dp, pill, düz (squish yoxdur), Andika 700 15.
/// Uşaq ekranında bunlar YOX, `PillButton` işlənir.
abstract final class ParentButtonStyles {
  /// «Ləğv et»: rəngsiz, mətn #5C45B5, basanda #F1ECFF fon, dalğa yoxdur.
  static final ButtonStyle text = TextButton.styleFrom(
    foregroundColor: ElifbaPalette.secondaryEdge,
    overlayColor: ElifbaPalette.surfaceContainer,
    splashFactory: NoSplash.splashFactory,
    textStyle: ElifbaTextStyles.parentButton,
    minimumSize: const Size(64, 48),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    shape: const StadiumBorder(),
  ).copyWith(
    // `styleFrom(overlayColor:)` rəngi şəffaflaşdırır; dizayn düz #F1ECFF
    // istəyir (basılı, hover və fokus).
    overlayColor: const WidgetStatePropertyAll(ElifbaPalette.surfaceContainer),
  );

  /// [text]-in 16 dp yan boşluqlu variantı: ayarların sıfırlama dialoqundakı
  /// «Ləğv et» (ScreenSettings, DS "Dialoq (valideyn)"). Qapıda 18 qalır.
  static final ButtonStyle textCompact = text.copyWith(
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
  );

  /// «Bağla»: #7C63D9 fon, #FFFDFB mətn.
  static final ButtonStyle filled = FilledButton.styleFrom(
    backgroundColor: ElifbaPalette.secondary,
    foregroundColor: ElifbaPalette.onSecondary,
    textStyle: ElifbaTextStyles.parentButton,
    minimumSize: const Size(64, 48),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    shape: const StadiumBorder(),
    elevation: 0,
  );

  /// «Bəli, sil»: #DD4A5A fon (kontrast ~4:1 — istifadəçiyə bildirilib).
  static final ButtonStyle destructive = FilledButton.styleFrom(
    backgroundColor: ElifbaPalette.error,
    foregroundColor: ElifbaPalette.onError,
    textStyle: ElifbaTextStyles.parentButton,
    minimumSize: const Size(64, 48),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    shape: const StadiumBorder(),
    elevation: 0,
  );
}
