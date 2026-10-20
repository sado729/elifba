import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'elifba_colors.dart';
import 'elifba_component_themes.dart';
import 'elifba_palette.dart';
import 'elifba_tokens.dart';
import 'elifba_typography.dart';

/// Material 3 `ColorScheme.light` — rollar AÇIQ verilir, `fromSeed` yoxdur.
///
/// `surfaceTint` şəffafdır və bu MƏCBURİDİR: defoltda o, `primary`-dir
/// (#FFB547), M3 isə hər dialoqu, kartı və AppBar-ı yüksəkliyə görə narıncı
/// çalara boyayardı.
const ColorScheme kElifbaColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: ElifbaPalette.primary,
  onPrimary: ElifbaPalette.onPrimary,
  primaryContainer: ElifbaPalette.primaryContainer,
  onPrimaryContainer: ElifbaPalette.onPrimaryContainer,
  secondary: ElifbaPalette.secondary,
  onSecondary: ElifbaPalette.onSecondary,
  secondaryContainer: ElifbaPalette.secondaryContainer,
  onSecondaryContainer: ElifbaPalette.onSecondaryContainer,
  tertiary: ElifbaPalette.tertiary,
  onTertiary: ElifbaPalette.onTertiary,
  tertiaryContainer: ElifbaPalette.tertiaryContainer,
  onTertiaryContainer: ElifbaPalette.onTertiaryContainer,
  error: ElifbaPalette.error,
  onError: ElifbaPalette.onError,
  errorContainer: ElifbaPalette.errorContainer,
  onErrorContainer: ElifbaPalette.onErrorContainer,
  surface: ElifbaPalette.surface,
  onSurface: ElifbaPalette.onSurface,
  onSurfaceVariant: ElifbaPalette.onSurfaceVariant,
  // DS-də yoxdur: ən yaxın rollarla doldurulub.
  surfaceDim: ElifbaPalette.surfaceContainerHigh,
  surfaceBright: ElifbaPalette.surface,
  surfaceContainerLowest: ElifbaPalette.surface,
  surfaceContainerLow: ElifbaPalette.surfaceContainerLow,
  surfaceContainer: ElifbaPalette.surfaceContainer,
  surfaceContainerHigh: ElifbaPalette.surfaceContainerHigh,
  surfaceContainerHighest: ElifbaPalette.surfaceContainerHighest,
  outline: ElifbaPalette.outline,
  outlineVariant: ElifbaPalette.outlineVariant,
  shadow: ElifbaPalette.onSurface,
  scrim: ElifbaPalette.scrim,
  inverseSurface: ElifbaPalette.inverseSurface,
  onInverseSurface: ElifbaPalette.onInverseSurface,
  inversePrimary: ElifbaPalette.inversePrimary,
  surfaceTint: ElifbaPalette.transparent,
);

/// Sistem panelləri: hər ekran açıq fondadır, ona görə status və nav bar
/// ikonları TÜND-dür, panellər şəffafdır.
///
/// Üç yerdə tətbiq olunur (hamısı lazımdır):
/// 1. `main.dart` — `SystemChrome.setSystemUIOverlayStyle`;
/// 2. `AppBarTheme.systemOverlayStyle` — şəffaf fonlu `AppBar` əks halda öz
///    üslubunu hesablayır və AÇIQ ikon seçir;
/// 3. AppBar-sız səhifələr — `AnnotatedRegion<SystemUiOverlayStyle>`.
const SystemUiOverlayStyle kElifbaSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: ElifbaPalette.transparent,
  // Android: tünd ikonlar.
  statusBarIconBrightness: Brightness.dark,
  // iOS: tünd məzmun.
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: ElifbaPalette.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarDividerColor: ElifbaPalette.transparent,
  // 3 düyməli nav bar-ın arxasında boz örtük olmasın — fon onsuz da açıqdır.
  systemNavigationBarContrastEnforced: false,
  systemStatusBarContrastEnforced: false,
);

/// Ekran spesifikasiyalarının işlətdiyi ad — [kElifbaSystemUiStyle] ilə eynidir.
const SystemUiOverlayStyle kElifbaLightBarsStyle = kElifbaSystemUiStyle;

