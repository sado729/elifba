import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'squishy.dart';

/// Kitabın 64 dp dairəvi oxu (DS "nav 64"): narıncı üz, 5 dp kənar.
///
/// Kitabın sonunda/əvvəlində `onPressed: null` verilir — boz üz, kənar yox,
/// `Semantics(enabled: false)`. Tooltip: «Əvvəlki səhifə» / «Növbəti səhifə».
class NavRoundButton extends StatelessWidget {
  const NavRoundButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  /// `Icons.arrow_back_rounded` / `Icons.arrow_forward_rounded`.
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Squishy(
      onTap: onPressed,
      tooltip: tooltip,
      shape: const CircleBorder(),
      color: ElifbaPalette.primary,
      pressedColor: ElifbaPalette.primaryPressed,
      edge: ElifbaEdge.e5,
      edgeColor: ElifbaPalette.primaryEdge,
      width: ElifbaSize.navRound,
      height: ElifbaSize.navRound,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 34,
        color: enabled ? ElifbaPalette.onPrimary : ElifbaPalette.onMuted,
      ),
    );
  }
}

/// Uşaq ekranlarının üst panelindəki 48 dp geri düyməsi (DS "toolbar 48 ·
/// Geri"): ağ dairə, 2 dp halqa + 3 dp kənar #D2C8F2.
///
/// [onPressed] verilməyəndə `Navigator.maybePop(context)` çağırılır.
/// Tooltip HƏMİŞƏ «Geri»-dir (testlər `find.byTooltip('Geri')` axtarır).
class ToolbarBackButton extends StatelessWidget {
  const ToolbarBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Squishy(
      onTap: onPressed ?? () => Navigator.maybePop(context),
      tooltip: 'Geri',
      shape: const CircleBorder(),
      color: ElifbaPalette.surface,
      pressedColor: ElifbaPalette.surfaceContainerLow,
      edge: ElifbaEdge.e3,
      edgeColor: ElifbaPalette.outline,
      ringColor: ElifbaPalette.outline,
      ringWidth: ElifbaRing.normal,
      width: ElifbaSize.toolbarButton,
      height: ElifbaSize.toolbarButton,
      alignment: Alignment.center,
      child: const Icon(
        Icons.arrow_back_rounded,
        size: 26,
        color: ElifbaPalette.onSurface,
      ),
    );
  }
}

/// Üst paneldə əvvəlki/növbəti hərf (və ya heyvan) oxu. Squishy DEYİL: fonsuz
/// `IconButton`, basanda M3 vurğusu #ECE8F6. Söndürüləndə ikon #D0C8EA.
///
/// Tooltip: «Əvvəlki hərf» / «Növbəti hərf» (və ya «… heyvan»). Heyvan
/// səhifəsində görünən en 44 ola bilər, hündürlük həmişə 48. En 48-dən
/// kiçik olanda toxunma sahəsi `padded`-dir: layout qutusu yenə 48 × 48
/// olur (vurğu 44 enində, mərkəzdə) — toxunma hədəfi heç vaxt 48-dən kiçik
/// deyil.
class ToolbarChevron extends StatelessWidget {
  const ToolbarChevron({
    super.key,
    required this.forward,
    required this.onPressed,
    required this.tooltip,
    this.width = 48,
  });

  /// `true` → `chevron_right_rounded`, `false` → `chevron_left_rounded`.
  final bool forward;
  final VoidCallback? onPressed;
  final String tooltip;
  final double width;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: ElifbaPalette.onSurface,
        disabledForegroundColor: ElifbaPalette.starOffEdge,
        highlightColor: ElifbaPalette.surfaceContainerHigh,
        fixedSize: Size(width, ElifbaSize.toolbarButton),
        minimumSize: Size(width, ElifbaSize.toolbarButton),
        tapTargetSize:
            width < ElifbaSize.touchMin
                ? MaterialTapTargetSize.padded
                : MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(
        forward ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
        size: 30,
      ),
    );
  }
}

/// Sakit ikon düyməsi (DS "Ayarlar (sakit)"): 48 × 48, fonsuz, kənarsız,
/// squish yoxdur. Basanda M3-ün defolt vurğusu (ikon rəngində state layer +
/// ripple) qalır — bu valideyn idarəsidir (home.md §5.4). Ana səhifədə
/// ayarlar dişlisi üçündür — ikon `Icons.settings_outlined` QALIR (testlər
/// ona toxunur).
class QuietIconButton extends StatelessWidget {
  const QuietIconButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.settings_outlined,
    this.tooltip = 'Ayarlar',
    this.size = 22,
    this.color = ElifbaPalette.quietIcon,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: color,
        fixedSize: const Size.square(ElifbaSize.touchMin),
        minimumSize: const Size.square(ElifbaSize.touchMin),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: size),
    );
  }
}

/// Ayarlar səhifəsinin geri düyməsi: 48 dp dairə, fonsuz, basanda/hover
/// zamanı düz #ECE8F6, dalğa yoxdur. Valideyn sahəsi düzdür — squish yoxdur.
///
/// [onPressed] verilməyəndə `Navigator.maybePop(context)`. Tooltip «Geri».
class ParentBackButton extends StatelessWidget {
  const ParentBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      tooltip: 'Geri',
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(Size.square(48)),
        minimumSize: const WidgetStatePropertyAll(Size.square(48)),
        shape: const WidgetStatePropertyAll(CircleBorder()),
        foregroundColor: const WidgetStatePropertyAll(ElifbaPalette.onSurface),
        overlayColor: const WidgetStatePropertyAll(
          ElifbaPalette.surfaceContainerHigh,
        ),
        splashFactory: NoSplash.splashFactory,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.arrow_back_rounded, size: 24),
    );
  }
}
