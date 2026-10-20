import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'squishy.dart';

/// Uşaq düyməsinin rəng variantı.
enum PillButtonVariant {
  /// Narıncı: «Yaşa!», «Yenidən» (yazı oyunu, təbrik).
  primary,

  /// Ağ, halqalı: «Yenidən başla».
  secondary,

  /// Açıq narıncı: «İpucu».
  tonal,

  /// Bənövşəyi: seçilmiş vəziyyət.
  selected,
}

/// Uşaq düyməsinin ölçüsü: L 64, M 56, S 52 dp.
enum PillButtonSize { large, medium, small }

/// Uşaq ekranlarının pill düyməsi (DS "Düymələr"). Həmişə pill-dir, həmişə
/// `Squishy` üzərindədir. Valideyn sahəsində işlənmir — orada
/// `ParentButtonStyles` var.
///
/// | variant   | üz      | basılı  | halqa     | kənar   | məzmun  |
/// |-----------|---------|---------|-----------|---------|---------|
/// | primary   | #FFB547 | #F5A938 | —         | #DE8D12 | #2E2A55 |
/// | secondary | #FFFDFB | #F8F5FF | 2 #D2C8F2 | #D2C8F2 | #2E2A55 |
/// | tonal     | #FFE7C2 | #FFE7C2 | —         | #F0C987 | #5A3A00 |
/// | selected  | #7C63D9 | #7C63D9 | —         | #5C45B5 | #FFFDFB |
/// | söndürülüb| #ECE8F6 | —       | —         | —       | #A9A2C6 |
///
/// Ekranlardakı məlum istisnalar [padding]/[labelStyle] ilə verilir:
/// * böyük təbrikin «Yaşa!»: L, `thumb_up_rounded`, padding 32/32;
/// * kiçik təbrikin «Yenidən»: M, `refresh_rounded`, padding 20/26,
///   `ElifbaTextStyles.buttonMCelebration`;
/// * pazlın «Yenidən başla»: S, secondary, `expand: true` (yazı sığmayanda
///   kiçilir — [scaleDown]).
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = PillButtonVariant.primary,
    this.size = PillButtonSize.medium,
    this.expand = false,
    this.scaleDown,
    this.padding,
    this.labelStyle,
    this.tooltip,
  });

  final String label;

  /// `null` → söndürülmüş (`Semantics(enabled: false)`).
  final VoidCallback? onPressed;
  final IconData? icon;
  final PillButtonVariant variant;
  final PillButtonSize size;

  /// Valideynin enini tutur (`Expanded` / tam en).
  final bool expand;

  /// `true` → ikon + yazı sığmayanda `FittedBox(scaleDown)` ilə kiçilir
  /// (üç nöqtə yox; animal.md §9.2). `false` → yazı `…` ilə kəsilir.
  /// Defolt: [expand].
  final bool? scaleDown;

  /// Üfüqi boşluğu əvəz edir.
  final EdgeInsetsGeometry? padding;

  /// Mətn üslubunu əvəz edir (rəng yenə variantdan gəlir).
  final TextStyle? labelStyle;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (face, pressed, ring, edge, content) = switch (variant) {
      PillButtonVariant.primary => (
        ElifbaPalette.primary,
        ElifbaPalette.primaryPressed,
        null,
        ElifbaPalette.primaryEdge,
        ElifbaPalette.onPrimary,
      ),
      PillButtonVariant.secondary => (
        ElifbaPalette.surface,
        ElifbaPalette.surfaceContainerLow,
        ElifbaPalette.outline,
        ElifbaPalette.outline,
        ElifbaPalette.onSurface,
      ),
      PillButtonVariant.tonal => (
        ElifbaPalette.primaryContainer,
        ElifbaPalette.primaryContainer,
        null,
        ElifbaPalette.hintEdge,
        ElifbaPalette.onPrimaryContainer,
      ),
      PillButtonVariant.selected => (
        ElifbaPalette.secondary,
        ElifbaPalette.secondary,
        null,
        ElifbaPalette.secondaryEdge,
        ElifbaPalette.onSecondary,
      ),
    };
    final (
      height,
      startIcon,
      end,
      textOnly,
      iconSize,
      gap,
      style,
      edgeH,
    ) = switch (size) {
      PillButtonSize.large => (
        ElifbaSize.buttonL,
        22.0,
        28.0,
        28.0,
        26.0,
        8.0,
        ElifbaTextStyles.buttonL,
        ElifbaEdge.e5,
      ),
      PillButtonSize.medium => (
        ElifbaSize.buttonM,
        16.0,
        22.0,
        22.0,
        24.0,
        8.0,
        ElifbaTextStyles.buttonM,
        ElifbaEdge.e5,
      ),
      PillButtonSize.small => (
        ElifbaSize.buttonS,
        10.0,
        14.0,
        14.0,
        22.0,
        6.0,
        ElifbaTextStyles.buttonS,
        ElifbaEdge.e4,
      ),
    };
    final fg = enabled ? content : ElifbaPalette.onMuted;
    final pad =
        padding ??
        (icon != null
            ? EdgeInsetsDirectional.only(start: startIcon, end: end)
            : EdgeInsets.symmetric(horizontal: textOnly));
    final textStyle = (labelStyle ?? style).copyWith(color: fg);
    final iconParts = [
      if (icon != null) ...[
        Icon(icon, size: iconSize, color: fg),
        SizedBox(width: gap),
      ],
    ];
    final Widget body =
        (scaleDown ?? expand)
            ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...iconParts,
                  Text(label, maxLines: 1, softWrap: false, style: textStyle),
                ],
              ),
            )
            : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...iconParts,
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
              ],
            );

    return Squishy(
      onTap: onPressed,
      color: face,
      pressedColor: pressed,
      shape: const StadiumBorder(),
      edge: edgeH,
      edgeColor: edge,
      ringColor: ring,
      ringWidth: ring != null ? ElifbaRing.normal : 0,
      height: height,
      width: expand ? double.infinity : null,
      padding: pad,
      alignment: expand ? Alignment.center : null,
      tooltip: tooltip,
      child: body,
    );
  }
}