/// Tətbiqin yeganə teması. Tünd tema yoxdur.
abstract final class ElifbaTheme {
  static ThemeData light() {
    const s = kElifbaColorScheme;
    const t = ElifbaTypography.textTheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: s,
      // Üslubsuz hər mətn Andika olsun — heç vaxt Roboto/NotoSans.
      fontFamily: ElifbaTypography.body,
      textTheme: t,
      // Yalnız ehtiyat: səhifələr öz `SkyBackground`-unu çəkir.
      scaffoldBackgroundColor: ElifbaPalette.skyMid,
      canvasColor: s.surface,
      // InkSparkle ilk toxunuşda shader kompilyasiya edir (zəif cihazda ləngimə).
      splashFactory: InkRipple.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: const [ElifbaColors.light],
      iconTheme: const IconThemeData(color: ElifbaPalette.onSurface, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: ElifbaPalette.transparent,
        surfaceTintColor: ElifbaPalette.transparent,
        foregroundColor: s.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: ElifbaSize.toolbar,
        centerTitle: false,
        titleSpacing: 12,
        // 10 + 48: `Padding(left: 10, child: ToolbarBackButton())`.
        leadingWidth: 58,
        titleTextStyle: t.titleLarge!.copyWith(color: s.onSurface),
        iconTheme: const IconThemeData(
          color: ElifbaPalette.onSurface,
          size: 26,
        ),
        actionsIconTheme: const IconThemeData(
          color: ElifbaPalette.onSurface,
          size: 30,
        ),
        actionsPadding: const EdgeInsets.only(right: 10),
        systemOverlayStyle: kElifbaSystemUiStyle,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: s.onSurface,
          disabledForegroundColor: ElifbaPalette.starOffEdge,
          minimumSize: const Size(48, 48),
          highlightColor: s.surfaceContainerHigh,
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: ParentButtonStyles.text),
      filledButtonTheme: FilledButtonThemeData(
        style: ParentButtonStyles.filled,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: ElifbaPalette.transparent,
        shadowColor: ElifbaPalette.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r28)),
        ),
        barrierColor: ElifbaPalette.scrim55,
        insetPadding: const EdgeInsets.all(24),
        titleTextStyle: ElifbaTextStyles.dialogTitle.copyWith(
          color: s.onSurface,
        ),
        contentTextStyle: ElifbaTextStyles.dialogBody.copyWith(
          color: s.onSurfaceVariant,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: s.inverseSurface,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        contentTextStyle: ElifbaTextStyles.snackbar.copyWith(
          color: s.onInverseSurface,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r16)),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionTextColor: s.inversePrimary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: ElifbaPalette.tooltipBg,
          borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        // 6 + 16 + 6 = 28 (DS). Flutter mobil defoltu `minHeight: 32`-dir.
        constraints: const BoxConstraints(minHeight: 28),
        textStyle: t.labelSmall!.copyWith(color: ElifbaPalette.surface),
      ),
      switchTheme: ElifbaSwitchTheme.data,
      segmentedButtonTheme: ElifbaSegmentedTheme.data,
      listTileTheme: ListTileThemeData(
        iconColor: s.onSurfaceVariant,
        textColor: s.onSurface,
        titleTextStyle: ElifbaTextStyles.listTitle.copyWith(color: s.onSurface),
        subtitleTextStyle: ElifbaTextStyles.listSubtitle.copyWith(
          color: s.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        // İki sətirli sətir: 2 × 11 + 22 + 20 = 64 (settings.md §5.3).
        minVerticalPadding: 11,
        minTileHeight: 64,
        horizontalTitleGap: 14,
        minLeadingWidth: 22,
      ),
      dividerTheme: const DividerThemeData(
        color: ElifbaPalette.surfaceContainerHigh,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: ElifbaPalette.surface,
        surfaceTintColor: ElifbaPalette.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r28)),
        ),
      ),
      // pageTransitionsTheme: defolt (Android = Zoom) — dəyişmir.
    );
  }
}
